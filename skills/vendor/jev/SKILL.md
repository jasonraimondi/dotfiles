---
name: jev
description: "Ask TypeSafe's Jev model for typed judgments over text or JSON from the shell: a yes/no probability, a pick from fixed options, or a score on a rubric. Use to triage, label, or rank a batch of items, or to try out TypeSafe questions before building them into code. Needs $TYPESAFE_API_KEY."
disable-model-invocation: true
---

# Jev

Jev is a System One model: it takes a `state` and a map of typed questions and returns probabilities, never prose. It answers judgments, it does not reason or write. The value over judging things yourself is **calibration** and **volume**: hundreds of items labeled the same way, each with a probability you can threshold on.

Building Jev into application code is a different job; reach for the `typesafe:typesafe-ai` skill for that.

If `$TYPESAFE_API_KEY` is unset, say so in one line and stop. Claude Code snapshots the shell environment at session start, so a key exported mid-session needs a restart to show up.

## Request

```bash
jq -n --arg state 'STATE TEXT' '{
  model: "jev-latest",
  state: $state,
  questions: {
    is_urgent:  {type: "noul",   instructions: "Does this message convey urgency?"},
    department: {type: "choice", instructions: "Which team should handle this message?",
                 criteria: {billing: "Payments, invoicing, refunds", technical: "Bugs, outages, integrations", other: "Anything else"}},
    frustration: {type: "score", instructions: "How frustrated is the customer?",
                  criteria: ["Calm", "Mildly annoyed", "Frustrated", "Very angry"]}
  }
}' \
| curl -sS https://api.typesafe.ai/v1/systemone \
    -H "Authorization: Bearer $TYPESAFE_API_KEY" \
    -H "Content-Type: application/json" \
    -d @- \
| jq '.answers'
```

Build the body with `jq -n --arg` (or `--argjson` for a JSON state) rather than a hand-written `-d '{...}'`: state text carries quotes that break a literal.

`state` is a string, object, or array. For records with several parts, pass an object and point questions at fields with backticked paths such as `` `ticket.messages[0].text` ``.

## Question types

| Type | Asks | `criteria` | Answer fields |
|---|---|---|---|
| `noul` | Is this true? | optional `{true, false}` descriptions | `noul`: probability of yes |
| `choice` | Which one? | required map of option → description (or `null`), max 255 | `choice`, `probabilities`, `confidence` |
| `score` | How much? | required ordered array of levels, 2–10 | `score` (can land between levels), `legend`, `probabilities`, `confidence` |

Question ids are for your code only and never reach the model, so the `instructions` must carry the whole meaning. One narrow judgment per question; split independent dimensions into separate questions rather than one compound one. Give a `choice` a no-match option whenever nothing may fit, or Jev is forced to pick a wrong one.

Score levels each describe a concrete situation, readable on their own ("Calm", not "1").

## Reading answers

- **Noul**: a probability, not an intensity. 0.5 means unsure, not "somewhat true". Gate on distance from 0.5.
- **Choice / Score `confidence`**: 1 when all probability sits on one outcome, 0 when spread evenly. Below ~0.5, report the item as uncertain rather than trusting the pick. Two acceptable options splitting the mass also lowers confidence; check `probabilities` before calling it wrong.

Report the probabilities alongside the label when relaying results to the user; that number is why Jev was used.

## Batching

All questions in one request run in parallel against one `state` and cannot see one another's answers, so ask every question about an item in a single request. Items need one request each:

```bash
jq -c '.[]' items.json | while read -r item; do
  jq -n --argjson state "$item" '{model: "jev-latest", state: $state, questions: {...}}' \
  | curl -sS https://api.typesafe.ai/v1/systemone \
      -H "Authorization: Bearer $TYPESAFE_API_KEY" -H "Content-Type: application/json" -d @- \
  | jq -c --argjson item "$item" '{item: $item, answers: .answers}'
done
```

Limits: 64k tokens per request (state plus all questions), 32k for state plus the longest question. Billing is per input token, so a long state asked many questions once is cheaper than the same state sent repeatedly.

## Errors

Standard HTTP codes with a JSON body. `401` is a bad or missing key: report it, don't retry. `422` names the malformed field in the body. `429` and `529` are rate limit and overload: back off and retry.

Pricing, models, and the full primitive guides live at https://docs.typesafe.ai/llms.txt (append `.md` to any page path for markdown).
