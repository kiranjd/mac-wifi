# MacWiFi Repo Notes

## Diagnostics

- Developer mode is enabled only when a `dev.txt` marker exists in one of these checked locations:
  - `/Users/jd/things/mac-wifi/dev.txt` when running the local repo app bundle
  - `~/Library/Application Support/MacWiFi/dev.txt` for installed/release runs
- When developer mode is enabled, logs are written to:
  - `~/Library/Logs/MacWiFi/app.log`
  - `~/Library/Logs/MacWiFi/analytics.log`
- `analytics.log` can be disabled without disabling developer mode by setting one of these in `dev.txt`:
  - `analytics=off`
  - `ga4_logs=off`

## Debugging

- Check the log files above first when diagnosing release or debug behavior.
- The app should only auto-open the popover for completed results after a user has opened it before and it later collapsed.

## UI Guardrails

- For MacWiFi settings and licensing UI, err on showing less. Prefer compact cards, a single obvious action, and the fewest elements needed to communicate state.

## Review Workflows

- Website changes:
  - After making changes that affect a website page, automatically open the corresponding page for review.
  - If that page is already open in a browser, focus the existing tab and refresh it instead of opening a duplicate tab.
  - Prefer showing the exact route that changed, not just the homepage.
  - When useful, verify both desktop and mobile presentation after refreshing the page.

- Mac app changes:
  - After making changes that affect the Mac app, automatically close the currently running MacWiFi app before launching a rebuilt version.
  - Build the app again before launch so the running app matches the latest code.
  - After a successful build, launch the updated app automatically for review.
  - If the build fails, do not relaunch the old app as if nothing happened; report the failure clearly instead.
