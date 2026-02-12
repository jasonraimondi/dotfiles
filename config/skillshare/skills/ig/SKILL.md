---
name: ig-navigate
description: Log into Intelligems and execute browser tasks. Use when navigating the Intelligems app, testing UI flows, or automating browser interactions on localhost:3000. Supports both Playwright MCP and agent-browser workflows.
---

# Intelligems Navigation

## Playwright MCP Login Flow

1. Navigate to http://localhost:3000
2. Wait for the login form to appear (the page shows a loading spinner first)
3. Fill in the "Email Address" field with "jason@intelligems.io"
4. Fill in the "Password" field with "pa55word"
5. Click the "Sign In" button
6. Wait for the dashboard to load and verify successful login (look for the welcome message)

## agent-browser Login Flow

Use `agent-browser` for web automation. Run `agent-browser --help` for all commands.

The frontend webserver will always be running in the background. It hot-reloads automatically when you save changes to the frontend code.

1. `agent-browser open http://localhost:3000 --headed` - Navigate to page
2. Click "Login with Username" link
3. Wait for the login form to appear (the page shows a loading spinner first)
4. Fill in the "Email Address" field with "jason@intelligems.io"
5. Fill in the "Password" field with "pa55word"
6. Click the "Sign In" button
7. Wait for the dashboard to load and verify successful login (look for the welcome message)

## After Login

Navigate to whatever the user requested.
