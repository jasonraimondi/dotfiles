# Project-local pi resources

## Extension

- `extensions/ask-user-question.ts` — Claude-style `AskUserQuestion`
- `extensions/clean-plan-mode.ts` — strict read-only plan mode

Load extensions:

```bash
pi -e ai/pi/extensions/ask-user-question.ts
pi -e ai/pi/extensions/clean-plan-mode.ts
```

## Prompt template snippet

- `prompts/interview-with-ask-user-question.md`

Use directly:

```bash
pi --prompt-template ai/pi/prompts/interview-with-ask-user-question.md
```

Or copy into project prompt discovery path:

```bash
mkdir -p .pi/prompts
cp ai/pi/prompts/interview-with-ask-user-question.md .pi/prompts/
```

Then run `/interview-with-ask-user-question` inside pi.

## Skill snippet

- `skills/ask-user-question-first/SKILL.md`

Use directly:

```bash
pi --skill ai/pi/skills/ask-user-question-first
```

Or copy into project skill discovery path:

```bash
mkdir -p .pi/skills
cp -R ai/pi/skills/ask-user-question-first .pi/skills/
```

Then run `/skill:ask-user-question-first` inside pi.
