# Publicar páginas HTTPS (GitHub Pages)

As páginas estão em `/docs`. URLs esperadas:

- https://berglimma.github.io/CheckApp/privacy.html
- https://berglimma.github.io/CheckApp/support.html
- https://berglimma.github.io/CheckApp/terms.html

## Ativar no GitHub

1. Push da branch `main` com a pasta `docs/`
2. Repo → **Settings → Pages**
3. Source: **Deploy from a branch**
4. Branch: `main` / folder: `/docs`
5. Aguarde 1–2 minutos e teste as URLs

Ou via CLI (já autenticado):

```bash
gh api repos/berglimma/CheckApp/pages -X POST -f build_type=legacy -f source[branch]=main -f source[path]=/docs
```
