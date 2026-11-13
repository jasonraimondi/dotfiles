# Endpoints, Discovery, Scopes & Claims

## Discovery & metadata

Fetch `<issuer>/.well-known/openid-configuration` (OIDC Discovery 1.0 / RFC 8414). **Never hardcode endpoints.**

**REQUIRED OP metadata**: `issuer` (HTTPS, no query/fragment), `authorization_endpoint`, `jwks_uri` (public keys only — no private/symmetric), `response_types_supported`, `subject_types_supported`, `id_token_signing_alg_values_supported` (MUST include `RS256`), `token_endpoint`.

**RECOMMENDED**: `userinfo_endpoint`, `registration_endpoint`, `scopes_supported` (MUST include `openid`), `claims_supported`.

**Notable OPTIONAL**: `response_modes_supported`, `grant_types_supported`, `token_endpoint_auth_methods_supported` (default `client_secret_basic`), `code_challenge_methods_supported`, `pushed_authorization_request_endpoint`, `require_pushed_authorization_requests`, `dpop_signing_alg_values_supported`, `authorization_response_iss_parameter_supported`, `revocation_endpoint`, `introspection_endpoint`, `end_session_endpoint`, `backchannel_logout_supported`, `mtls_endpoint_aliases`.

**Issuer validation**: the string used to build the well-known URL MUST equal the returned `issuer` exactly (including trailing slash or its absence), and MUST equal the `iss` claim of issued ID Tokens. `https` only.

**Caching**: TTL 24h or honor `Cache-Control`. Re-fetch on a JWKS `kid` miss. Feature-detect via metadata — many OPs pre-date RFC 9700; do not assume `iss`-parameter or DPoP support.

## Authorization Endpoint

Renders login/consent. GET (typically) or POST. Returns a 302 with the response in `query`, `fragment`, or `form_post`.

## Token Endpoint & client authentication (OIDC Core §9)

`token_endpoint_auth_methods_supported` lists accepted methods:
- `client_secret_basic` — HTTP Basic with URL-encoded `client_id:client_secret`. Discovery default.
- `client_secret_post` — credentials in the form body.
- `client_secret_jwt` — client signs a JWT with HMAC keyed by `client_secret`.
- `private_key_jwt` — client signs a JWT with its private key; AS verifies against the client's JWKS. **Recommended for confidential clients.**
- `tls_client_auth` / `self_signed_tls_client_auth` (RFC 8705) — mTLS.
- `none` — public clients; PKCE required.

Client-assertion JWT (`client_secret_jwt` / `private_key_jwt`) claims: `iss=sub=client_id`, `aud`, `jti`, `exp`, optional `iat`; `client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer`. For `aud`, FAPI 2.0 and RFC 9700 prefer the AS **issuer identifier** (not the token-endpoint URL); many ASes accept both.

**Recommendation**: confidential clients default to `private_key_jwt` or mTLS — no long-lived shared secret crosses the wire. FAPI 2.0 mandates one of the two.

## UserInfo Endpoint (Core §5.3)

A protected resource. The client presents the **access token** (`Authorization: Bearer <token>` or DPoP-bound). GET or POST; response is a JSON object that MUST include `sub`. **The `sub` MUST equal the ID Token's `sub`** (cross-account confusion guard). May be a signed/encrypted JWT if the client registered `userinfo_signed_response_alg`. **Common bug**: calling UserInfo with the *ID Token* — the ID Token is not an OAuth bearer token.

## JWKS URI

HTTPS only. Each JWK: `kty`, `use` (`sig`/`enc`), `alg`, `kid`, key params. Rotate by adding a new key, signing with it, then removing the old key after consumers refresh.

## Other endpoints

- **Dynamic Client Registration** (RFC 7591 + OIDC Registration 1.0): POST client metadata to `registration_endpoint`. The AS MUST validate registered URIs for SSRF.
- **Introspection** (RFC 7662): POST `token` with caller auth → `{ active, scope, client_id, sub, exp, ... }`. Prefer offline verification for JWT access tokens.
- **Revocation** (RFC 7009): POST `token` + `token_type_hint`. Always returns HTTP 200 (no oracle).
- **PAR — Pushed Authorization Requests** (RFC 9126): POST the full auth request to `pushed_authorization_request_endpoint`, get back `request_uri`, then redirect with `client_id` + `request_uri`. Integrity-protected, no Referer/log leakage, no URL-length limits. FAPI 2.0 mandates PAR.
- **JAR — JWT-Secured Authorization Request** (RFC 9101): replace front-channel params with a signed `request=<JWS>` or `request_uri=<URL>` Request Object. PAR covers the same confidentiality.

## Logout

- **RP-Initiated Logout 1.0**: `end_session_endpoint` (REQUIRED OP metadata, `https`). Front-channel GET params: `id_token_hint` (RECOMMENDED), `logout_hint`, `client_id` (if both `client_id` and `id_token_hint` are present the OP MUST verify they match), `post_logout_redirect_uri` (MUST be pre-registered), `state`, `ui_locales`.
- **Back-Channel Logout**: the OP POSTs a Logout Token (signed JWT) to each RP's `backchannel_logout_uri`. The token MUST contain `iss`, `aud`, `iat`, `jti`, `exp`, an `events` claim with `"http://schemas.openid.net/event/backchannel-logout"` → `{}`, and `sub` and/or `sid`. It MUST NOT contain `nonce`. The RP MUST validate signature, `iss`, `aud`, `iat`, the events claim, and the presence of `sub`/`sid`. **Prefer back-channel logout.**
- **Front-Channel Logout / Session Management 1.0** depend on third-party cookies, which Safari and Firefox block by default. Plan for CHIPS/`Partitioned` cookies or migrate to back-channel logout.

## Scopes & claims

**Scopes** (Core §5.4): `openid` (MANDATORY — triggers OIDC) · `profile` (→ `name`, `family_name`, `given_name`, `picture`, `locale`, `updated_at`, …) · `email` (→ `email`, `email_verified`) · `address` · `phone` · `offline_access` (→ refresh token; explicit consent required).

**Standard claims** (Core §5.1): `sub`, `name`/`given_name`/`family_name`/`nickname`, `preferred_username` (not unique), `profile`/`picture`/`website` (URLs), `email` + `email_verified` (bool), `gender`, `birthdate` (`YYYY-MM-DD`), `zoneinfo` (IANA tz), `locale` (BCP47), `phone_number` (E.164) + `phone_number_verified`, `address` (object: `formatted`, `street_address`, `locality`, `region`, `postal_code`, `country`), `updated_at` (NumericDate).

**Claim stability** (§5.7): only `(iss, sub)` is guaranteed stable and unique. **Never key user accounts on `email` alone** — `email_verified` only attests past control; addresses get reassigned. Many enterprise OPs return only `sub` plus a few custom claims; code defensively.

The **`claims` request parameter** (§5.5) requests specific claims into `id_token`/`userinfo`, each `null` (voluntary) or `{"essential":true,...}`. **`acr`/`amr`**: assurance level / methods. RFC 9470 step-up: the RS replies `401 WWW-Authenticate: Bearer error="insufficient_user_authentication"` with `acr_values`/`max_age`; the client repeats the request.

---

## Checklist — what an OP MUST do per endpoint

- **Authorization endpoint**: validate `client_id`, `redirect_uri` (exact match), `scope` (contains `openid`), `response_type` (registered for this client), `code_challenge` (required), `nonce` if the flow requires it. Authenticate the user, obtain consent, issue an authorization code bound to `(client_id, redirect_uri, code_challenge, nonce, scope, auth_time)`.
- **Token endpoint**: authenticate the client; validate `code` (one-time, unexpired, bound to client + redirect_uri); validate `code_verifier` against the stored `code_challenge`; issue access/refresh/ID tokens with correct claims and signing.
- **UserInfo**: require an access token with the `openid` scope; return `sub` matching the ID Token; never return unconsented claims.
- **JWKS**: serve only public keys; rotate with overlapping validity.
- **Discovery**: return `issuer` byte-identical to the URL prefix; never include private keys.
- **Revocation**: always return 200. **Introspection**: authenticate the caller.
- **End session**: validate `id_token_hint` and `post_logout_redirect_uri` (exact match), revoke the local session, send back-channel logout to each registered RP, then redirect.
