# Repository Instructions

## Project

- This repository is al-folio, an academic website theme built with Jekyll, Liquid, Markdown, Sass, and JavaScript.
- Site configuration lives in `_config.yml`; page content is mainly in `_pages/`, posts in `_posts/`, announcements in `_news/`, and project content in `_projects/`.
- Shared Liquid includes and layouts live in `_includes/` and `_layouts/`; styles live in `_sass/` and `assets/`.
- Preserve existing site content and configuration when making theme-level changes. Avoid editing generated output such as `_site/`.

## Conventions

- Follow the existing patterns in the nearest related Liquid template, Sass file, or content file. Keep changes focused and preserve public configuration keys and front matter unless the task requires otherwise.
- Format supported files with Prettier, including Liquid via `@shopify/prettier-plugin-liquid`. The repository uses a 150-character print width and ES5 trailing commas.
- Do not add dependencies unless the requested change needs them; JavaScript development dependencies are managed through npm, and site dependencies through Bundler.

## Validation

- Run `npx prettier . --check` for formatting changes; use `npx prettier <path> --check` for a narrower check.
- Run `bundle exec jekyll build` to validate the generated site. For local preview, use `bundle exec jekyll serve` and open `http://localhost:4000`.
- The Jekyll commands require dependencies from `Gemfile`; the build may also require Jupyter as described in `INSTALL.md`.
- For a running site with Docker, follow `INSTALL.md` and use `docker compose up`.