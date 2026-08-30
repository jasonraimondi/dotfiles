---
name: kagi
description: "Search the web through Kagi and pull pages down as clean markdown. Use for programming, library, API and documentation questions — an error message, release notes, whether behavior changed in some version — in place of WebSearch and WebFetch. Needs $KAGI_API_KEY."
---

# Kagi

Kagi's Search API returns ad-free, re-ranked results and honors the account's own ranking settings, which is worth the most on technical queries — the ones WebSearch buries under content farms and scraped-Stack-Overflow mirrors. Reach for it on programming questions; leave general web search to WebSearch.

Each call is billed to the user's Kagi account, so make the query count rather than firing a spread of variations.

If `$KAGI_API_KEY` is unset, say so in one line and fall back to WebSearch. Getting a key is a manual step for the user at https://kagi.com/api/keys.

## Search

```bash
curl -s https://kagi.com/api/v1/search \
  -H "Authorization: Bearer $KAGI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg q 'QUERY' '{query: $q, limit: 10}')" \
| jq -r '.data.search[]? | "\(.title)\n\(.url)\n\(.snippet // "")\n"'
```

Build the body with `jq -n --arg` rather than hand-written JSON — queries carry apostrophes and quotes that break a literal `-d '{...}'`.

The raw response is large. Always pipe through `jq` to trim results down to title, URL and snippet before reading them.

### Body options

| Field | Effect |
|---|---|
| `limit` | Cap on results returned, 1–1024. Caps the response, not the search — cost is the same. |
| `page` | Pagination, 1–10. |
| `workflow` | `search` (default), `images`, `videos`, `news`, `podcasts`. |
| `filters` | `{region, after, before}` — ISO-3166-1 alpha-2 country code, and `YYYY-MM-DD` publish/update bounds. |
| `lens` | `{sites_included, sites_excluded, keywords_included, keywords_excluded, file_type}` — arrays of domains/keywords. Overrides any `site:` operator in the query. |
| `lens_id` | A saved lens from https://kagi.com/settings/lenses, by ID. |
| `timeout` | Seconds to spend gathering, 0.5–4. Lower is faster and thinner. |
| `extract` | `{count, timeout}` — fetch the top `count` results (max 10) and replace each `snippet` with the page's full markdown. Billed as Extract on top of the search. |

Reach for `extract` when the answer needs page bodies rather than snippets; it collapses a search plus several fetches into one round trip.

### Result buckets

`data` is keyed by result type, and a plain search fills several at once. `.data.search[]` is the web results; the rest are worth widening the `jq` to when `search` comes back thin or the query is a question:

`direct_answer` (math, unit conversions), `infobox`, `related_search`, `adjacent_question` (question text sits in `.props.question`), `interesting_finds` (Kagi's small-web index), `interesting_news`, `code`, `listicle`, `web_archive`.

Non-`search` workflows land in their own bucket: `.data.news`, `.data.image`, `.data.video`, `.data.podcast`.

Every item is `{url, title, snippet?, time?, image?, props?}`.

## Tech searches

Three knobs carry most of the value on technical queries:

- **`filters.after`** — pin to a date when the answer turns over with versions. A question about a library's current API is actively harmed by results from three majors ago, and Kagi will happily rank a well-linked 2019 blog post above the current docs. Set it to roughly when the version you care about shipped.
- **`lens.sites_included`** — pin to the source of truth once you know it (`["docs.python.org"]`, `["github.com"]`, `["doc.rust-lang.org"]`). Beats a `site:` operator in the query, which the lens overrides anyway.
- **`extract`** — API reference and changelog pages are the case where snippets are useless and the page body is the whole answer. Extracting the top 2–3 results beats searching and then fetching them one at a time.

An error message is best searched verbatim, with the parts unique to the run — paths, hex addresses, PIDs — stripped out.

Kagi also fills `.data.code` with results pointing at repositories and code resources; widen the `jq` to it when hunting for an implementation rather than prose.

Kagi's built-in **Programming** lens (official language sites and forums) is worth applying via `lens_id`, but Kagi publishes no identifier strings for its built-in lenses. To use it, the user has to open https://kagi.com/settings/lenses, make it shareable, and read the ID off its URL. Ask for it rather than guessing an identifier.

## Extract

Up to 10 URLs per call, returned as markdown:

```bash
curl -s https://kagi.com/api/v1/extract \
  -H "Authorization: Bearer $KAGI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"pages":[{"url":"https://example.com/a"},{"url":"https://example.com/b"}]}' \
| jq -r '.data[] | "## \(.url)\n\n\(.markdown // .error)\n"'
```

Per-page failures come back as `.error` on that page's entry with the rest of the batch intact, so check for it rather than assuming every page returned markdown.

## Errors

Failures return `data: null` and an `errors` array of `{code, message, url}`, where `code` is namespaced (`general.invalid_token`, `extract.invalid_url`). A bad or missing key is `general.invalid_token` and arrives as HTTP 400, not 401 — report it and fall back to WebSearch rather than retrying.
