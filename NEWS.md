# kquarto.r (development version)

* `render_book()`, `render_presentation()` et `build_site()` ont un argument
  `workers` (défaut : option `kquarto.r.workers`, sinon `1`) pour rendre
  plusieurs livres ou présentations en même temps, chacun dans une session R
  en arrière-plan (callr, sur tous les OS). La sortie de Quarto de chaque
  rendu va dans un fichier de log, affiché en cas d'échec ; tous les rendus
  vont au bout et l'erreur liste ceux qui ont échoué. `build_site()` met les
  livres et les présentations dans la même file. Nouvelle dépendance :
  callr (déjà installé avec quarto, via processx).
* kableExtra passe des Imports aux Suggests : il n'est plus installé avec
  kquarto.r. `kable()` en a toujours besoin pour la sortie HTML et donne une
  erreur claire sans lui : l'ajouter aux dépendances des projets dont les
  livres appellent `kable()`. kquarto.r installe ainsi 15 paquets de moins.
* `build_site(render_reports = FALSE, render_presentations = FALSE)` met
  quand même à jour la barre de navigation, avec les livres et les
  présentations rendus ailleurs (par exemple par d'autres jobs de CI). Il
  initialise aussi le site pkgdown (`pkgdown::init_site()`), sans quoi pkgdown
  refuse d'écrire dans le dossier déjà rempli par ces rendus.
* `build_site()` a un argument `render_presentations` : `render_reports`
  ne concerne plus que les livres et `render_presentations` les
  présentations, pour n'en rendre qu'une partie. La barre de navigation liste
  toujours tous les livres et présentations trouvés, ceux qui ne sont pas
  rendus gardant leur sortie précédente. Avant, `render_reports = FALSE`
  désactivait aussi les présentations.
* Arguments renommés, nom générique puis qualificatif, comme `dirname_reports` :
  `path_reports` (dossier des livres, défaut `"reports"`) et
  `path_presentations` (dossier des présentations, défaut `"presentations"`)
  remplacent `path` ; `dirname_presentations` remplace `name` et
  `presentations` ; dans `build_site()` et `update_pkgdown_yml()`,
  `path_site` remplace `dest`, `subdir_reports` et `subdir_presentations`
  remplacent `site_subdir`, `presentations_subdir` et
  `presentations_site_subdir`. Les anciens noms restent acceptés, avec un
  avertissement. Les défauts passent de `"."` à `"reports"` et
  `"presentations"`.
* `build_site(path_site = )` donne aussi ce dossier à pkgdown (`override:
  destination`) et rend les livres et les présentations dans le dossier où
  pkgdown écrit le site, `<path_site>/dev` pour une version de
  développement. Avant, pkgdown écrivait dans la `destination` de
  `_pkgdown.yml`, ce qui laissait un site sans ses pages pkgdown quand `dest`
  était différent.
* `create_book()` ajoute le dossier des livres (`reports/`) au
  `.Rbuildignore` du package qui le contient.

* Nouveau : `add_pdf_download()` ajoute à des books existants un format PDF
  (Typst par défaut) et une icône « Download PDF » dans le volet gauche de la
  version HTML (`book: downloads: [pdf]`), avec le style d'un template
  optionnel. `create_book()` ajoute aussi cette icône quand `formats` combine
  le HTML et un PDF. Rendre avec `render_book(output_format = "all")` (#15).
* `render_presentation(output_format = "pptx")` rend un PowerPoint, qui peut
  utiliser les masques d'un modèle (`pptx: reference-doc:` dans l'en-tête des
  diapositives) ; `output_dir` copie aussi le `.pptx`. Le template
  `inrae-presentation` désactive l'étirement automatique des graphiques de
  reveal.js (`auto-stretch: false`), qui les faisait déborder des masques.
* Le template `inrae-presentation` reprend les masques du modèle PowerPoint
  INRAE (4:3) : diapositive de titre avec le filigrane, le chevron et les
  logos République française et INRAE ; pages avec le motif et le logo en pied
  de page, le titre de la présentation, la ligne date / information / auteur
  et le numéro `p. N` ; pages intermédiaires (`# Section`) ; diapositive de fin
  sur fond vert (`{.fin-inrae}`). Les fichiers du masque sont dans
  `images/`. La sortie PDF Beamer est inchangée.
* Nouveau : les présentations vont sur le site pkgdown. `build_site()` rend
  chaque présentation de `presentations_path` (`"presentations"` par défaut)
  dans `<dest>/presentations/<nom>/` (`index.html`, et le PDF s'il y en a un)
  et `update_pkgdown_yml()` ajoute le menu `Presentations` à la barre de
  navigation, avec le `title` de chaque présentation. Un site peut avoir des
  présentations sans books, et inversement. `render_presentation()` a
  l'argument `output_dir` pour copier les fichiers rendus.
* Nouveau : présentations reveal.js avec `create_presentation()`,
  `render_presentation()` et `list_presentations()`, et leurs templates
  (`create_template_presentation()`, `list_templates_presentation()`,
  `remove_template_presentation()`). Templates livrés :
  `default-presentation` et `inrae-presentation`. `formats = "beamer"`
  ajoute une sortie PDF LaTeX (Beamer) ; pas de Typst, Quarto n'ayant pas
  de diapositives Typst.
* Les templates ont un type, déclaré dans un `template.yml` (`book` par
  défaut) : les listes de books et de présentations ne se mélangent pas.
  Un template peut réutiliser des fichiers partagés (`shared:`) ; le
  template `inrae` des books partage désormais sa charte (couleurs,
  polices, logo) avec `inrae-presentation`.
* Nouveau : `create_book(formats = )` ajoute un format PDF aux books :
  `"typst"` (fourni avec Quarto, auteur obligatoire) ou `"pdf"` (LaTeX, qui
  nécessite une distribution LaTeX comme TinyTeX). Le template `inrae` a
  son style pour chacun (couleur et logo, Quarto >= 1.9.17 pour Typst).
  Le PDF se génère avec `render_book(output_format = "typst")` ou
  `"pdf"`.
* `kable()` écrit désormais le tableau complet hors HTML (tableau Markdown,
  compatible Typst, ou `booktabs` en LaTeX) au lieu des premières lignes.

# kquarto.r 0.2.0

Cette version ajoute la construction d'un site pkgdown avec ses rapports
Quarto, le template INRAE et la mise en forme des tableaux.

* Nouveau : `kable()` met en forme un tableau pour un book : tableau stylé
  et défilant en HTML, tableau `booktabs` en LaTeX. Elle vient du package
  `kutils`.
* Nouveau : template `inrae` (charte graphique INRAE : couleurs, polices,
  logo, favicon, page de titre et bibliographie), utilisable avec
  `create_book(template = "inrae")`. Il remplace le package
  `kquarto.r.inrae`.
* Nouveau : `build_site()` rend les books dans le dossier d'un site
  pkgdown, les ajoute à la barre de navigation puis construit le site.
* Nouveau : `update_pkgdown_yml()` ajoute les books à `_pkgdown.yml`, dans
  un seul menu `Reports` : un en-tête par langue (`English`, `Français`,
  d'après le suffixe `-en`/`-fr` du dossier) quand il y a plusieurs
  langues, sans en-tête sinon. Les composants `reports_en` et `reports_fr`
  sont supprimés.

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
