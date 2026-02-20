---
name: navigate-intelligems
description: Log into Intelligems and execute browser tasks
model: opus
---

Use `agent-browser` for web automation. Run `agent-browser --help` for all commands.

The frontend webserver will always be running in the background.  It hot-reloads automatically when you save changes to the frontend code.

Core workflow:
1. `agent-browser open http://localhost:3000 --headed` - Navigate to page
2. Click "Login with Username" link
3. Wait for the login form to appear (the page shows a loading spinner first)
4. Fill in the "Email Address" field with "jason@intelligems.io"
5. Fill in the "Password" field with "[UPDATE]"
6. Click the "Sign In" button
7. Wait for the dashboard to load and verify successful login (look for the welcome message)

After logging in, navigate {{prompt}}
