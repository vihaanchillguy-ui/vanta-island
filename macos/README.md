# Vanta Island

Vanta Island is a macOS desktop companion prototype.

## Native macOS build

The native app source is in `macos/Sources/VantaIslandApp.swift`. It creates an always-on-top floating island, with an expandable music panel, Spotify desktop controls through AppleScript, battery status, and a system volume slider.

A GitHub Actions workflow builds an unsigned universal app (Apple silicon + Intel) and packages it as a DMG. Open **Actions → Build Vanta Island for macOS → Run workflow** to build it, then download the `Vanta-Island-macOS` artifact from the completed run.

## Important limitations

- The DMG is ad-hoc signed, not Developer ID notarized. macOS may show a security warning; do not bypass security prompts unless you trust the build and understand the risk.
- Spotify controls require the Spotify desktop app and macOS Automation permission.
- Apple Music control, real weather, calendar event access, system brightness, and reading other apps' notifications are not implemented yet.
- The web preview in the repository is separate from the native macOS app.

The build runs on GitHub-hosted macOS runners; availability and usage limits depend on GitHub's current plan and account settings.
