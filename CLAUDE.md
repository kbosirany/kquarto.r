# kquarto.r — contexte du projet

Ce fichier est lu automatiquement par Claude Code à l’ouverture du
dépôt. Il résume ce que le code et l’historique git ne disent pas : le
pourquoi, les décisions et ce qui reste ouvert. Le tenir à jour quand
une décision change.

## But

Package R de Kevin Bosirany Orlando pour gérer les rapports (books
Quarto) et les présentations de ses projets professionnels (INRAE, UMR
G-EAU), et les publier dans le site pkgdown du projet.

## Dépôts liés

- `kbosirany/kquarto.inrae` : la charte INRAE en extension Quarto.
- `kpkg.r` : modèle de package et de CI (les variables `KPKG_*` de
  `dev/build_site.R` en viennent).
- `kutils` : origine de
  [`kable()`](https://kbosirany.github.io/kquarto.r/reference/kable.md).

Nomenclature : les dépôts personnels portent le préfixe `k` et vivent
sur <https://github.com/kbosirany>, pas sur la forge INRAE.

## Historique

- Créé ici sous le nom `kquarto.r` (0.1.0 à 0.2.0).
- Copié le 2026-11-03 sur forge.inrae.fr sous le nom `quarto.r`, où la
  0.3.0 a été développée (présentations, rendu par élément, CI GitLab).
- Ramené ici le 2026-11-09 (PR \#32). La forge n’était pas le bon
  endroit ; son dépôt est à supprimer et ne doit plus être modifié.

## Décisions

- **Licence MIT**, pas l’AGPL de la copie de la forge.
- **CI GitHub Actions** (`.github/workflows`). `.gitlab-ci.yml` n’a pas
  été repris.
- **[`update_gitlab_ci()`](https://kbosirany.github.io/kquarto.r/reference/update_gitlab_ci.md)
  et
  [`render_site_item()`](https://kbosirany.github.io/kquarto.r/reference/render_site_item.md)
  restent** : ils servent aux projets hébergés sur GitLab qui utilisent
  ce package, pas à ce dépôt.
- **La charte INRAE passe par l’extension `kquarto.inrae`.** Les
  templates `inrae` et `inrae-presentation` de `inst/` sont encore là,
  en doublon.

## Analyse critique du 2026-11-09 (non appliquée)

Constat : environ la moitié du package refait ce que Quarto fait déjà.

- Création et templates
  ([`create_book()`](https://kbosirany.github.io/kquarto.r/reference/create_book.md),
  [`create_presentation()`](https://kbosirany.github.io/kquarto.r/reference/create_presentation.md),
  `create_template_*()`,
  [`add_pdf_download()`](https://kbosirany.github.io/kquarto.r/reference/add_pdf_download.md),
  `shared:`) : remplaçables par l’extension Quarto. Les templates sont
  copiés dans chaque livre, donc une mise à jour de la charte ne se
  propage pas.
- Rendu
  ([`render_book()`](https://kbosirany.github.io/kquarto.r/reference/render_book.md),
  [`render_presentation()`](https://kbosirany.github.io/kquarto.r/reference/render_presentation.md),
  `workers`) : surcouche de `quarto render`.
- Site pkgdown
  ([`build_site()`](https://kbosirany.github.io/kquarto.r/reference/build_site.md),
  [`update_pkgdown_yml()`](https://kbosirany.github.io/kquarto.r/reference/update_pkgdown_yml.md))
  : la partie sans équivalent, à garder.
- [`kable()`](https://kbosirany.github.io/kquarto.r/reference/kable.md)
  et
  [`source_report_setup()`](https://kbosirany.github.io/kquarto.r/reference/source_report_setup.md)
  : utilitaires d’exécution, hors sujet dans un package d’échafaudage.
- [`update_pkgdown_yml()`](https://kbosirany.github.io/kquarto.r/reference/update_pkgdown_yml.md)
  et
  [`create_book_chapter()`](https://kbosirany.github.io/kquarto.r/reference/create_book_chapter.md)
  réécrivent le YAML en entier et perdent les commentaires. Piste :
  passer le menu à pkgdown par `override` au lieu d’écrire dans
  `_pkgdown.yml` (non testé).

Rien de cela n’est décidé : aucune fonction n’a été retirée.

## Conventions

- Branches : travail sur une branche, PR vers `dev`, puis `dev` vers
  `main`. Le site de `main` est à la racine de GitHub Pages, celui de
  `dev` dans `/dev`.
- Commits en anglais, préfixés (`feat:`, `fix:`, `docs:`, `chore:`).
- Code, commentaires et documentation roxygen en anglais ; `README.md`
  et `NEWS.md` en français.
- Lignes de 80 caractères (`.lintr`).

## Vérifier un changement

Les tests demandent le package R `quarto` et le CLI Quarto. Sans eux, la
CI de la PR est la seule vérification.

``` r

devtools::test()
devtools::check()
```
