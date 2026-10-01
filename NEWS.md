# kquarto.r (development version)

* Nouveau : `build_site()` rend les books dans le dossier d'un site
  pkgdown, les ajoute à la barre de navigation puis construit le site.
* Nouveau : `update_pkgdown_yml()` ajoute les books (menus `reports_fr`,
  `reports_en`, ...) à `_pkgdown.yml`.

# kquarto.r 0.1.1

* Correction du nom de l'auteur (Kevin Bosirany Orlando) et ajout de son
  ORCID.
* Les workflows GitHub Actions utilisent `actions/checkout@v5` (Node.js 24).

# kquarto.r 0.1.0

* Première version : `create_book()`, `create_book_chapter()`,
  `render_book()`, `list_books()` et gestion des templates
  (`create_template_book()`, `list_templates_book()`,
  `remove_template_book()`), y compris les templates livrés par d'autres
  packages (`template = "pkg::nom"`).
