# Stakeholder update

Readers are product, CS and leadership. They know the product and its customers, and not the code. Each line answers "what can someone do now that they couldn't before, and is it live?"

## Shape

- First line: `*End-of-day update, <Weekday> <Mon D>*`, the day taken from `date`.
- One `*bold*` heading per workstream, named for the outcome in product words: "Customers can export invoices in bulk", not the ticket title. Mark the main one `(main focus)`.
- Under each heading, one to five `•` bullets, each a full plain sentence. Order: what works now, what is left or being made safe, then whether it reaches customers yet.
- Small items share one `*Other*` heading, a bullet each.
- Close with `*Next*`: `*Next week*` on a Friday, `*Tomorrow*` otherwise. One or two bullets.
- A decision Jason owes or a blocker is a plain sentence under its workstream ("It's ready to plan once I sign off").

## Translate

Every technical fact becomes its effect on a customer, a teammate or the launch:

- Name features by what they let someone do: "schedule the export to run every month, and cancel it afterward".
- Name a risk by when it matters: "three safety gaps I'll fix before any real account is touched".
- Say plainly whether anything is live, switched off in production, or still on dev.
- Report review and testing by verdict: "an independent review found no serious problems".
- Teammates appear by first name.

Leave the post free of PR and ticket numbers, branch and file names, flags, line or reviewer counts, and links; stakeholders read the update, not the code.

## Sample

```
*End-of-day update, Fri Nov 13*

*Customers can export invoices in bulk (main focus)*
• Most of the feature is now built. A customer can pick a date range, preview the export and download it. Once an admin approves, the export can be scheduled to run every month, and a scheduled run can be cancelled afterward.
• Old export files now get cleaned up automatically, so accounts don't run out of storage.
• An independent review of all of it found no serious problems. It did find a handful of safety gaps, and I'll fix three of them before any real account is touched.
• Nothing has touched a real account yet. Everything stays switched off in production, and the next step is a test run in our dev environment.

*Sending exports to a customer's own storage*
• The design is done: for customers who keep their records in their own storage, the export would land there for their team to review instead of being emailed directly.
• This isn't needed for launch. It's ready to plan once I sign off.

*Other*
• Gave feedback on the plan for the new onboarding checklist, mostly about which steps to cut.

*Next week*
• Fix the three safety gaps, then test invoice export end to end in dev.
```
