# oidc-best-practices — Knowledge Base for Building an OIDC Library in TypeScript

## TL;DR
- **OIDC = OAuth 2.0 + identity.** OAuth 2.0 issues access tokens (authorization); OIDC layers an **ID Token** (signed JWT), **UserInfo Endpoint**, **Discovery**, standardized **scopes/claims**, and a **nonce** to deliver authentication. Build every interactive client on **Authorization Code + PKCE (S256)** — public and confidential alike — per RFC 9700 ("OAuth 2.0 Security Best Current Practice", January 2025) and OAuth 2.1 (current draft-ietf-oauth-v2-1-15, published 2 March 2026, expiring 3 September 2026).
- **Build the library on `panva/oauth4webapi` + `panva/jose`**; for the OP side, study `panva/node-oidc-provider`. Use Web Crypto by default (stable in Node ≥19 per the Node.js 19 release announcement "The WebCrypto API is now stable", Deno, Bun, Cloudflare Workers, browsers); gate `node:crypto` only in optional adapters. Do not write JWT crypto yourself.
- **Always reject `alg:"none"`** (the panva/jose verifier documents: "Unsecured JWTs ({ \"alg\": \"none\" }) are never accepted by this API"). **Always validate** `iss` (exact string), `aud` (must contain `client_id`), `exp`, `iat`, `nonce`, and `at_hash`/`c_hash` when present. Never use the access token to identify the user; never store tokens in `localStorage` from a SPA; never accept the implicit grant.

---

## 1. OIDC vs OAuth 2.0 — the precise relationship

### 1.1 What OIDC adds on top of OAuth 2.0
OIDC (OpenID Connect Core 1.0 — `https://openid.net/specs/openid-connect-core-1_0.html`) is a thin identity layer on top of OAuth 2.0 (RFC 6749). The new pieces are:

- **ID Token** — signed JWT (JWS, optionally JWE) describing the authentication event. REQUIRED claims: `iss`, `sub`, `aud`, `exp`, `iat`. Conditional/optional: `auth_time`, `nonce`, `acr`, `amr`, `azp` (Core §2).
- **UserInfo Endpoint** — protected by the access token (RFC 6750 Bearer), returns standardized claims as JSON or as a signed/encrypted JWT.
- **Discovery** — `.well-known/openid-configuration` metadata document (Discovery 1.0 §4).
- **JWKS endpoint** — public JWK Set at `jwks_uri`.
- **Standardized scopes** — `openid`, `profile`, `email`, `address`, `phone`, `offline_access`.
- **Standardized claims** — §5.1 (see §7 below).
- **`nonce`** — request parameter and ID Token claim; mitigates token replay/injection.
- **Logout** — Session Management, Front-Channel Logout, Back-Channel Logout, RP-Initiated Logout (separate specs).
- **`response_type`/`response_mode` extensions** — `id_token`, `code id_token`, etc., and the `form_post` response mode.
- **`request`/`request_uri` (JAR-style request objects)** — also generalized by RFC 9101.

### 1.2 Authentication ≠ Authorization — the "OAuth-as-auth" anti-pattern
A bare OAuth access token says only "this token grants these scopes at this resource server". It does **not** prove the bearer is a particular user. Using an access token (or its `sub`) to log a user in is the OAuth-as-authentication anti-pattern that OIDC was designed to fix: the ID Token is bound to a specific client (`aud = client_id`) and ties the authentication event to the client-generated `nonce`.

### 1.3 The `openid` scope is the trigger
A request is an OIDC request **iff `scope` contains `openid`**. Core §3.1.2.1: "scope REQUIRED. OpenID Connect requests MUST contain the openid scope value." Without it, the server SHOULD behave as plain OAuth and MUST NOT return an ID Token.

### 1.4 `response_type` → flow mapping
- `code` → Authorization Code flow (use this).
- `id_token` → Implicit (ID Token only).
- `id_token token` → Implicit (deprecated).
- `code id_token` / `code token` / `code id_token token` → Hybrid.
- `none` → no tokens (used in some signout scenarios).

### 1.5 Where OIDC reuses vs introduces machinery
**Reuses**: authorization endpoint, token endpoint, redirect_uri, state, scope, client_id/client_secret, all OAuth grant types.
**Adds**: ID Token, UserInfo, nonce, Discovery, dynamic registration profile, signed request objects, logout endpoints, standardized claims/scopes, JWKS.

### 1.6 OAuth 2.1 consolidation
OAuth 2.1 (draft-ietf-oauth-v2-1-15 by D. Hardt of Hellō, A. Parecki of Okta, and T. Lodderstedt of SPRIND, published 2 March 2026, expiring 3 September 2026) consolidates RFC 6749, RFC 6750, RFC 7636, RFC 8252, and RFC 9700 and **removes**:

- The **Implicit grant** (`response_type=token`).
- The **Resource Owner Password Credentials (ROPC)** grant.
- Bearer tokens in URI query parameters.
- Wildcard / non-exact redirect URI matching.

OAuth 2.1 mandates **PKCE for every authorization code request**, even confidential clients. This matches RFC 9700 §2.1.1: "Clients utilizing the authorization code grant type MUST use PKCE in order to (with the help of the authorization server) detect and prevent attempts to inject (replay) authorization codes…"

---

## 2. Flows and when to use each

### 2.1 Authorization Code with PKCE — the only recommended user-interactive flow
**Use for**: every interactive client (web app, SPA via BFF, mobile, desktop, TV via device flow), public or confidential.

**Authorization request** (front-channel `GET` to `authorization_endpoint`):
- `response_type=code` (REQUIRED)
- `client_id` (REQUIRED)
- `redirect_uri` (REQUIRED in OIDC; exact match against pre-registered URI)
- `scope=openid ...` (REQUIRED; must include `openid` for OIDC)
- `state` (RECOMMENDED — CSRF and app-state binding)
- `nonce` (RECOMMENDED for Code flow; REQUIRED in any flow that returns an ID Token from the Authorization Endpoint)
- `code_challenge` (REQUIRED per RFC 9700 / OAuth 2.1)
- `code_challenge_method=S256` (REQUIRED; **never `plain`**)
- Optional: `response_mode` (`query`, `fragment`, `form_post`), `prompt` (`none`, `login`, `consent`, `select_account`), `max_age`, `display` (`page`, `popup`, `touch`, `wap`), `ui_locales`, `id_token_hint`, `login_hint`, `acr_values`, `claims`, `request`, `request_uri`.

**Authorization response** (front-channel redirect to `redirect_uri`): `code`, `state`, and per RFC 9207 `iss` if the AS advertises `authorization_response_iss_parameter_supported=true`.

**Token request** (back-channel `POST` to `token_endpoint`, `application/x-www-form-urlencoded`):
- `grant_type=authorization_code`
- `code`
- `redirect_uri` (must match the auth request)
- `client_id` (always)
- `code_verifier` (REQUIRED; original verifier whose hash was the `code_challenge`)
- Client authentication using the configured method.

**Token response**: JSON with `access_token`, `token_type` (`Bearer` or `DPoP`), `expires_in`, `refresh_token` (optional), `id_token` (for OIDC), `scope` (if narrower than requested).

### 2.2 Implicit flow — DEPRECATED
`response_type=token` or `token id_token`. Tokens are returned in the URL fragment. RFC 9700: "Clients SHOULD NOT use the implicit grant (response type 'token') or other response types issuing access tokens in the authorization response." Removed from OAuth 2.1. Vulnerabilities: tokens in browser history/Referer, no sender-constraining, no client authentication on token issuance, no PKCE coverage, susceptible to token injection. **Do not implement.**

### 2.3 Hybrid flow
`response_type=code id_token`, `code token`, or `code id_token token`. When an ID Token is returned from the Authorization Endpoint, that ID Token MUST contain:
- `c_hash` — base64url of the left-most half of the hash of the ASCII octets of `code`, hashed with the alg used to sign the ID Token (e.g., RS256 → SHA-256, take left 128 bits).
- `at_hash` — same construction over `access_token`.
- `nonce` — verbatim of the request nonce.

Modern practice: avoid Hybrid. FAPI 2.0 explicitly removes Hybrid ("only `response_type=code` is allowed").

### 2.4 Client Credentials (RFC 6749 §4.4) — not OIDC
`grant_type=client_credentials`. No user, no ID Token. RFC 9068 §5: `sub` SHOULD correspond to a client identifier. For confidential clients only.

### 2.5 Resource Owner Password Credentials — DEPRECATED
`grant_type=password`. Removed in OAuth 2.1. Do not implement.

### 2.6 Device Authorization Grant (RFC 8628)
For TVs, CLIs, IoT.
- `POST` to `device_authorization_endpoint` with `client_id` and `scope`.
- Response: `device_code`, `user_code`, `verification_uri`, `verification_uri_complete`, `expires_in`, `interval`.
- Device polls token endpoint with `grant_type=urn:ietf:params:oauth:grant-type:device_code` and `device_code`. Errors: `authorization_pending`, `slow_down`, `access_denied`, `expired_token`.
- Add PKCE if the client can.

### 2.7 Refresh tokens
- Returned with `offline_access` scope (Core §11) or per AS policy.
- **MUST rotate for public clients** per RFC 9700 §4.14: each use returns a new refresh token; the old one is invalidated.
- **Reuse detection**: on second presentation of a rotated refresh token, invalidate the entire token family (Auth0 documents this as "automatic reuse detection"; FusionAuth and Logto implement the same; Obsidian Security: "If a previously invalidated refresh token is presented to the authorization server, it signals compromise. The entire token family must be invalidated immediately.").
- **Sender-constraining**: use DPoP (RFC 9449) or mTLS (RFC 8705).
- Absolute lifetime + inactivity timeout.
- Serialize refresh requests per session: concurrent refresh under rotation racing will kill one branch via reuse detection. A short reuse-grace window (≤30s) is a pragmatic mitigation (Mihai Andrei's writeup, Auth0 SDK behavior); production-grade systems serialize instead. Duende explicitly chose to default to **reusable** refresh tokens for confidential clients ("Reusing Refresh Tokens by Default in IdentityServer", citing Philippe De Ryck's analysis that an attacker can simply wait until rotation stops).

### 2.8 CIBA (Client-Initiated Backchannel Authentication)
Decoupled flow: the client asks the OP to authenticate a user identified out-of-band (push, second device). Three delivery modes: poll, ping, push. `backchannel_authentication_endpoint` is the entry point. Used in call centers, point-of-sale, banking. Defined by OpenID's CIBA Core 1.0.

### 2.9 Token Exchange (RFC 8693)
`grant_type=urn:ietf:params:oauth:grant-type:token-exchange`. Service A presents `subject_token` (and optional `actor_token`) and receives a new token. Used for delegation/impersonation and downstream service calls.

---

## 3. Tokens — deep dive

### 3.1 ID Token (the OIDC artifact)

**REQUIRED claims** (Core §2):
- `iss` — Issuer Identifier; HTTPS URL, no query, no fragment.
- `sub` — Subject Identifier; ≤ 255 ASCII chars; case-sensitive; combined `(iss, sub)` is the canonical user key.
- `aud` — Audience; string or array; **MUST contain the `client_id`**. If multi-valued, `azp` SHOULD be present.
- `exp` — Expiration time (NumericDate, seconds since epoch).
- `iat` — Issued-at time.

**Conditional / optional**:
- `auth_time` — REQUIRED when `max_age` was requested or `auth_time` was requested as an essential claim.
- `nonce` — REQUIRED if `nonce` was sent in the auth request; value MUST equal what the client sent.
- `acr` — case-sensitive Authentication Context Class Reference string.
- `amr` — JSON array of Authentication Methods References (IANA-registered values SHOULD be used: `pwd`, `mfa`, `otp`, `hwk`, `fpt`, `sms`, `face`, `iris`, `swk`, …).
- `azp` — Authorized party; MUST be the `client_id` when present.

**Signing** (Core §2):
- "ID Tokens MUST be signed using JWS."
- "ID Tokens MUST NOT use none as the alg value unless the Response Type used returns no ID Token from the Authorization Endpoint" and the client registered `none` use.
- Default alg is `RS256` unless the client registered a different `id_token_signed_response_alg`.
- If encrypted, MUST be signed then encrypted (Nested JWT).

**`sub` stability**: `public` subject type → same `sub` everywhere; `pairwise` subject type → different `sub` per client (per `sector_identifier_uri`).

### 3.2 Access Token

**Opaque (reference) token**: random string; RS calls `introspection_endpoint` (RFC 7662). Easy revocation, higher per-request latency.

**JWT access token (RFC 9068, October 2021)**:
- `typ` header MUST be `at+jwt` — this is the guard that prevents an ID Token being accepted as an access token.
- REQUIRED claims: `iss`, `exp`, `aud`, `sub`, `client_id`, `iat`, `jti`.
- OPTIONAL: `scope`, `auth_time`, `acr`, `amr`, plus `groups`, `roles`, `entitlements` (RFC 9068 §7.2.1 from RFC 7643).
- `aud` MUST identify the resource server. RFC 8707 `resource` indicators let the client request audience-restricted tokens.
- For grants with a resource owner, `sub` is the user. For client_credentials, `sub` SHOULD identify the client.
- MUST NOT use `alg:"none"`.

**Rule**: never use the access token to identify the user. Identity belongs to the ID Token (or UserInfo response).

### 3.3 Refresh Token
Opaque to the client. Single-use under rotation; sender-constrained for public clients (DPoP/mTLS). Absolute lifetime + inactivity timeout. Never log.

### 3.4 JWT internals — JWS, JWE, algorithms
- **JWS** (RFC 7515): `BASE64URL(header).BASE64URL(payload).BASE64URL(signature)`.
- **JWE** (RFC 7516): encrypted JWT.
- **JWA** (RFC 7518): algorithm identifiers.

**Library default allow-list**:
- ID Token signing: `RS256` (mandatory baseline), `PS256`, `ES256`, `EdDSA`. Allow `RS384/512`, `PS384/512`, `ES384/512` for symmetry.
- `HS256`/`HS384`/`HS512` — only for confidential clients (HMAC key = UTF-8 octets of `client_secret`, Core §10.1). Never expose HS to public clients; never share an HS key across many clients.
- **`alg:"none"`**: reject unconditionally. The `panva/jose` `JWTVerifyOptions` documentation states verbatim: "By default all 'alg' (Algorithm) values applicable for the used key/secret are allowed. Note: 'none' is never accepted." Replicate that posture.

**Algorithm confusion attacks**:
- The classic: `verify(token, RSA_PUBLIC_KEY)` that trusts the token's `alg`. Attacker submits `alg:"HS256"` and HMACs the token using the RSA public-key bytes as the HMAC secret.
- Mitigation: **pin allowed algs at the call site**; bind key type to algorithm; never pass the token's `alg` into the verifier as a parameter.
- Do not use `jsonwebtoken` (npm). It carries the historical CVE-2022-23541 (algorithm confusion allowing HS256 verification with an RSA public key) and CVE-2022-23540 (signature bypass when alg is omitted and secret is falsy), both affecting versions ≤ 8.5.1 and fixed in v9.0.0 (per GitHub Advisory Database GHSA-qwph-4952-7xr6 and GHSA-27h2-hvpr-p74q). Use `panva/jose`.

**`kid` handling**:
- Select the JWK by header `kid`.
- On `kid` miss, refetch JWKS **once** with single-flight.
- Never honor embedded `jwk`/`jku`/`x5u` JWS headers — attackers can pick the key.

**JWKS fetching/caching**:
- Cache with TTL (e.g., 10 min) and honor `Cache-Control`/`ETag`.
- One cache entry per issuer; bounded.
- De-duplicate concurrent fetches (single-flight per issuer; `panva/jose`'s `createRemoteJWKSet` does this).
- 5s timeout; allow-list of hosts derived from the discovered `jwks_uri` host to prevent SSRF.

### 3.5 ID Token validation — the 13 ordered checks (Core §3.1.3.7)
1. If encrypted (JWE), decrypt using the client's registered keys.
2. `iss` MUST **exactly** match the Issuer Identifier from Discovery (byte compare; no trailing-slash normalization).
3. `aud` MUST contain `client_id`. Reject untrusted extra audiences.
4. If multiple audiences are present, the ID Token SHOULD contain `azp`.
5. If `azp` is present, its value MUST be the `client_id`.
6. If the ID Token was received over direct TLS to the Token Endpoint, TLS server validation MAY substitute for signature check; otherwise the JWS signature MUST be verified using a key from the issuer's JWKS.
7. `alg` SHOULD be the default `RS256` or the client's registered `id_token_signed_response_alg`.
8. If MAC alg is used, the UTF-8 octets of `client_secret` are the key.
9. Current time MUST be before `exp` (skew typically ±30–60 s).
10. `iat` MAY be used to reject too-old tokens.
11. If `nonce` was sent, the ID Token MUST contain it; values MUST match.
12. If `acr` was requested, verify.
13. If `auth_time` was requested or `max_age` was used, verify and require re-auth if too elapsed.

### 3.6 `at_hash` / `c_hash` / `s_hash`
- `at_hash` (Core §3.1.3.6): base64url of left-most half of hash of the ASCII octets of the `access_token`, using the alg of the ID Token (`RS256` → SHA-256, take left 128 bits). REQUIRED in ID Tokens delivered alongside an access token via the Authorization Endpoint.
- `c_hash`: same over `code`. REQUIRED in ID Tokens issued at the Authorization Endpoint in Hybrid.
- `s_hash`: same over `state`, defined in FAPI 1.0 Advanced; removed by FAPI 2.0.

### 3.7 Nonce
- High-entropy, opaque, generated by the client per request.
- Bound to the user-agent session (HttpOnly cookie or server-side session — never `localStorage`).
- REQUIRED in flows returning an ID Token from the Authorization Endpoint; RECOMMENDED in plain Code flow as defense-in-depth.

---

## 4. Endpoints

### 4.1 Authorization Endpoint
Renders login/consent. GET (typically) or POST. Returns 302 with the response in `query`, `fragment`, or `form_post`.

### 4.2 Token Endpoint and client authentication methods
`token_endpoint_auth_methods_supported` lists what the AS accepts. OIDC Core §9:

- `client_secret_basic` — HTTP Basic with URL-encoded `client_id:client_secret`. Discovery default.
- `client_secret_post` — `client_id`/`client_secret` in form body.
- `client_secret_jwt` — Client signs a JWT with HMAC keyed by `client_secret`. `client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer`. Required JWT claims: `iss=sub=client_id`, `aud=token_endpoint_or_issuer`, `jti`, `exp`, optional `iat`.
- `private_key_jwt` — Client signs JWT with its private key; AS verifies against the client's JWKS. Same claims. Recommended for confidential clients.
- `tls_client_auth` and `self_signed_tls_client_auth` (RFC 8705) — mTLS.
- `none` — public clients; PKCE required.

**Recommendation**: confidential clients default to `private_key_jwt` or mTLS — no long-lived shared secret crosses the wire. FAPI 2.0 mandates one of these two.

For `aud` in client assertions, FAPI 2.0 and RFC 9700 prefer the AS's **issuer identifier** (not the token endpoint URL); many ASes accept both for interop.

### 4.3 UserInfo Endpoint (Core §5.3)
- Protected resource. Client presents the **access token** (`Authorization: Bearer <token>` or DPoP-bound).
- GET or POST. Response: JSON object MUST include `sub`.
- **`sub` MUST equal the `sub` of the ID Token** used to obtain the access token (cross-account confusion guard).
- Response MAY be a signed/encrypted JWT if the client registered `userinfo_signed_response_alg`/`userinfo_encrypted_response_alg`.
- Common pitfall: calling UserInfo with the **ID Token** — the ID Token is not an OAuth bearer token; this is wrong.

### 4.4 JWKS URI
HTTPS only. Each JWK has `kty`, `use` (`sig`/`enc`), `alg`, `kid`, plus key parameters (`n`/`e`, `crv`/`x`/`y`, etc.). Rotate by adding a new key, signing with it, removing the old key after consumers have refreshed.

### 4.5 Discovery (`.well-known/openid-configuration`)
See §6 below. Cache 24h or per `Cache-Control`.

### 4.6 Dynamic Client Registration (RFC 7591 + OIDC Registration 1.0)
POST JSON of client metadata to `registration_endpoint`; receive `client_id`, optional `client_secret`, `registration_access_token`, `registration_client_uri`. RFC 7592 adds READ/UPDATE/DELETE. The AS MUST validate registered URIs (`redirect_uris`, `jwks_uri`, `logo_uri`, `policy_uri`, `tos_uri`, `sector_identifier_uri`) for SSRF.

### 4.7 Token Introspection (RFC 7662)
POST `token`, optional `token_type_hint`, with caller authentication. Response: `{ "active": true|false, "scope", "client_id", "username", "exp", "iat", "sub", "aud", "iss", "jti", "token_type" }`. For JWT access tokens, prefer offline verification.

### 4.8 Token Revocation (RFC 7009)
POST `token` and `token_type_hint=access_token|refresh_token`. Always returns HTTP 200 regardless of token validity (no oracle).

### 4.9 End Session / RP-Initiated Logout
Per OpenID Connect RP-Initiated Logout 1.0 §2:
- `end_session_endpoint` — REQUIRED OP metadata; MUST use `https`.
- Front-channel GET parameters:
  - `id_token_hint` — RECOMMENDED.
  - `logout_hint` — OPTIONAL.
  - `client_id` — OPTIONAL; if both `client_id` and `id_token_hint` are present, the OP MUST verify they refer to the same client.
  - `post_logout_redirect_uri` — OPTIONAL; MUST be pre-registered in the client's `post_logout_redirect_uris`.
  - `state` — OPTIONAL; returned to the RP.
  - `ui_locales` — OPTIONAL.

### 4.10 Back-Channel Logout
OP POSTs a Logout Token (signed JWT) to each RP's registered `backchannel_logout_uri`. The Logout Token MUST contain:
- `iss`, `aud`, `iat`, `jti`
- `events` claim with member `"http://schemas.openid.net/event/backchannel-logout"` mapping to a JSON object `{}`
- `sub` and/or `sid`

Logout Token MUST NOT contain `nonce`. OP metadata: `backchannel_logout_supported`, `backchannel_logout_session_supported`. RP metadata: `backchannel_logout_uri`, `backchannel_logout_session_required`. RP MUST validate signature, `iss`, `aud`, `iat`, the events claim, and presence of `sub` or `sid`. OP SHOULD use short expirations (the spec suggests at most two minutes).

### 4.11 Front-Channel Logout and Session Management
Front-Channel Logout: OP returns HTML embedding an `<iframe>` per RP's `frontchannel_logout_uri`. Session Management 1.0: cross-origin `postMessage` from a `check_session_iframe`. Both depend on third-party cookies. Apple Safari has blocked third-party cookies by default since 2020, Firefox blocks them via Total Cookie Protection by default, and although Google cancelled its own Chrome deprecation plan on 22 April 2025 (Privacy Sandbox blog: "Instead of deprecating third-party cookies, we would introduce a new experience in Chrome that lets people make an informed choice"), the trend is irreversible enough that you should plan for CHIPS/Partitioned cookies or migrate to **back-channel logout** regardless.

### 4.12 PAR — Pushed Authorization Requests (RFC 9126)
- POST to `pushed_authorization_request_endpoint` with the full authorization request as `application/x-www-form-urlencoded`, authenticated as the client.
- Response: `{ "request_uri": "urn:ietf:params:oauth:request_uri:<opaque>", "expires_in": <seconds> }`.
- Client then redirects to `authorization_endpoint?client_id=...&request_uri=...`.
- Benefits: integrity-protected request, no Referer/log leakage, no URL length limits, AS can authenticate before redirecting the user.
- AS metadata: `pushed_authorization_request_endpoint`, `require_pushed_authorization_requests`.
- FAPI 2.0 mandates PAR.

### 4.13 JAR — JWT-Secured Authorization Request (RFC 9101)
Replace front-channel parameters with `request=<JWS>` or `request_uri=<URL>`. The Request Object is a JWT signed (and optionally encrypted) by the client. Defends against parameter tampering; non-repudiation when needed. FAPI 2.0 makes JAR optional (covered by PAR's confidentiality); FAPI 1.0 Advanced requires JAR.

---

## 5. Security topics — RFC 9700 as authoritative

### 5.1 PKCE everywhere, S256 only
- `code_verifier`: 43–128 chars; ≥256 bits of entropy from a CSPRNG.
- `code_challenge = BASE64URL(SHA-256(code_verifier))`.
- `code_challenge_method=S256`.
- **`plain` MUST NOT be used.** RFC 7636 §4.4.1: "Clients MUST NOT downgrade to 'plain' after trying the 'S256' method." An error when `S256` is presented can only mean a faulty server or a MITM downgrade attempt.
- PKCE provides robust CSRF protection even against attackers who can read the authorization response (RFC 9700).

### 5.2 `state` for CSRF (and beyond)
High-entropy, unpredictable, bound to the user-agent session (e.g., `__Host-state` cookie or server session). Even with PKCE, keep `state` for (a) carrying app return-target context, (b) detecting duplicate callbacks, (c) interop with ASes that do not advertise PKCE.

### 5.3 `nonce` for ID Token replay
Different role from `state`. Bind to the user-agent session. Always include in the auth request; always verify in the ID Token.

### 5.4 `iss` parameter (RFC 9207) — prevents mix-up
AS MAY include `iss` in the authorization response; clients MUST compare it to the expected issuer of the AS the request was sent to (RFC 9207: "Clients MUST extract the value of the iss parameter from authorization responses they receive if the parameter is present… If the value does not match the expected issuer identifier, clients MUST reject the authorization response"). Advertised by `authorization_response_iss_parameter_supported`. Required by FAPI 2.0. Mitigates the Mainka/Mladenov/Schwenk "mix-up attack" against multi-AS clients.

### 5.5 Exact `redirect_uri` matching
RFC 9700 §4.1 + OAuth 2.1: exact string match. No wildcards, no path tricks, no open redirectors at the redirect URI. Loopback `http://127.0.0.1:<dynamic port>` (or `[::1]`) is the only `http` exception (RFC 8252).

### 5.6 Authorization code injection
PKCE binds the code to the original verifier; `nonce` binds the ID Token; `iss` rejects cross-AS. Use all three.

### 5.7 Token leakage
Never put tokens in URLs (RFC 6750 §2.3 discourages; OAuth 2.1 forbids). Use `Authorization` header or body. Codes are short-lived (1–10 min) and single-use; the AS MUST reject reuse.

### 5.8 DPoP (RFC 9449) and mTLS (RFC 8705) — sender-constrained tokens
**DPoP**: client generates a per-instance key pair. Each request carries a `DPoP` header containing a JWT signed by the private key with claims `htm` (method), `htu` (URL, no fragment), `iat`, `jti`, and the JWK in the JWS header. The AS binds the access token via `cnf.jkt` (JWK thumbprint). The RS verifies the proof matches the cnf. AS may require a fresh server-supplied `nonce` via `WWW-Authenticate: DPoP error="use_dpop_nonce"`. Works for public and confidential clients.

**mTLS**: token is bound to the client's X.509 cert; `cnf.x5t#S256` carries the cert thumbprint. Requires TLS terminating in a layer that exposes the client cert to the RS.

### 5.9 Resource indicators (RFC 8707) and `aud` confusion
Client sends `resource=https://api.example.com` in the auth/token request; AS issues an access token with that `aud`. Multi-`aud` tokens are dangerous; prefer one resource per token.

### 5.10 SSRF via JWKS / `request_uri` / `logo_uri` / `sector_identifier_uri`
These cause the AS to make outbound HTTP requests. Treat as untrusted:
- Scheme allow-list (`https` only).
- Resolve DNS and reject internal/loopback/link-local addresses (`127.0.0.0/8`, `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `169.254.0.0/16`, `::1`, `fc00::/7`, `fe80::/10`).
- Strict timeouts and response size caps.
- For `request_uri`, prefer `require_request_uri_registration=true` and an allow-list. **PAR removes the need for the AS to fetch.**

### 5.11 Subdomain takeover and redirect URI risk
If `https://foo.example.com/callback` is registered and the subdomain is taken over (orphan CNAME), the attacker controls the redirect. Audit registered redirect URIs; do not allow registration on shared/dangling subdomains.

### 5.12 Cookie security
- RP session cookie (BFF): `Secure; HttpOnly; SameSite=Lax` (or `Strict`). `__Host-` prefix (no `Domain`, `Path=/`, `Secure`).
- OP session cookies used in cross-site iframes: `Partitioned` (CHIPS) is now the standard mechanism for third-party cookie deprecation.

### 5.13 JWT `crit` header
A JWS verifier MUST understand any header listed in `crit`; if there is an unrecognized critical header, reject. `panva/jose` exposes a `crit` option to declare which extensions you understand.

### 5.14 Algorithm confusion / `alg: none`
Covered in §3.4: pin algorithms; bind key type to algorithm; never accept `alg:"none"`. The npm `jsonwebtoken` library's history (CVE-2022-23541, CVE-2022-23540) is the reason this matters in practice.

### 5.15 Logout security
Prefer back-channel logout. Front-channel logout is degraded in modern browsers; either adopt CHIPS or migrate.

---

## 6. Discovery and metadata

Per OIDC Discovery 1.0 §3 and RFC 8414:

**REQUIRED OP metadata**:
- `issuer` — HTTPS URL, no query/fragment. MUST equal the URL used as the prefix for `.well-known/openid-configuration` (string equality), and MUST equal the `iss` claim of issued ID Tokens.
- `authorization_endpoint`
- `jwks_uri` — public JWK Set; MUST NOT contain private/symmetric keys.
- `response_types_supported` — dynamic OPs MUST support `code`, `id_token`, `id_token token`.
- `subject_types_supported` — `public` and/or `pairwise`.
- `id_token_signing_alg_values_supported` — MUST include `RS256`.
- `token_endpoint` — REQUIRED unless only Implicit flow used.

**RECOMMENDED**: `userinfo_endpoint`, `registration_endpoint`, `scopes_supported` (MUST include `openid`), `claims_supported`.

**OPTIONAL** (selection):
- `response_modes_supported` (default `["query","fragment"]`)
- `grant_types_supported` (default `["authorization_code","implicit"]`)
- `acr_values_supported`
- `id_token_encryption_alg_values_supported`, `id_token_encryption_enc_values_supported`
- `userinfo_signing_alg_values_supported`, `userinfo_encryption_alg_values_supported`, `userinfo_encryption_enc_values_supported`
- `request_object_signing_alg_values_supported` (SHOULD support `none` and `RS256`)
- `request_object_encryption_alg_values_supported`, `request_object_encryption_enc_values_supported`
- `token_endpoint_auth_methods_supported` (default `client_secret_basic`)
- `token_endpoint_auth_signing_alg_values_supported` — `none` MUST NOT be used
- `display_values_supported`
- `claim_types_supported` (`normal`, `aggregated`, `distributed`; default `normal`)
- `claims_locales_supported`, `ui_locales_supported`
- `claims_parameter_supported` (default `false`)
- `request_parameter_supported` (default `false`)
- `request_uri_parameter_supported` (default `true`)
- `require_request_uri_registration` (default `false`)
- `op_policy_uri`, `op_tos_uri`, `service_documentation`
- `code_challenge_methods_supported` (e.g., `["S256"]`)
- `pushed_authorization_request_endpoint`, `require_pushed_authorization_requests`
- `dpop_signing_alg_values_supported`
- `authorization_response_iss_parameter_supported`
- `revocation_endpoint`, `introspection_endpoint`
- `end_session_endpoint`, `backchannel_logout_supported`, `backchannel_logout_session_supported`
- `mtls_endpoint_aliases` (RFC 8705) — alternative endpoints for mTLS

**Issuer validation rules**:
1. The string used to construct the well-known URL MUST equal the `issuer` value returned (exact, including trailing slash or its absence).
2. The same string MUST equal `iss` in subsequent ID Tokens.
3. `https` only; no fragment, no query component.

**Caching**: TTL 24h or honor `Cache-Control`. Re-fetch on JWKS `kid` miss.

---

## 7. Standardized scopes and claims

### 7.1 Scopes (Core §5.4)
- `openid` (MANDATORY) — triggers OIDC.
- `profile` → `name`, `family_name`, `given_name`, `middle_name`, `nickname`, `preferred_username`, `profile`, `picture`, `website`, `gender`, `birthdate`, `zoneinfo`, `locale`, `updated_at`.
- `email` → `email`, `email_verified`.
- `address` → `address`.
- `phone` → `phone_number`, `phone_number_verified`.
- `offline_access` (Core §11) — request refresh token; OP MUST get explicit consent.

### 7.2 Standard Claims (Core §5.1)
All strings unless noted:
- `sub`
- `name`, `given_name`, `family_name`, `middle_name`, `nickname`
- `preferred_username` — not guaranteed unique
- `profile`, `picture`, `website` — URLs
- `email`, `email_verified` (boolean)
- `gender`
- `birthdate` — ISO 8601 `YYYY-MM-DD` (year may be `0000` if unknown)
- `zoneinfo` — IANA tz name
- `locale` — BCP47 tag
- `phone_number` — E.164 RECOMMENDED
- `phone_number_verified` (boolean)
- `address` — JSON object
- `updated_at` — NumericDate

**`address` sub-fields (§5.1.1)**: `formatted`, `street_address`, `locality`, `region`, `postal_code`, `country`.

**Claim stability (§5.7)**: only `(iss, sub)` is guaranteed stable and unique. **Never key user accounts on `email` alone** — `email_verified` only attests the user controlled the address at some past time; emails can be reassigned, recovered by IdP support, etc.

### 7.3 Aggregated and distributed claims (§5.6.2)
- **Aggregated**: a signed JWT containing claims, embedded under `_claim_sources`/`_claim_names`. The RP verifies the inner JWT.
- **Distributed**: the claim is fetched by the RP from a URL with an access token, found in `_claim_sources`.

### 7.4 `claims` request parameter (§5.5)
JSON with two top-level keys, `userinfo` and `id_token`, each mapping claim names to `null` (voluntary) or `{"essential":true, "value":..., "values":[...]}` (essential):

```json
{
  "id_token": { "acr": { "essential": true, "values": ["urn:mace:incommon:iap:silver"] } },
  "userinfo": { "email": { "essential": true }, "email_verified": null }
}
```

### 7.5 `acr` / `amr`
- `acr` — AS-defined string identifying the assurance level / authentication ceremony (e.g., `urn:mace:incommon:iap:silver`, `0`, `1`).
- `amr` — array of methods (`pwd`, `mfa`, `otp`, `hwk`, `fpt`, `sms`, `face`, `iris`, `swk`).
- RFC 9470 ("Step-Up Authentication Challenge"): RS responds `401 WWW-Authenticate: Bearer error="insufficient_user_authentication", acr_values="...", max_age="..."`; client repeats with `acr_values`/`max_age`.

---

## 8. Special cases and profiles

### 8.1 Native / mobile apps (RFC 8252 / BCP 212)
- MUST use an **external user-agent** (system browser or in-app browser tab: Chrome Custom Tabs on Android, `ASWebAuthenticationSession`/`SFAuthenticationSession` on iOS).
- MUST NOT use embedded WebViews.
- Redirect URI options:
  - Claimed-https (App Links / Universal Links) — preferred when available.
  - Custom URI scheme — MUST be a reverse-DNS name owned by the app (`com.example.app:/oauth`).
  - Loopback `http://127.0.0.1:<dynamic port>` or `http://[::1]:<dynamic port>` — the only `http` case acceptable.
- PKCE is mandatory. Public client (`token_endpoint_auth_method=none`).
- Reference libraries: `AppAuth-Android`, `AppAuth-iOS`, `AppAuth-JS`.

### 8.2 SPA / browser-based apps
Per the OAuth WG draft "OAuth 2.0 for Browser-Based Apps":
- **Preferred**: Backend-for-Frontend (BFF). The BFF is the OAuth client; tokens never reach the browser; the browser holds an HttpOnly session cookie.
- Token-Mediating Backend (TMB) is a weaker alternative — backend exchanges tokens then forwards to the SPA — and is not equivalent to BFF (Auth0: "If your backend is passing tokens to the browser in any form, you haven't implemented BFF").
- If pure SPA is unavoidable: Authorization Code + PKCE; public client; **no refresh tokens** (or DPoP-bound very short-lived only). The Spring Authorization Server team writes: "There are no plans to implement refresh tokens for Public Clients, as there are no browser APIs that allow refresh tokens to be stored in a secure way."
- Never store tokens in `localStorage` (fully readable by XSS). `sessionStorage` is marginally better but XSS-readable. In-memory plus silent renewal via `prompt=none` iframe is acceptable but degraded under third-party cookie deprecation.

### 8.3 FAPI 1.0 Advanced
PAR + JAR (signed Request Objects), `id_token` as detached signature in Hybrid, mTLS or `private_key_jwt`, S256 PKCE. Signing algs restricted to `PS256`, `ES256`.

### 8.4 FAPI 2.0 Security Profile (openid.net/specs/fapi-security-profile-2_0-final.html)
- **`response_type=code` only** — Hybrid removed.
- **PAR mandatory.**
- **Sender-constrained access tokens** via mTLS or DPoP — bearer is not acceptable.
- Client authentication: mTLS or `private_key_jwt` (no shared secrets).
- PKCE S256 with per-request challenge.
- `iss` parameter in authorization response (RFC 9207) — mandatory.
- For `private_key_jwt`, `aud` MUST be the AS's issuer identifier string (not the endpoint URL, not an array).
- Refresh token rotation is **prohibited** when used with confidential clients and sender-constrained tokens (FAPI 2.0 §5.3 — rotation adds operational fragility without security gain in that case).
- Clock skew: accept `iat`/`nbf` between 0 and 10 seconds in the future; reject beyond 60 seconds in the future.

### 8.5 Multi-tenant / per-tenant issuers
Each tenant has its own issuer URL (e.g., `https://idp.example.com/tenants/{id}`) and its own Discovery document. Library MUST treat `issuer` as opaque; do not parse. Tenant comparison is exact-string on `iss` claim.

### 8.6 Step-up authentication (RFC 9470)
`WWW-Authenticate: Bearer error="insufficient_user_authentication"` with `acr_values` and `max_age`. Client repeats the auth request with those.

---

## 9. Building an OIDC library — TypeScript-focused architecture

### 9.1 Module structure
```
src/
  core/
    protocol/    // request builders, response parsers, error mapping
    jwt/         // wrappers over panva/jose
    pkce/        // verifier + S256 challenge
    crypto/      // Web Crypto helpers (random, hash)
    discovery/   // metadata fetch + cache + validate
    jwks/        // JWKS fetch, cache, single-flight, kid lookup
    validate/    // ID Token / access-token / logout-token validators
  rp/
    client.ts    // high-level Client factory
    storage.ts   // pluggable state/nonce/code_verifier store
    http.ts      // pluggable fetch
    logout.ts
  op/            // OP recipes / re-export node-oidc-provider
  errors.ts
  types.ts
  index.ts
```

### 9.2 Crypto: Web Crypto by default
Web Crypto (`globalThis.crypto.subtle`) is stable in Node ≥19 (Node.js 19 release blog, nodejs.org/en/blog/announcements/v19-release-announce: "The WebCrypto API is now stable"), Deno, Bun, browsers, Cloudflare Workers, Vercel Edge. `node:crypto` is Node-only. Use Web Crypto by default; gate `node:crypto` only in legacy adapters. `panva/oauth4webapi` does exactly this — its `package.json` lists `bun`, `cloudflare`, `deno`, `edge`, `workerd`, `workers` among keywords and ships **zero runtime dependencies**.

### 9.3 JWT/JOSE library choice
- **Use `panva/jose`**: cross-runtime, modern, secure defaults. The `JWTVerifyOptions` doc states verbatim "Unsecured JWTs ({ \"alg\": \"none\" }) are never accepted by this API." It exposes `createRemoteJWKSet(url)` with built-in caching/single-flight, supports algorithm allow-lists, and supports `typ` checks (for `at+jwt`).
- **Do not use `jsonwebtoken` (npm)** — CVE-2022-23541 (algorithm confusion: HS256 verification with RSA public key) and CVE-2022-23540 (signature bypass when alg is omitted and secret is falsy) both affecting versions ≤ 8.5.1, fixed in v9.0.0 (GHSA-qwph-4952-7xr6, GHSA-27h2-hvpr-p74q).
- `node-jose` is heavier and Node-only.

### 9.4 `oauth4webapi` vs `openid-client`
- `oauth4webapi` (panva): low-level, function-based, framework-free, Web Crypto, ESM only, zero deps. The right engine for a new library or for users wanting minimum surface area.
- `openid-client` (panva): higher-level `Client` class with auto-discovery, callback handling, refresh, UserInfo. Excellent reference for ergonomics.

### 9.5 Public API shape — function-first, with optional Client wrapper

```ts
// Discriminated union for flow selection
type AuthRequest =
  | { flow: 'code'; scopes: string[]; state: string; nonce: string;
      codeChallenge: string; codeChallengeMethod: 'S256';
      redirectUri: string; extra?: Record<string, string> }
  | { flow: 'par'; requestUri: string }
  | { flow: 'device'; userCode: string };

interface ClientConfig {
  readonly issuer: string;                 // exact issuer URL
  readonly clientId: string;
  readonly redirectUri: string;
  readonly clientAuth:
    | { method: 'none' }
    | { method: 'client_secret_basic' | 'client_secret_post'; secret: string }
    | { method: 'client_secret_jwt'; secret: string; alg: 'HS256'|'HS384'|'HS512' }
    | { method: 'private_key_jwt'; privateKey: CryptoKey; kid: string;
        alg: 'RS256'|'PS256'|'ES256'|'EdDSA' }
    | { method: 'tls_client_auth'; cert: ArrayBuffer; key: CryptoKey };
  readonly defaultScopes?: readonly string[];
  readonly clockSkewSeconds?: number;       // default 30
  readonly fetch?: typeof fetch;
  readonly clock?: () => number;
  readonly storage?: StateStore;
  readonly logger?: Logger;                 // never logs tokens
}

// Tree-shakeable named exports
export async function discover(issuer: string): Promise<OpMetadata>;
export async function buildAuthorizationUrl(meta: OpMetadata, cfg: ClientConfig, req: AuthRequest): Promise<URL>;
export async function exchangeCode(
  meta: OpMetadata, cfg: ClientConfig,
  params: { code: string; codeVerifier: string; state?: string; iss?: string }
): Promise<TokenResponse>;
export async function validateIdToken(
  meta: OpMetadata, cfg: ClientConfig, idToken: string,
  opts: { nonce: string; maxAge?: number; acrValues?: string[];
          accessToken?: string; code?: string }
): Promise<IdTokenClaims>;
export async function fetchUserInfo(meta: OpMetadata, accessToken: string): Promise<UserInfo>;
export async function refresh(
  meta: OpMetadata, cfg: ClientConfig, refreshToken: string,
  opts?: { scopes?: string[]; resource?: string }
): Promise<TokenResponse>;
export async function buildLogoutUrl(meta: OpMetadata, params: {
  idTokenHint?: string; clientId?: string;
  postLogoutRedirectUri?: string; state?: string;
}): Promise<URL>;
```

Optional higher-level wrapper: `export function createClient(cfg: ClientConfig): Promise<Client>;`.

### 9.6 Strong types

```ts
// Branded opaque tokens
type AccessToken = string & { readonly __brand: 'AccessToken' };
type RefreshToken = string & { readonly __brand: 'RefreshToken' };
type IdToken = string & { readonly __brand: 'IdToken' };

// OAuth error union — standard + OIDC + DPoP codes verbatim
export type OAuthErrorCode =
  | 'invalid_request' | 'invalid_client' | 'invalid_grant'
  | 'unauthorized_client' | 'unsupported_grant_type'
  | 'invalid_scope' | 'access_denied' | 'server_error'
  | 'temporarily_unavailable' | 'invalid_token' | 'insufficient_scope'
  // OIDC (Core §3.1.2.6)
  | 'interaction_required' | 'login_required'
  | 'account_selection_required' | 'consent_required'
  | 'invalid_request_uri' | 'invalid_request_object'
  | 'request_not_supported' | 'request_uri_not_supported'
  | 'registration_not_supported'
  // DPoP (RFC 9449)
  | 'use_dpop_nonce' | 'invalid_dpop_proof';

export interface IdTokenClaims {
  readonly iss: string;
  readonly sub: string;
  readonly aud: string | readonly string[];
  readonly exp: number;
  readonly iat: number;
  readonly auth_time?: number;
  readonly nonce?: string;
  readonly acr?: string;
  readonly amr?: readonly string[];
  readonly azp?: string;
  readonly [claim: string]: unknown;   // index signature for custom claims
}

// Discriminated error hierarchy
export type OidcError =
  | { kind: 'protocol'; code: OAuthErrorCode; description?: string; uri?: string }
  | { kind: 'validation'; reason: string; claim?: string }
  | { kind: 'network'; cause: unknown }
  | { kind: 'http'; status: number; body: unknown };
```

### 9.7 Pluggable storage

```ts
export interface StateStore {
  put(key: string, value: StoredState, ttlSeconds: number): Promise<void>;
  take(key: string): Promise<StoredState | undefined>; // consume once
}
interface StoredState {
  state: string; nonce: string; codeVerifier: string;
  redirectUri: string; createdAt: number;
}
```
Ship an in-memory adapter, a cookie-based adapter (signed/encrypted), and document a Redis adapter.

### 9.8 Pluggable HTTP and clock
Inject `fetch` (default `globalThis.fetch`) and a `clock(): number` returning epoch seconds — essential for testable expiry logic.

### 9.9 Logging / redaction
Pass a structured logger; never log `code`, `access_token`, `refresh_token`, `id_token`, `code_verifier`, `client_secret`, DPoP keys. When logging URLs, strip these params.

### 9.10 Concurrency
- **JWKS single-flight**: deduplicate concurrent JWKS fetches per issuer so a `kid` miss doesn't trigger N parallel requests. `panva/jose`'s `createRemoteJWKSet` does this; if you roll your own, keep a per-issuer in-flight `Promise`.
- **Refresh serialization**: per refresh-token family, serialize the refresh call (mutex). Rotation + reuse detection burns the family on a race; serializing avoids the race.

### 9.11 Clock skew
Default 30s, configurable 0–60s. FAPI 2.0 allows up to 10s future and caps at 60s.

### 9.12 String comparison
- `iss` and `aud` — exact byte comparison (no normalization).
- HMAC secrets / client secrets — timing-safe compare (`crypto.subtle.timingSafeEqual` equivalent).

### 9.13 URL building
Use `URL` + `URLSearchParams`. Never string-concatenate `'?' + key + '=' + value`. Double-URL-encoding is the most common cause of `redirect_uri_mismatch`. `redirect_uri` must be byte-identical to the registered one (case, trailing slash, query order all matter — pre-register the canonical form).

### 9.14 ESM / tree-shaking / runtime support
Pure ESM, `"sideEffects": false`. Target ES2022+ (Node 20 baseline; users on older runtimes must transpile) — exactly what `oauth4webapi` does. Avoid CommonJS-only deps. Avoid `process`, `Buffer`, `__dirname` in the core.

### 9.15 Testing
- **OpenID Foundation Certification suite** (openid.net/certification) — run RP-side and OP-side conformance.
- Table-driven tests for the validator with a corpus covering every step of §3.1.3.7.
- Property tests for PKCE: `code_verifier` entropy and `BASE64URL(SHA-256(verifier)) === challenge`.
- Test vectors from RFC 7515 Appendix A (JWS), RFC 7516 Appendix A (JWE), RFC 7519 §3.1.
- Mock fetch with deterministic JWKS responses.

### 9.16 Static analysis and supply chain
- `tsc --strict`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`.
- ESLint with `eslint-plugin-security`, `eslint-plugin-no-unsanitized`. Ban `eval`, `Function(...)`.
- Minimal runtime deps: the core should depend on **only `jose`**. `oauth4webapi` ships zero deps; match that for the protocol layer.
- Pin lockfile; audit transitive deps in CI; reproducible builds.

### 9.17 Versioning and docs
- Strict semver. Document each token-validation change as breaking.
- Ship a threat model: what the library prevents (alg-confusion, code injection, replay, mix-up, CSRF) and what it does NOT (XSS in your SPA, CSP, cookie config, TLS pinning, secrets management).

---

## 10. Common pitfalls and anti-patterns (named)

- Using the **access token** to identify the user. Use the **ID Token** (or UserInfo with the access token).
- Skipping signature verification "because we trust the issuer".
- **Trusting the `alg` from the token header**. Pin allowed algs at the verifier.
- HS256 with a shared secret across many clients.
- Wildcard or substring `redirect_uri` matching.
- Not validating `nonce`.
- Not validating `aud`.
- Storing tokens in `localStorage` in SPAs.
- Implementing the Implicit flow today.
- Long-lived refresh tokens without rotation.
- Forgetting to validate `iss`.
- Using a JWT library that doesn't reject `alg:"none"` by default.
- Sending the ID Token to APIs as the access token (wrong `aud`, wrong `typ`).
- Calling UserInfo with the ID Token instead of the access token.
- Caching JWKS forever; not honoring `kid` rotation.
- Not handling `kid` not found by refetching JWKS **once**.
- Hardcoding endpoints instead of using Discovery.
- Trusting redirect parameters without `state` and `iss` validation.

---

## 11. Concrete checklists

### 11.1 What a correct ID Token validator MUST do (per Core §3.1.3.7)
1. Parse the JWT; reject malformed header/claims.
2. Reject `alg:"none"`. Pin allowed algs (e.g., `[RS256, PS256, ES256, EdDSA]`).
3. If encrypted (JWE), decrypt using the client's registered decryption keys.
4. Locate signing key by `kid` in cached JWKS; on miss, refetch JWKS once (single-flight).
5. Verify JWS signature.
6. `iss` MUST exactly equal the discovered issuer.
7. `aud` MUST contain `client_id`. Reject untrusted extra audiences.
8. If `azp` present, MUST equal `client_id`.
9. `exp` > now − skew; `iat` ≤ now + skew; optionally `iat` > now − maxAge.
10. `nonce` MUST equal the value sent in the request.
11. If `auth_time` requested or `max_age` set: `auth_time` MUST be present and acceptable.
12. If `acr` requested: verify.
13. If `at_hash`/`c_hash` present (Hybrid/Implicit), compute and compare.
14. Return typed claims; never expose the raw JWT to higher layers.

### 11.2 What a correct authorization response handler MUST do
1. Parse `state`, `code`, `iss`, `error`.
2. **State**: look up stored state record; abort if missing; match `state` byte-for-byte.
3. **iss**: if AS advertised `authorization_response_iss_parameter_supported`, MUST match the expected issuer (RFC 9207).
4. If `error` present, surface as typed `protocol` error.
5. Exchange `code` at the token endpoint with `code_verifier` and authenticated client.
6. Validate token response shape: `token_type` matches expectation, `id_token` presence (OIDC), `access_token` presence.
7. Validate the ID Token (§11.1) using the stored `nonce`.
8. If `at_hash` present in the ID Token, compute and compare against `access_token`.
9. Optionally fetch UserInfo; the returned `sub` MUST equal the ID Token's `sub`.
10. Delete the stored state record (one-time).

### 11.3 What a correct token-endpoint client MUST do
1. Build `application/x-www-form-urlencoded` body with grant-specific params.
2. Apply configured client authentication:
   - `client_secret_basic`: `Authorization: Basic base64(urlencode(client_id) ':' urlencode(client_secret))`.
   - `client_secret_post`: `client_id` + `client_secret` in body.
   - `private_key_jwt`: build `client_assertion` JWT with `iss=sub=client_id`, `aud=issuer`, `exp` ≤ 5 min from now, `jti` random; `client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer`.
   - `client_secret_jwt`: similar but HMAC-signed.
   - `tls_client_auth`: present client cert via the mTLS endpoint alias.
3. Parse JSON; on HTTP 4xx, parse OAuth error body `{ error, error_description, error_uri }`.
4. Handle DPoP nonce challenges (`WWW-Authenticate: DPoP error="use_dpop_nonce"`) by retrying with the supplied nonce.
5. Validate `token_type` matches what the AS should issue.

### 11.4 What an OP MUST do on each endpoint
- **Authorization endpoint**: validate `client_id`, `redirect_uri` (exact match), `scope` (contains `openid`), `response_type` (registered for this client), `code_challenge` (required), `nonce` if required by the flow. Authenticate the user, obtain consent, return an authorization code bound to `(client_id, redirect_uri, code_challenge, nonce, scope, auth_time)`.
- **Token endpoint**: authenticate the client, validate `code` (one-time, unexpired, bound to client + redirect_uri), validate `code_verifier` against the stored `code_challenge`, issue access/refresh/ID tokens with correct claims and signing.
- **UserInfo**: require an access token with `openid` scope; return `sub` matching the ID Token; do not return claims the user did not consent to.
- **JWKS**: serve only public keys; rotate with overlapping validity.
- **Discovery**: return `issuer` byte-identical to the URL prefix; never include private keys.
- **Revocation**: always return 200.
- **Introspection**: authenticate the caller (usually the RS).
- **End session**: validate `id_token_hint`, validate `post_logout_redirect_uri` (exact match against registered list), revoke local session, send back-channel logout to each registered RP, redirect.

---

## 12. Resources

**OpenID specs**
- OpenID Connect Core 1.0 — https://openid.net/specs/openid-connect-core-1_0.html
- OpenID Connect Discovery 1.0 — https://openid.net/specs/openid-connect-discovery-1_0.html
- OpenID Connect Dynamic Client Registration 1.0 — https://openid.net/specs/openid-connect-registration-1_0.html
- OpenID Connect Session Management 1.0 — https://openid.net/specs/openid-connect-session-1_0.html
- OpenID Connect Front-Channel Logout 1.0 — https://openid.net/specs/openid-connect-frontchannel-1_0.html
- OpenID Connect Back-Channel Logout 1.0 — https://openid.net/specs/openid-connect-backchannel-1_0.html
- OpenID Connect RP-Initiated Logout 1.0 — https://openid.net/specs/openid-connect-rpinitiated-1_0.html
- FAPI 2.0 Security Profile — https://openid.net/specs/fapi-security-profile-2_0-final.html
- CIBA Core 1.0

**IETF RFCs**
- RFC 6749 OAuth 2.0, RFC 6750 Bearer
- RFC 7009 Revocation, RFC 7515 JWS, RFC 7516 JWE, RFC 7517 JWK, RFC 7518 JWA, RFC 7519 JWT
- RFC 7521 Assertion Framework, RFC 7522 SAML, RFC 7523 JWT Assertion
- RFC 7591 Dynamic Registration, RFC 7592 Management, RFC 7636 PKCE, RFC 7662 Introspection
- RFC 8252 Native Apps (BCP 212) — https://www.rfc-editor.org/rfc/rfc8252.html
- RFC 8414 AS Metadata, RFC 8628 Device Grant, RFC 8693 Token Exchange
- RFC 8705 mTLS, RFC 8707 Resource Indicators
- RFC 9068 JWT Access Tokens — https://datatracker.ietf.org/doc/html/rfc9068
- RFC 9101 JAR, RFC 9126 PAR
- RFC 9207 Issuer Identification — https://www.rfc-editor.org/rfc/rfc9207.html
- RFC 9449 DPoP — https://datatracker.ietf.org/doc/html/rfc9449
- RFC 9470 Step-Up Auth
- RFC 9700 OAuth 2.0 Security BCP — https://datatracker.ietf.org/doc/rfc9700/
- OAuth 2.0 for Browser-Based Apps (Internet-Draft) — https://datatracker.ietf.org/doc/html/draft-ietf-oauth-browser-based-apps
- OAuth 2.1 (draft-ietf-oauth-v2-1-15, published 2 March 2026) — https://datatracker.ietf.org/doc/draft-ietf-oauth-v2-1/

**Implementation references**
- `panva/oauth4webapi` — https://github.com/panva/oauth4webapi
- `panva/jose` — https://github.com/panva/jose
- `panva/node-oidc-provider` — https://github.com/panva/node-oidc-provider
- `panva/openid-client`
- OpenIddict (.NET), Spring Authorization Server (Java), Keycloak, AppAuth-JS/Android/iOS
- OpenID Foundation Certification — https://openid.net/certification/

**Vendor docs**
- Auth0 — https://auth0.com/docs/authenticate/protocols/openid-connect-protocol
- Microsoft identity platform — https://learn.microsoft.com/en-us/entra/identity-platform/v2-protocols-oidc
- Google Identity, Okta developer, Curity guides
- Pragmatic Web Security / Philippe De Ryck writings

**Assurance**
- NIST SP 800-63C (Federation)

---

## Recommendations (decision-ready, with thresholds)

1. **Build on `panva/jose` + `panva/oauth4webapi` as the substrate.** Do not write JWT crypto yourself. Wrap them with named-export functions and an optional `createClient(...)` factory.
2. **Make PKCE+S256, `state`, `nonce`, `iss` (RFC 9207), and exact `redirect_uri` matching non-optional.** Don't expose knobs for the unsafe variants.
3. **Default to Authorization Code.** Ship Device Grant. Do not ship Implicit or ROPC at all.
4. **Confidential clients default to `private_key_jwt`** (or mTLS) with `client_secret_basic` available as a compat path.
5. **For SPAs: recommend BFF in docs.** If shipping a SPA adapter, ban `localStorage`, default to in-memory with silent renew, and document the XSS threat model. **Threshold to move from "warn" to "refuse"**: SPA stores tokens client-side AND no DPoP — disallow refresh tokens entirely in that configuration.
6. **DPoP and resource indicators on by default** for new deployments — sender-constrained tokens dramatically cap the blast radius of XSS or token theft. **Threshold to require DPoP**: any public client requesting `offline_access`.
7. **Refresh tokens**: rotate + reuse-detect + per-session serialization. Provide a `reuseGraceSeconds` configurable default of 0, allow up to 30. **Threshold to disable rotation**: confidential client + sender-constrained tokens (per FAPI 2.0 §5.3).
8. **Run the OpenID Foundation Conformance Suite in CI** for both RP and OP modes; gate releases on a green run.
9. **Threshold to enter FAPI 2.0 strict mode**: user enables PAR + (mTLS or DPoP) + (`private_key_jwt` or mTLS) — the library should then reject Hybrid, reject bearer, enforce iss, enforce 10s/60s clock-skew rules.
10. **Threshold to remove Implicit/Hybrid support**: now. Provide a migration guide to Code+PKCE.

---

## Caveats

- **OAuth 2.1 is still a draft** (draft-ietf-oauth-v2-1-15, expiring 3 September 2026). Cite **RFC 9700** for normative force; cite the OAuth 2.1 draft for direction.
- **"OAuth 2.0 for Browser-Based Apps" is a draft.** Treat BFF and Token-Mediating Backend patterns as best practice rather than RFC-level requirements; the spec is still evolving and certain SPA refresh-token guidance has been debated by reviewers (e.g., the Spring Authorization Server team's note that "there are no plans to implement refresh tokens for Public Clients").
- **Front-channel logout and OIDC Session Management 1.0 depend on third-party cookies** that Safari (since 2020) and Firefox already block by default. Although Google **cancelled** its Chrome third-party-cookie deprecation plan on 22 April 2025 (Privacy Sandbox blog: "Instead of deprecating third-party cookies, we would introduce a new experience in Chrome that lets people make an informed choice"), planning for CHIPS/Partitioned cookies or migrating to **back-channel logout** is still the right call.
- **`node-oidc-provider` is Node-only**. If your OP must run on Workers/Deno/Bun, you will need to write your own server using `jose` and the metadata/endpoint specs directly. Filip Skokan's `oauth4webapi` covers RP-side cross-runtime; there is no equivalent OP-side cross-runtime library yet.
- **"Standard" claims (`email`, `name`, etc.) are not always present.** Many enterprise OPs return only `sub` plus a few custom claims. Code defensively; never key user accounts on anything but `(iss, sub)`.
- **RFC 9700 is normatively published (January 2025)** but several OPs in production still pre-date its more recent guidance (`iss` parameter, sender-constraining tokens). Feature-detect via metadata; do not assume.
- **Duende IdentityServer's choice to default to reusable (non-rotating) refresh tokens for confidential clients** (their April 2024 blog) is one defensible reading of RFC 9700; it does not contradict the spec, which mandates rotation specifically for public clients. Make the choice configurable.
- **CVE history for `jsonwebtoken`** (CVE-2022-23541, CVE-2022-23540) is the strongest single argument for using `panva/jose` instead; even newer versions are fine but the API still requires careful configuration, while `panva/jose` is safe by default.