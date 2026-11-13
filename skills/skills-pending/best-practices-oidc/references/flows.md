# Flows

A request is OIDC **iff `scope` contains `openid`** (Core §3.1.2.1). Without it, the server behaves as plain OAuth and MUST NOT return an ID Token.

`response_type` → flow: `code` → Authorization Code (use this) · `id_token` / `id_token token` → Implicit (deprecated) · `code id_token` etc. → Hybrid (avoid) · `none` → no tokens.

## Authorization Code with PKCE — the only recommended interactive flow

Use for **every** interactive client (web, SPA-via-BFF, mobile, desktop, TV-via-device), public or confidential.

**Authorization request** (front-channel `GET` to `authorization_endpoint`):
- `response_type=code` (REQUIRED)
- `client_id` (REQUIRED)
- `redirect_uri` (REQUIRED in OIDC; exact match against a pre-registered URI)
- `scope=openid ...` (REQUIRED; must include `openid`)
- `state` (RECOMMENDED — CSRF + app-state binding)
- `nonce` (RECOMMENDED for Code flow; REQUIRED for any flow returning an ID Token from the authorization endpoint)
- `code_challenge` (REQUIRED per RFC 9700 / OAuth 2.1)
- `code_challenge_method=S256` (REQUIRED — **never `plain`**)
- Optional: `response_mode` (`query`/`fragment`/`form_post`), `prompt` (`none`/`login`/`consent`/`select_account`), `max_age`, `display`, `ui_locales`, `id_token_hint`, `login_hint`, `acr_values`, `claims`, `request`, `request_uri`.

**Authorization response** (redirect to `redirect_uri`): `code`, `state`, and per RFC 9207 `iss` when the AS advertises `authorization_response_iss_parameter_supported=true`.

**Token request** (back-channel `POST` to `token_endpoint`, `application/x-www-form-urlencoded`):
- `grant_type=authorization_code`, `code`, `redirect_uri` (must match the auth request), `client_id`
- `code_verifier` (REQUIRED — the original verifier whose S256 hash was `code_challenge`)
- Client authentication per the configured method.

**Token response**: JSON with `access_token`, `token_type` (`Bearer`/`DPoP`), `expires_in`, optional `refresh_token`, `id_token` (OIDC), `scope` (if narrowed).

## Implicit flow — DEPRECATED, do not implement

`response_type=token` / `token id_token`. Tokens land in the URL fragment — exposed via history/Referer, no sender-constraining, no client auth on issuance, no PKCE coverage, token-injection prone. Removed from OAuth 2.1.

## Hybrid flow — avoid

`response_type=code id_token` etc. An ID Token returned from the authorization endpoint MUST carry `c_hash` (over `code`), `at_hash` (over `access_token` when present), and `nonce`. FAPI 2.0 removes Hybrid: only `response_type=code`.

## Client Credentials (RFC 6749 §4.4) — not OIDC

`grant_type=client_credentials`. No user, no ID Token. Confidential clients only. RFC 9068 §5: `sub` SHOULD be a client identifier.

## Resource Owner Password Credentials — DEPRECATED

`grant_type=password`. Removed in OAuth 2.1. Do not implement.

## Device Authorization Grant (RFC 8628)

For TVs, CLIs, IoT:
- `POST` to `device_authorization_endpoint` with `client_id` + `scope` → `device_code`, `user_code`, `verification_uri`, `verification_uri_complete`, `expires_in`, `interval`.
- Device polls the token endpoint with `grant_type=urn:ietf:params:oauth:grant-type:device_code` + `device_code`. Errors: `authorization_pending`, `slow_down`, `access_denied`, `expired_token`.
- Add PKCE if the client can.

## Refresh tokens

- Issued with the `offline_access` scope (Core §11) or per AS policy.
- **MUST rotate for public clients** (RFC 9700 §4.14): each use returns a new refresh token; the old one is invalidated.
- **Reuse detection**: a second presentation of a rotated token signals compromise — invalidate the entire token family immediately.
- **Sender-constrain** with DPoP (RFC 9449) or mTLS (RFC 8705).
- Enforce an absolute lifetime + an inactivity timeout. Never log.
- **Serialize refresh requests per session** — concurrent refresh under rotation races into reuse detection and kills a branch. A short reuse-grace window (≤30s) is a pragmatic mitigation; production systems serialize instead.
- Duende IdentityServer defaults confidential clients to *reusable* (non-rotating) refresh tokens — a defensible reading of RFC 9700, which mandates rotation specifically for *public* clients. Make it configurable.

## CIBA (Client-Initiated Backchannel Authentication)

Decoupled flow: the client asks the OP to authenticate a user identified out-of-band (push, second device). Delivery modes: poll, ping, push. Entry point `backchannel_authentication_endpoint`. Used in call centers, point-of-sale, banking.

## Token Exchange (RFC 8693)

`grant_type=urn:ietf:params:oauth:grant-type:token-exchange`. Present a `subject_token` (and optional `actor_token`), receive a new token. For delegation/impersonation and downstream service calls.

---

## Checklist — authorization response handler (RP)

1. Parse `state`, `code`, `iss`, `error`.
2. **State**: look up the stored state record; abort if missing; match `state` byte-for-byte.
3. **iss**: if the AS advertised `authorization_response_iss_parameter_supported`, it MUST match the expected issuer (RFC 9207).
4. If `error` is present, surface it as a typed protocol error.
5. Exchange `code` at the token endpoint with `code_verifier` and an authenticated client.
6. Validate the token response shape: `token_type` as expected, `id_token` present (OIDC), `access_token` present.
7. Validate the ID Token (see `tokens.md`) using the stored `nonce`.
8. If `at_hash` is present in the ID Token, compute and compare it against `access_token`.
9. Optionally fetch UserInfo; the returned `sub` MUST equal the ID Token's `sub`.
10. Delete the stored state record (one-time use).

## Checklist — token-endpoint client (RP)

1. Build the `application/x-www-form-urlencoded` body with grant-specific params.
2. Apply the configured client authentication:
   - `client_secret_basic`: `Authorization: Basic base64(urlencode(client_id) ':' urlencode(client_secret))`.
   - `client_secret_post`: `client_id` + `client_secret` in the body.
   - `private_key_jwt`: build a `client_assertion` JWT — `iss=sub=client_id`, `aud=issuer`, `exp` ≤ 5 min out, random `jti`; `client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer`.
   - `client_secret_jwt`: as above but HMAC-signed with `client_secret`.
   - `tls_client_auth`: present the client cert via the mTLS endpoint alias.
3. Parse JSON; on HTTP 4xx parse the OAuth error body `{ error, error_description, error_uri }`.
4. Handle DPoP nonce challenges (`WWW-Authenticate: DPoP error="use_dpop_nonce"`) by retrying with the supplied nonce.
5. Validate `token_type` matches what the AS should issue.
