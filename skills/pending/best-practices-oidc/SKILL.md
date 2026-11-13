---
name: best-practices-oidc
description: 'Best practices for OpenID Connect (OIDC) and OAuth 2.0 — flow selection, token validation, endpoints, discovery, and security hardening. Use when building, integrating, or reviewing authentication code: OIDC/OAuth clients (RP), authorization servers (OP), an OIDC library, ID token / JWT validation, PKCE, refresh tokens, DPoP, or logout.'
---

# OIDC & OAuth 2.0 Best Practices

OIDC = OAuth 2.0 + identity. OAuth issues an **access token** (authorization). OIDC adds an **ID Token** (signed JWT proving authentication), UserInfo, Discovery, standard claims, and `nonce`. A request is OIDC **iff `scope` contains `openid`**.

## Non-negotiable rules

These hold for every task — apply them without being asked, and flag violations in reviews.

1. **Authorization Code + PKCE (S256) for every interactive client** — public and confidential alike. Never ship Implicit, never ROPC, never `code_challenge_method=plain`.
2. **Reject `alg:"none"` unconditionally. Pin allowed algorithms at the verifier** — never pass the token's own `alg` into verification (algorithm-confusion attack).
3. **Validate the ID Token** — `iss` (exact byte match), `aud` (contains `client_id`), `exp`, `iat`, `nonce`, and `at_hash`/`c_hash` when present. See `references/tokens.md` for the full ordered checklist.
4. **Never identify the user from the access token.** Identity is the ID Token (or UserInfo called *with* the access token). An access token only grants scopes.
5. **Exact `redirect_uri` matching** — no wildcards, no substring. Use `state` + `nonce` + the `iss` parameter (RFC 9207).
6. **Use Discovery** (`.well-known/openid-configuration`); never hardcode endpoints.
7. **In TypeScript, build on `panva/jose` + `panva/oauth4webapi`.** Never `jsonwebtoken` (CVE-2022-23540/23541), never hand-rolled JWT crypto.
8. **SPAs: never put tokens in `localStorage`.** Prefer a Backend-for-Frontend (BFF).

Authoritative source: **RFC 9700** (OAuth 2.0 Security BCP, Jan 2025). OAuth 2.1 is still a draft — cite it for direction, RFC 9700 for normative force.

## Workflow

1. **Classify the task** — relying party (client/RP), authorization server (OP), or library? Which area: flow, tokens, endpoints, security, deployment profile?
2. **Load the matching reference(s)** from the table below — read before writing or reviewing code.
3. **Apply the non-negotiable rules** above plus the loaded reference.
4. **Verify** against the checklist embedded in the relevant reference file.

## Reference lookup

| Topic | When to read | File |
|---|---|---|
| **Flows** | Choosing a grant, building auth/token requests, handling the callback, refresh tokens, device flow | [flows.md](references/flows.md) |
| **Tokens** | ID/access/refresh tokens, JWT/JOSE, signing, ID-token validation, `nonce`, `at_hash` | [tokens.md](references/tokens.md) |
| **Endpoints** | Authorization/token/UserInfo/JWKS, Discovery & metadata, scopes & claims, logout, PAR/JAR, OP duties | [endpoints.md](references/endpoints.md) |
| **Security** | PKCE, CSRF, mix-up, token leakage, DPoP/mTLS, SSRF, algorithm confusion, anti-patterns | [security.md](references/security.md) |
| **Library & profiles** | Building an OIDC library in TypeScript; native/mobile, SPA/BFF, FAPI, multi-tenant, step-up | [library.md](references/library.md) |
| **Specs & references** | RFC and OpenID spec index, implementation references | [resources.md](references/resources.md) |

## Common pitfalls

Access token used as identity · skipped signature verification · trusting the header `alg` · wildcard `redirect_uri` · missing `nonce`/`aud`/`iss` validation · tokens in `localStorage` · Implicit flow · refresh tokens without rotation · UserInfo called with the ID Token instead of the access token · JWKS cached forever (no `kid`-rotation handling) · hardcoded endpoints. Full list with fixes in [security.md](references/security.md).
