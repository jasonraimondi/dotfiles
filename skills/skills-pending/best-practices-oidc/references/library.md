# Building a Library & Deployment Profiles

## Substrate — what to build on

- **JWT/JOSE: `panva/jose`.** Cross-runtime, secure defaults; rejects `alg:"none"` by default; `createRemoteJWKSet(url)` has built-in caching + single-flight; supports algorithm allow-lists and `typ` checks (`at+jwt`).
- **Protocol: `panva/oauth4webapi`.** Low-level, function-based, framework-free, Web Crypto, ESM-first, **zero runtime dependencies**. The right engine for a new library.
- **`openid-client`** (panva) — higher-level `Client` class with auto-discovery; an excellent ergonomics reference.
- **OP side: `node-oidc-provider`** (panva) — study it; Node-only.
- **Never** `jsonwebtoken` (CVE history) or hand-rolled JWT crypto.

## Crypto — Web Crypto by default

`globalThis.crypto.subtle` is stable in Node ≥19, Deno, Bun, browsers, Cloudflare Workers, Vercel Edge. `node:crypto` is Node-only — gate it to optional legacy adapters only.

## Suggested module structure

```
src/
  core/
    protocol/  jwt/  pkce/  crypto/
    discovery/   // metadata fetch + cache + validate
    jwks/        // fetch, cache, single-flight, kid lookup
    validate/    // ID Token / access-token / logout-token validators
  rp/
    client.ts  storage.ts  http.ts  logout.ts
  op/          // OP recipes
  errors.ts  types.ts  index.ts
```

## Public API — function-first, tree-shakeable

Named exports: `discover`, `buildAuthorizationUrl`, `exchangeCode`, `validateIdToken`, `fetchUserInfo`, `refresh`, `buildLogoutUrl`. Optional higher-level `createClient(cfg)` factory.

`ClientConfig` carries: exact `issuer`, `clientId`, `redirectUri`, a discriminated `clientAuth` union (`none` | `client_secret_basic`/`post` | `client_secret_jwt` | `private_key_jwt` | `tls_client_auth`), `clockSkewSeconds` (default 30), and injected `fetch` / `clock` / `storage` / `logger`.

## Design rules

- **Strong types**: branded opaque token strings; a verbatim `OAuthErrorCode` union (standard + OIDC §3.1.2.6 + DPoP codes); a typed `IdTokenClaims` with an index signature for custom claims; a discriminated `OidcError` union (`protocol` | `validation` | `network` | `http`).
- **Pluggable storage** — a `StateStore` with `put(key, value, ttl)` and consume-once `take(key)`, holding `{ state, nonce, codeVerifier, redirectUri, createdAt }`. Ship in-memory + cookie adapters; document Redis.
- **Pluggable HTTP & clock** — inject `fetch` and `clock(): number` (epoch seconds) so expiry logic is testable.
- **Logging/redaction** — never log `code`, `access_token`, `refresh_token`, `id_token`, `code_verifier`, `client_secret`, or DPoP keys; strip these params when logging URLs.
- **Concurrency** — JWKS single-flight per issuer; refresh serialization (mutex) per refresh-token family so rotation + reuse detection doesn't burn the family on a race.
- **String comparison** — `iss`/`aud` exact byte compare (no normalization); secrets compared timing-safe.
- **URL building** — use `URL` + `URLSearchParams`, never string concatenation. Double-URL-encoding is the top cause of `redirect_uri_mismatch`; `redirect_uri` must be byte-identical to the registered value.
- **Packaging** — pure ESM, `"sideEffects": false`, target ES2022+. Core depends on **only `jose`**.
- **Don't expose unsafe knobs** — make PKCE+S256, `state`, `nonce`, `iss`, and exact `redirect_uri` matching non-optional. Don't ship Implicit or ROPC at all.
- **Testing** — run the OpenID Foundation Conformance Suite (RP and OP modes) in CI; table-driven tests covering every step of the §3.1.3.7 validator; property tests for PKCE; RFC test vectors; mocked deterministic JWKS.
- **Ship a threat model** — state what the library prevents (alg-confusion, code injection, replay, mix-up, CSRF) and what it does NOT (XSS in the app, CSP, cookie config, TLS, secrets management).

## Deployment profiles

### Native / mobile (RFC 8252 / BCP 212)

MUST use an **external user-agent** (system browser, Chrome Custom Tabs, `ASWebAuthenticationSession`) — never an embedded WebView. Redirect URI: claimed-https (App/Universal Links, preferred) · custom reverse-DNS scheme (`com.example.app:/oauth`) · loopback `http://127.0.0.1:<dynamic port>`. PKCE mandatory; public client (`token_endpoint_auth_method=none`). Reference: `AppAuth-*`.

### SPA / browser apps (OAuth 2.0 for Browser-Based Apps draft)

- **Preferred: Backend-for-Frontend (BFF)** — the BFF is the OAuth client; tokens never reach the browser; the browser holds an HttpOnly session cookie.
- Token-Mediating Backend is a weaker alternative — if the backend passes tokens to the browser, it is not a BFF.
- Pure SPA only if unavoidable: Authorization Code + PKCE, public client, **no refresh tokens** (or DPoP-bound, very short-lived). In-memory tokens + silent renewal via `prompt=none` iframe is degraded under third-party-cookie deprecation.
- **Never `localStorage`** (XSS-readable); `sessionStorage` is no better.

### FAPI profiles

- **FAPI 1.0 Advanced**: PAR + JAR, `id_token` as detached signature in Hybrid, mTLS or `private_key_jwt`, S256 PKCE; signing algs `PS256`/`ES256`.
- **FAPI 2.0 Security Profile**: `response_type=code` only (no Hybrid); PAR mandatory; sender-constrained tokens (mTLS or DPoP) — bearer not acceptable; client auth mTLS or `private_key_jwt`; `iss` parameter mandatory; for `private_key_jwt`, `aud` MUST be the AS issuer identifier string; refresh-token rotation prohibited for confidential clients with sender-constrained tokens; clock skew 0–10s future, reject beyond 60s.

### Multi-tenant

Each tenant has its own issuer URL and Discovery document. Treat `issuer` as **opaque** — never parse it. Tenant comparison is exact-string on the `iss` claim.

### Step-up authentication (RFC 9470)

The RS replies `WWW-Authenticate: Bearer error="insufficient_user_authentication"` with `acr_values` and `max_age`; the client repeats the auth request with those values.
