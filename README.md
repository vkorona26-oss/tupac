# 2P — download site

Static marketing and download page for the 2P workspace. No framework, no build
step, no external requests: three files and five screenshots.

```
site/
  index.html     hero, features, gallery, download, requirements, FAQ
  styles.css     one page, one accent, responsive down to 360 px
  app.js         sticky nav, release links, anchor offset
  assets/        logo.svg + app screenshots
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

Then push and let the workflow publish Pages. Release assets should be named
exactly as the page expects:

- `2P-3.2.0-Setup.exe`
- `2P-3.2.0-portable.zip`

To create the repository and the release:

```bash
gh auth login
cd site
git init -b main
git add .
git commit -m "2P download site"
gh repo create 2p-executor/2p --public --source . --remote origin --push
gh release create v3.2.0 "../app/dist/2P-3.2.0-Setup.exe" "../app/dist/2P-3.2.0-portable.zip" \
  --title "2P 3.2.0" --notes "First public build."
```

If the owner in `REPO` differs from the account you authenticate with, change
`REPO` before pushing.
