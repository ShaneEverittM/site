# shanemurphy.space

Personal portfolio and writing site for Shane Murphy. Built with [Zola](https://www.getzola.org/) and deployed to GitHub Pages.

## Stack

| Layer                 | Tool                                           |
|-----------------------|------------------------------------------------|
| Static site generator | [Zola](https://www.getzola.org/) 0.22.1 (Rust) |
| Templating            | Tera (Jinja2-like)                             |
| Styles                | Sass (compiled by Zola, no npm)                |
| Hosting               | GitHub Pages                                   |
| CI/CD                 | GitHub Actions                                 |
| Domain registrar      | Squarespace Domains                            |

No Node.js, no npm, no JavaScript build tooling.

## Local development

Install Zola via Homebrew:

```bash
brew install zola
```

Serve locally with live reload:

```bash
zola serve
```

The site is available at `http://127.0.0.1:1111`.

## Deployment

Pushes to `main` automatically trigger the GitHub Actions workflow at `.github/workflows/deploy.yml`, which builds the site with Zola and deploys the `public/` output to GitHub Pages.

### GitHub Pages settings

In the repository's **Settings → Pages**:

- **Source:** GitHub Actions
- **Custom domain:** `shanemurphy.space`
- **Enforce HTTPS:** enabled (once DNS has propagated)

## Custom domain DNS (Squarespace)

The domain `shanemurphy.space` is registered through Squarespace Domains. The following DNS records must be set in the Squarespace DNS panel:

### A records (root domain)

| Type | Host | Value             |
|------|------|-------------------|
| A    | `@`  | `185.199.108.153` |
| A    | `@`  | `185.199.109.153` |
| A    | `@`  | `185.199.110.153` |
| A    | `@`  | `185.199.111.153` |

### CNAME record (www subdomain)

| Type  | Host  | Value                     |
|-------|-------|---------------------------|
| CNAME | `www` | `shaneeverittm.github.io` |

> **Note:** Remove any default Squarespace A records before adding the GitHub Pages ones. DNS propagation can take up to 48 hours.

## Project structure

```
content/        # Markdown content (pages, work, writing)
sass/           # Sass stylesheets
  _palette.scss # Colour tokens
  main.scss     # All styles
static/         # Static assets and CNAME file
templates/      # Tera HTML templates
  base.html     # Site shell (nav, footer)
  index.html    # Homepage
  page.html     # Individual pages
  section.html  # Section index pages
zola.toml       # Site config, hero content, about facts, links
```
