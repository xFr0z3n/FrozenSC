# FrozenSC Discord RPC

Discord Rich Presence for SoundCloud, as a second dylib next to NexaSC

It shows what you're playing on SoundCloud as your Discord status (song, artist, progress and
optionally the cover art) and adds a **Discord RPC** entry to the settings
(long-press on the home button and scroll down).

## Build

Actions → **Build FrozenSCDiscord.dylib** → Run workflow. You get a draft release with
`FrozenSCDiscord.dylib`. Add it to the app's dylibs next to FrozenSC's dylib and that's it:
it doesn't need CydiaSubstrate or ElleKit.

The draft release is only visible to you. If you add the secrets below, they are built into the
dylib, so don't publish it.

## Setup

In the app: FrozenSC settings → **Discord RPC**. Enter your Discord App ID and token, and
optionally your Nextcloud / WebDAV details for cover art. Tap ✓ to restart SoundCloud.

Or build them in with repository secrets (Settings → Secrets and variables → Actions):
`DISCORD_APP_ID`, `DISCORD_TOKEN`, `NEXTCLOUD_WEBDAV_URL`, `NEXTCLOUD_USER`, `NEXTCLOUD_PASS`,
`NEXTCLOUD_PUBLIC_URL`. Anything entered in the app is used instead of the matching secret.

Your Discord token logs into your account, keep it private. Discord doesn't officially support
using an account token like this, so use it at your own risk.
