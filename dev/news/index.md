# Changelog

## kquarto.r (development version)

## kquarto.r 0.2.0

Cette version ajoute la construction d’un site pkgdown avec ses rapports
Quarto, le template INRAE et la mise en forme des tableaux.

- Nouveau :
  [`kable()`](https://kbosirany.github.io/kquarto.r/dev/reference/kable.md)
  met en forme un tableau pour un book : tableau stylé et défilant en
  HTML, tableau `booktabs` en LaTeX. Elle vient du package `kutils`.
- Nouveau : template `inrae` (charte graphique INRAE : couleurs,
  polices, logo, favicon, page de titre et bibliographie), utilisable
  avec `create_book(template = "inrae")`. Il remplace le package
  `kquarto.r.inrae`.
- Nouveau :
  [`build_site()`](https://kbosirany.github.io/kquarto.r/dev/reference/build_site.md)
  rend les books dans le dossier d’un site pkgdown, les ajoute à la
  barre de navigation puis construit le site.
- Nouveau :
  [`update_pkgdown_yml()`](https://kbosirany.github.io/kquarto.r/dev/reference/update_pkgdown_yml.md)
  ajoute les books à `_pkgdown.yml`, dans un seul menu `Reports` : un
  en-tête par langue (`English`, `Français`, d’après le suffixe
  `-en`/`-fr` du dossier) quand il y a plusieurs langues, sans en-tête
  sinon. Les composants `reports_en` et `reports_fr` sont supprimés.

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
