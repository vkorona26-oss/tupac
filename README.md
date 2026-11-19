# Tupac — download site and protection manifest

Static marketing and download page for the Tupac workspace, plus the pack
manifest the app reads. No framework, no build step, no external requests.

```
site/
  index.html     hero, features, screens, updates, download, requirements, FAQ
  styles.css     one page, one accent, responsive down to 360 px
  app.js         sticky nav, release links, anchor offset
  assets/        logo.svg + app screenshots
  protection/
    manifest.json          what the newest pack is, per channel
    packs/<version>.json   signature table for one Roblox client build
  .github/workflows/pages.yml   GitHub Pages deploy on push to main
```

## Run locally

```bash
python -m http.server 8899
# http://127.0.0.1:8899
```

## Publish

The download buttons resolve to `https://github.com/<REPO>/releases/latest/download/…`.
Set the repository once in `app.js`:

```js
const REPO = 'owner/repo';
```

Then push and let the workflow publish Pages. Release assets must be named
exactly as the page expects:

- `Tupac-4.0.0-Setup.exe`
- `Tupac-4.0.0-portable.zip`

```bash
gh auth login
cd site
gh repo create <owner>/tupac --public --source . --remote origin --push
gh release create v4.0.0 ../app/dist/Tupac-4.0.0-Setup.exe ../app/dist/Tupac-4.0.0-portable.zip \
  --title "Tupac 4.0.0" --notes-file ../app/dist/release-notes.md
```

## Protection packs

A pack is the signature table for one Roblox client build. Regenerate it from the
loader's header whenever the table changes:

```bash
python scripts/make-pack.py --version 4.0.0 --build version-xxxxxxxx
```

That writes `protection/packs/<version>.json`, recomputes its SHA-256 and updates
`protection/manifest.json`. Commit both. The app fetches the manifest from
`https://raw.githubusercontent.com/<owner>/tupac/main/protection/manifest.json`,
verifies the pack against the hash, and stores it under
`%LOCALAPPDATA%\Tupac\protection\<version>\pack.json`.

Unresolved signatures stay as empty strings. The app reports the pack as carrying
no signatures and the loader refuses to inject — a wrong offset is worse than a
clear refusal.
