# Lens: `security`

Identify exploitable vulnerabilities. Report only **HIGH-CONFIDENCE** findings — clear vulnerable patterns with attacker-controlled input.

## Scope discipline

- **Report on**: only the changed code in scope.
- **Research**: the entire codebase to build confidence — trace data flow, check sanitization, check framework protections, check config.

Do not report based on pattern matching alone. Investigate first, then report only what's confirmed exploitable.

## Reference materials

Detect context from file paths and imports, then load the relevant guides — they carry the patterns to flag and the framework mitigations that produce false positives. Paths below are relative to `../security/`.

| Code type | References |
|---|---|
| API endpoints, routes | `references/authorization.md`, `references/authentication.md`, `references/injection.md` |
| Frontend, templates | `references/xss.md`, `references/csrf.md` |
| File handling, uploads | `references/file-security.md` |
| Crypto, secrets, tokens | `references/cryptography.md`, `references/data-protection.md` |
| Deserialization | `references/deserialization.md` |
| External requests | `references/ssrf.md` |
| Business workflows | `references/business-logic.md` |
| GraphQL / REST design | `references/api-security.md` |
| Config, headers, CORS | `references/misconfiguration.md` |
| CI/CD, dependencies | `references/supply-chain.md` |
| Error handling | `references/error-handling.md` |
| Audit, logging | `references/logging.md` |
| Prototype pollution, LLM injection, WebSocket | `references/modern-threats.md` |

| Language | Guide |
|---|---|
| Python (Django, Flask, FastAPI) | `languages/python.md` |
| JS/TS (Node, Express, React, Vue, Next.js) | `languages/javascript.md` |

| Infra | Guide |
|---|---|
| Docker | `infrastructure/docker.md` |

## Confidence

| Level | Criteria | Action |
|---|---|---|
| **HIGH** | Vulnerable pattern + attacker-controlled input confirmed | **Report** with severity |
| **MEDIUM** | Vulnerable pattern, input source unclear | **Note** as "Needs verification" |
| **LOW** | Theoretical, best practice, defense-in-depth | **Do not report** — unless dispatched by `full`, which wants every level |

Dispatched by `full`, emit all findings (HIGH/MEDIUM/LOW) with `confidence` set; the verifier filters. Invoked directly, report HIGH only.

## Do not flag

- Test files (unless reviewing test security)
- Dead / commented code, doc strings
- Server-controlled values (Django settings, env vars, hardcoded constants) — not attacker-controlled
- Framework-mitigated patterns where escaping/parameterization is the default

## Severity

| Severity | Examples |
|---|---|
| **Critical** | RCE, SQL injection to data, auth bypass, hardcoded secrets |
| **High** | Stored XSS, SSRF to metadata, IDOR to sensitive data |
| **Medium** | Reflected XSS, CSRF on state-changing actions, path traversal |
| **Low** | Missing headers, verbose errors, weak algorithms in non-critical context |

**Always flag (Critical)**
```
eval(user_input)
exec(user_input)
pickle.loads(user_data)
yaml.load(user_data)              # not safe_load
unserialize($user_data)
deserialize(user_data)
shell=True + user_input
child_process.exec(user)
```

**Always flag (High)**
```
innerHTML = userInput              # DOM XSS
dangerouslySetInnerHTML={user}     # React XSS
v-html="userInput"                 # Vue XSS
f"SELECT * FROM x WHERE {user}"    # SQL injection
os.system(f"cmd {user_input}")     # Command injection
```

## Output

```
## Security Review: <File/Component Name>

### Summary
- **Findings**: X (Y Critical, Z High, ...)
- **Risk Level**: Critical/High/Medium/Low

### Findings

#### [VULN-001] <Vulnerability Type> (Severity)
- **Location**: `file.py:123`
- **Confidence**: High
- **Issue**: <what>
- **Impact**: <what an attacker could do>
- **Evidence**:
  ```python
  <vulnerable code snippet>
  ```
- **Fix**: <how to remediate>

### Needs Verification
- **Location**: `file.py:456`
- **Question**: <what needs to be verified>
```

If nothing found: "No high-confidence vulnerabilities identified."

Shared rules in `../SKILL.md` apply.
