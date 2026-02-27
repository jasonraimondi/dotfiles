# PRD Plan Format Reference

Supplementary patterns for writing PRD tasks. See SKILL.md for the full workflow, templates, and quality bar.

## Step-writing patterns

- Target-first: `Route /settings/security — require recent auth for password change`
- Behavior-first: `On success — redirect to /orgs and show success toast`
- Constraint-first: `404 for missing org or non-member`

Include critical edge behavior inline:
- expired/invalid tokens
- duplicate conflicts
- authz/authn failures
- degraded dependency behavior

## Description patterns

Preferred starts:
- `Build ...`
- `Implement ...`
- `Configure ...`
- `Create ...`
- `Define ...`
- `Write ...`
- `Handle ...`
- `Set up ...`
