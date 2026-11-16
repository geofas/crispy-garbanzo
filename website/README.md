# Nudgy Timer website

The marketing site for https://nudgytimer.app: a pre-launch page with a waitlist, plus the privacy and support pages the App Store asks for. Static HTML and CSS, no build step.

## Layout

- `public/` — the site. `index.html`, `privacy.html`, `support.html`, `404.html`, styles, script, icons, `robots.txt`, `sitemap.xml`, and `_headers` (security headers for Cloudflare Pages).
- `functions/api/waitlist.js` — Cloudflare Pages Function behind the waitlist form. It validates the address and stores it in Supabase.
- `supabase/waitlist.sql` — creates the waitlist table and the `join_waitlist()` function. Run once in the Supabase project.
- `tools/` — local dev server, tests, and the source of the social preview image.

## Cloudflare Pages settings

| Setting | Value |
|---|---|
| Production branch | `main` |
| Root directory | `website` |
| Build command | (none) |
| Build output directory | `public` |
| Variable `SUPABASE_URL` | `https://<project-ref>.supabase.co` |
| Variable `SUPABASE_KEY` | the project's publishable (anon) key |

Then add `nudgytimer.app` under Custom domains, and turn on Web Analytics for the project.

The publishable key is enough: the table is closed to the API and the key can only call `join_waitlist()`, which adds one address.

## Run locally

```bash
node tools/dev-server.mjs
```

Without `SUPABASE_URL` and `SUPABASE_KEY` set, the form reports an error instead of storing anything.

## Tests

```bash
node --test tools/waitlist.test.mjs
```

## When the app is on the App Store

Replace the two waitlist forms in `public/index.html` with the App Store badge, add `<meta name="apple-itunes-app" content="app-id=...">` for the Smart App Banner, and add the price to the structured data.
