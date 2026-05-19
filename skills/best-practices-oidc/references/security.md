# Security

Authoritative source: **RFC 9700** — "Best Current Practice for OAuth 2.0 Security" (January 2025). OAuth 2.1 (still a draft) consolidates it and **removes** the Implicit grant, ROPC, bearer tokens in query parameters, and wildcard redirect-URI matching.

## PKCE everywhere, S256 only

- `code_verifier`: 43–128 chars, ≥256 bits of entropy from a CSPRNG.
- `code_challenge = BASE64URL(SHA-256(code_verifier))`; `code_challenge_method=S256`.
- **`plain` MUST NOT be used.** Clients MUST NOT downgrade to `plain` after trying `S256` — an error on `S256` means a faulty server or a MITM downgrade attempt.
- PKCE is mandatory for **every** authorization-code request (RFC 9700 §2.1.1 / OAuth 2.1), confidential clients included. It gives robust CSRF protection even against an attacker who can read the authorization response.

## `state` — CSRF and app-state

High-entropy, unpredictable, bound to the user-agent session (`__Host-state` cookie or server session). Keep `state` even with PKCE: it carries app return-target context, detects duplicate callbacks, and interoperates with ASes that do not advertise PKCE.

## `nonce` — ID Token replay

A different role from `state`. Bind to the user-agent session. Always include it in the auth request; always verify it in the ID Token.

## `iss` parameter (RFC 9207) — mix-up defense

When the AS includes `iss` in the authorization response, the client MUST compare it to the expected issuer; on mismatch, **reject the response**. Advertised by `authorization_response_iss_parameter_supported`; required by FAPI 2.0. Mitigates the mix-up attack against multi-AS clients.

## Exact `redirect_uri` matching

Exact string match (RFC 9700 §4.1 / OAuth 2.1). No wildcards, no path tricks, no open redirector at the redirect URI. Loopback `http://127.0.0.1:<dynamic port>` (or `[::1]`) is the only `http` exception (RFC 8252).

## Authorization-code injection

Use all three together: PKCE binds the code to the original verifier, `nonce` binds the ID Token, the `iss` parameter rejects cross-AS responses.

## Token leakage

Never put tokens in URLs (RFC 6750 §2.3 discourages; OAuth 2.1 forbids) — use the `Authorization` header or the body. Authorization codes are short-lived (1–10 min) and single-use; the AS MUST reject reuse.

## Sender-constrained tokens — DPoP & mTLS

- **DPoP** (RFC 9449): the client holds a per-instance key pair. Each request carries a `DPoP` header — a JWT signed by the private key with `htm` (method), `htu` (URL, no fragment), `iat`, `jti`, and the JWK in the JWS header. The AS binds the access token via `cnf.jkt` (JWK thumbprint); the RS checks the proof matches. The AS may require a fresh server-supplied nonce via `WWW-Authenticate: DPoP error="use_dpop_nonce"`. Works for public and confidential clients.
- **mTLS** (RFC 8705): the token is bound to the client's X.509 cert; `cnf.x5t#S256` carries the cert thumbprint. Needs TLS terminating where the client cert is visible to the RS.

Sender-constraining caps the blast radius of XSS or token theft — strongly preferred for new deployments, and required for any public client requesting `offline_access`.

## Resource indicators (RFC 8707) & `aud` confusion

The client sends `resource=https://api.example.com`; the AS issues an access token with that `aud`. Multi-`aud` tokens are dangerous — prefer one resource per token.

## SSRF via JWKS / `request_uri` / `logo_uri` / `sector_identifier_uri`

These make the AS issue outbound HTTP requests. Treat every URL as untrusted: `https`-only scheme allow-list; resolve DNS and reject internal/loopback/link-local ranges (`127.0.0.0/8`, `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `169.254.0.0/16`, `::1`, `fc00::/7`, `fe80::/10`); strict timeouts and response-size caps. For `request_uri`, prefer `require_request_uri_registration=true` — PAR removes the need for the AS to fetch at all.

## Subdomain takeover

A registered `https://foo.example.com/callback` whose subdomain is taken over (orphan CNAME) hands the attacker the redirect. Audit registered redirect URIs; never register on shared or dangling subdomains.

## Cookie security

- RP/BFF session cookie: `Secure; HttpOnly; SameSite=Lax` (or `Strict`); `__Host-` prefix (no `Domain`, `Path=/`, `Secure`).
- OP session cookies used in cross-site iframes: `Partitioned` (CHIPS).

## Algorithm confusion & `alg:"none"`

Pin algorithms at the verifier; bind key type to algorithm; never accept `alg:"none"`; never trust the token's header `alg`. The npm `jsonwebtoken` library's history — CVE-2022-23541 (algorithm confusion: HS256 verification with an RSA public key) and CVE-2022-23540 (signature bypass when `alg` is omitted and the secret is falsy), both ≤ v8.5.1, fixed in v9.0.0 — is why this matters. Use `panva/jose`, which rejects `alg:"none"` by default.

---

## Anti-patterns — flag every one of these in a review

- Using the **access token** to identify the user — identity is the ID Token (or UserInfo called with the access token).
- Skipping signature verification "because we trust the issuer".
- **Trusting the `alg` from the token header.** Pin allowed algs at the verifier.
- `HS256` with a secret shared across many clients.
- Wildcard or substring `redirect_uri` matching.
- Not validating `nonce`. Not validating `aud`. Forgetting to validate `iss`.
- Storing tokens in `localStorage` in SPAs.
- Implementing the Implicit flow today.
- Long-lived refresh tokens with no rotation.
- A JWT library that doesn't reject `alg:"none"` by default.
- Sending the ID Token to APIs as the access token (wrong `aud`, wrong `typ`).
- Calling UserInfo with the ID Token instead of the access token.
- Caching JWKS forever; not handling `kid` rotation (refetch once on a miss).
- Hardcoding endpoints instead of using Discovery.
- Trusting redirect parameters without `state` and `iss` validation.
