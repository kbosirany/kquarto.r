# Changelog

## kquarto.r (development version)

- Nouveau :
  [`build_site()`](https://kbosirany.github.io/kquarto.r/dev/reference/build_site.md)
  rend les books dans le dossier d’un site pkgdown, les ajoute à la
  barre de navigation puis construit le site.
- Nouveau :
  [`update_pkgdown_yml()`](https://kbosirany.github.io/kquarto.r/dev/reference/update_pkgdown_yml.md)
  ajoute les books (menus `reports_fr`, `reports_en`, …) à
  `_pkgdown.yml`.

## kquarto.r 0.1.1

- Correction du nom de l’auteur (Kevin Bosirany Orlando) et ajout de son
  ORCID.
- Les workflows GitHub Actions utilisent `actions/checkout@v5` (Node.js
  24).

## kquarto.r 0.1.0

- Première version :
  [`create_book()`](https://kbosirany.github.io/kquarto.r/dev/reference/create_book.md),
  [`create_book_chapter()`](https://kbosirany.github.io/kquarto.r/dev/reference/create_book_chapter.md),
  [`render_book()`](https://kbosirany.github.io/kquarto.r/dev/reference/render_book.md),
  [`list_books()`](https://kbosirany.github.io/kquarto.r/dev/reference/list_books.md)
  et gestion des templates
  ([`create_template_book()`](https://kbosirany.github.io/kquarto.r/dev/reference/create_template_book.md),
  [`list_templates_book()`](https://kbosirany.github.io/kquarto.r/dev/reference/list_templates_book.md),
  [`remove_template_book()`](https://kbosirany.github.io/kquarto.r/dev/reference/remove_template_book.md)),
  y compris les templates livrés par d’autres packages
  (`template = "pkg::nom"`).
