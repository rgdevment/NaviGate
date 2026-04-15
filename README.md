# LinkUnbound

Browser picker for Windows. Every link you click — in Teams, Outlook, Slack, a PDF, wherever — gets intercepted by LinkUnbound. If there's a domain rule, the assigned browser opens silently. If not, a small picker appears near your cursor and lets you choose.

## What it does

- Registers itself as the default browser in Windows
- Intercepts every link click system-wide
- Shows a floating picker near your cursor to choose a browser
- Saves per-domain rules: "always open this domain in X"
- Resolves redirects and SafeLinks before matching rules
- Runs silently in the system tray
- Can start with Windows

## Requirements

- Windows 10 or 11
- At least two browsers installed

## Setup

1. Run `linkunbound.exe`
2. On first launch, LinkUnbound scans your installed browsers and registers itself
3. In the settings window, click **Set as default** — Windows Settings opens, select LinkUnbound
4. Done — every link now goes through LinkUnbound

## How it works

**Link click with a rule:** browser opens instantly, no UI shown.

**Link click without a rule:** a picker appears near your cursor. Pick a browser. Optionally check "Always open here" to save a rule for that subdomain.

**Settings (tray):** double-click the tray icon or right-click → Settings. Three tabs:

- **General** — default browser status, startup toggle, browser list, add custom, refresh
- **Rules** — all domain rules, change browser per rule, delete rules
- **About** — version, license, reset data, unregister

## Domain rules

Rules match hierarchically. A rule for `google.com` covers `mail.google.com`, `drive.google.com`, etc., unless a more specific subdomain rule exists. Rules are created from the picker ("Always open here") and managed in the Rules tab.

## Architecture

One exe, two modes:

- `linkunbound.exe` (no args) → settings + tray (resident process)
- `linkunbound.exe "https://..."` (link click) → sends URL via named pipe to resident, or operates standalone if no resident

The resident process listens on a named pipe. Second instances send the URL and exit immediately. A Windows mutex prevents duplicate resident processes.
