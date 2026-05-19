# Specs & Implementation References

## OpenID specs

- OpenID Connect Core 1.0 — https://openid.net/specs/openid-connect-core-1_0.html
- OpenID Connect Discovery 1.0 — https://openid.net/specs/openid-connect-discovery-1_0.html
- OpenID Connect Dynamic Client Registration 1.0 — https://openid.net/specs/openid-connect-registration-1_0.html
- OpenID Connect Session Management 1.0 — https://openid.net/specs/openid-connect-session-1_0.html
- OpenID Connect Front-Channel Logout 1.0 — https://openid.net/specs/openid-connect-frontchannel-1_0.html
- OpenID Connect Back-Channel Logout 1.0 — https://openid.net/specs/openid-connect-backchannel-1_0.html
- OpenID Connect RP-Initiated Logout 1.0 — https://openid.net/specs/openid-connect-rpinitiated-1_0.html
- FAPI 2.0 Security Profile — https://openid.net/specs/fapi-security-profile-2_0-final.html
- CIBA Core 1.0

## IETF RFCs

- RFC 6749 OAuth 2.0 · RFC 6750 Bearer Token Usage
- RFC 7009 Revocation · RFC 7515 JWS · RFC 7516 JWE · RFC 7517 JWK · RFC 7518 JWA · RFC 7519 JWT
- RFC 7521 Assertion Framework · RFC 7522 SAML Assertion · RFC 7523 JWT Assertion
- RFC 7591 Dynamic Registration · RFC 7592 Registration Management · RFC 7636 PKCE · RFC 7662 Introspection
- RFC 8252 OAuth for Native Apps (BCP 212) — https://www.rfc-editor.org/rfc/rfc8252.html
- RFC 8414 AS Metadata · RFC 8628 Device Grant · RFC 8693 Token Exchange
- RFC 8705 mTLS · RFC 8707 Resource Indicators
- RFC 9068 JWT Access Tokens — https://datatracker.ietf.org/doc/html/rfc9068
- RFC 9101 JAR · RFC 9126 PAR
- RFC 9207 Issuer Identification — https://www.rfc-editor.org/rfc/rfc9207.html
- RFC 9449 DPoP — https://datatracker.ietf.org/doc/html/rfc9449
- RFC 9470 Step-Up Authentication Challenge
- RFC 9700 OAuth 2.0 Security BCP — https://datatracker.ietf.org/doc/rfc9700/
- OAuth 2.0 for Browser-Based Apps (Internet-Draft) — https://datatracker.ietf.org/doc/html/draft-ietf-oauth-browser-based-apps
- OAuth 2.1 (Internet-Draft) — https://datatracker.ietf.org/doc/draft-ietf-oauth-v2-1/

## Implementation references

- `panva/oauth4webapi` — https://github.com/panva/oauth4webapi
- `panva/jose` — https://github.com/panva/jose
- `panva/node-oidc-provider` — https://github.com/panva/node-oidc-provider
- `panva/openid-client`
- OpenIddict (.NET), Spring Authorization Server (Java), Keycloak, AppAuth-JS/Android/iOS
- OpenID Foundation Certification — https://openid.net/certification/

## Vendor docs & assurance

- Auth0 — https://auth0.com/docs/authenticate/protocols/openid-connect-protocol
- Microsoft identity platform — https://learn.microsoft.com/en-us/entra/identity-platform/v2-protocols-oidc
- Google Identity · Okta developer · Curity guides · Pragmatic Web Security (Philippe De Ryck)
- NIST SP 800-63C (Federation)

## Caveats

- **OAuth 2.1 is a draft.** Cite RFC 9700 for normative force, OAuth 2.1 for direction.
- **"OAuth 2.0 for Browser-Based Apps" is a draft.** Treat BFF / Token-Mediating Backend as best practice, not RFC-level requirements.
- **Front-channel logout and Session Management 1.0 depend on third-party cookies** that Safari and Firefox block by default. Plan for CHIPS/`Partitioned` cookies or back-channel logout.
- **`node-oidc-provider` is Node-only.** No cross-runtime OP-side library exists yet; for Workers/Deno/Bun, build on `jose` + the specs directly.
- **Standard claims are not always present.** Many enterprise OPs return only `sub` plus custom claims. Key accounts on `(iss, sub)` only.
- **Many production OPs pre-date RFC 9700's newer guidance** (`iss` parameter, sender-constrained tokens). Feature-detect via metadata; do not assume.
