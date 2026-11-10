# kquarto.r

Site : <https://kbosirany.github.io/kquarto.r/> (version en
développement : <https://kbosirany.github.io/kquarto.r/dev/>)

Créer, modéliser (templates) et générer des rapports Quarto de type
*book*, dans un package R ou dans un projet de rédaction indépendant.

## Utilisation

``` r

library(kquarto.r)

# Créer deux rapports avec un _quarto.yml rempli, dans reports/ (argument
# path_reports ; les présentations vont dans presentations/)
create_book(
  c("rapport_technique", "note_synthese"),
  title = c(note_synthese = "Note de synthèse"),
  author = "Kevin Orlando",
  lang = "fr",
  chapters = c("Introduction", "Méthodes")
)
# -> reports/rapport_technique/chapitre_01_introduction.qmd,
#    chapitre_02_methodes.qmd

# Ajouter un chapitre : numéro suivant, ajouté au _quarto.yml
create_book_chapter("rapport_technique", "Résultats")
# -> chapitre_03_resultats.qmd ("chapter_03_..." si lang = "en")

# Générer un rapport (par défaut dans reports/rapport_technique/_book)
render_book("rapport_technique")

# ... ou ailleurs, chemin relatif au dossier du rapport
render_book("rapport_technique", output_dir = "../../docs/rapport_technique")

# Générer tous les books de reports/
render_book()
```

## Sortie PDF (Typst ou LaTeX)

Les templates produisent du HTML. Pour obtenir aussi un PDF, ajouter un
format avec `formats` :

``` r

# PDF avec Typst (fourni avec Quarto ; Chrome ou Chromium et webshot2
# seulement si le livre contient des widgets)
create_book("rapport", template = "inrae", author = "Kevin Orlando",
            formats = c("html", "typst"))
render_book("rapport", output_format = "typst")

# PDF avec LaTeX (nécessite une distribution LaTeX)
create_book("rapport", template = "inrae", formats = c("html", "pdf"))
render_book("rapport", output_format = "pdf")
```

|  | Typst (`"typst"`) | LaTeX (`"pdf"`) |
|----|----|----|
| Installation | aucune (inclus dans Quarto), sauf widgets (voir ci-dessous) | TinyTeX (`quarto install tinytex`) ou TeX Live |
| Auteur | obligatoire | facultatif |
| Style INRAE | couleur, logo, pied de page | couleurs, logo, pied de page |

`kquarto.r` ne dépend d’aucune distribution LaTeX : elle n’est utile que
si on demande le format `"pdf"`.

Les éléments interactifs doivent être pensés pour les deux formats :

- [`kable()`](https://kbosirany.github.io/kquarto.r/reference/kable.md)
  donne un tableau déroulant en HTML et le tableau complet dans le PDF ;
- les widgets (`leaflet`, `plotly`, `DT`…) sont remplacés dans le PDF
  par une capture d’écran de leur état initial, ce qui demande Chrome ou
  Chromium et le package `webshot2`
  ([`render_book()`](https://kbosirany.github.io/kquarto.r/reference/render_book.md)
  prévient avant le rendu s’ils manquent) ;
- un contenu propre à un format s’écrit avec
  `::: {.content-visible when-format="html"}` (ou `"typst"`, `"pdf"`).

## Site pkgdown

``` r

# Rendre les books de reports/ dans public/reports/, les ajouter à la
# barre de navigation (_pkgdown.yml) puis construire le site pkgdown
build_site()

# Seulement mettre à jour la barre de navigation
update_pkgdown_yml()

# Le HTML est toujours rendu ; d'autres formats s'ajoutent (seulement pour
# les livres et présentations qui les déclarent)
build_site(output_format = c("typst", "beamer"))
```

[`build_site()`](https://kbosirany.github.io/kquarto.r/reference/build_site.md)
donne `output_format` à
[`render_book()`](https://kbosirany.github.io/kquarto.r/reference/render_book.md)
et à
[`render_presentation()`](https://kbosirany.github.io/kquarto.r/reference/render_presentation.md),
jamais à pkgdown. Chaque format rejoue le code des chapitres : mettre
les calculs lents en cache
([`saveRDS()`](https://rdrr.io/r/base/readRDS.html)).

### Un job de CI par livre

Pour un projet hébergé sur GitLab (ce dépôt, lui, utilise GitHub
Actions) : pour rendre chaque livre et chaque présentation dans son
propre job (en parallèle, avec des logs séparés),
[`render_site_item()`](https://kbosirany.github.io/kquarto.r/reference/render_site_item.md)
rend un élément dans le dossier du site, et
[`update_gitlab_ci()`](https://kbosirany.github.io/kquarto.r/reference/update_gitlab_ci.md)
tient à jour la liste des éléments de la matrice du `.gitlab-ci.yml`
(ceux du dossier de travail et de `origin/main` et `origin/dev`) :

``` r

# dans un job de la matrice `render` (ITEM: reports/01_mon_livre)
render_site_item("reports/01_mon_livre")

# dans le job `pages`, une fois les rendus récupérés en artefacts : échoue
# si un livre ou une présentation manque dans le site
build_site(
  render_reports = FALSE, render_presentations = FALSE,
  check_rendered = TRUE
)

# après avoir ajouté ou retiré un livre
update_gitlab_ci(fetch = TRUE)
```

### Noms qui existent aussi ailleurs

[`build_site()`](https://kbosirany.github.io/kquarto.r/reference/build_site.md)
(pkgdown, devtools) et
[`kable()`](https://kbosirany.github.io/kquarto.r/reference/kable.md)
(knitr) existent dans d’autres packages. Avec les deux packages
attachés, le dernier chargé masque l’autre : écrire
[`kquarto.r::build_site()`](https://kbosirany.github.io/kquarto.r/reference/build_site.md)
et
[`kquarto.r::kable()`](https://kbosirany.github.io/kquarto.r/reference/kable.md).

## Présentations

Une présentation (reveal.js) est un dossier avec un seul fichier
`<nom>.qmd`, indépendant des books. Elle a ses propres templates, rangés
dans les mêmes dossiers que ceux des books : un `template.yml` y déclare
le `type` (`book` par défaut, ou `presentation`), et chaque fonction de
liste ne montre que son type.

``` r

create_presentation(
  "seminaire",
  title = "Mon séminaire",
  author = "Kevin Orlando",
  template = "inrae-presentation"
)
# -> seminaire/seminaire.qmd, charte et logo INRAE

render_presentation("seminaire")
# -> seminaire/seminaire.html (un seul fichier autonome)

list_presentations()
list_templates_presentation()

# PDF avec LaTeX (Beamer) en plus du HTML
create_presentation("seminaire", formats = c("revealjs", "beamer"))
render_presentation("seminaire", output_format = "beamer")

# Template par défaut, par exemple dans le .Rprofile
options(kquarto.r.presentation.template = "inrae-presentation")

# Dériver un template (autre logo, diapositives types...)
create_template_presentation("mon_unite", from = "inrae-presentation")
```

Dans un projet avec un site pkgdown, les présentations sont rangées dans
un dossier `presentations/` (comme les books dans `reports/`) :
[`build_site()`](https://kbosirany.github.io/kquarto.r/reference/build_site.md)
les rend dans `<dest>/presentations/<nom>/index.html` et le menu
`Presentations` de la barre de navigation les liste.

Le PDF d’une présentation passe par Beamer (LaTeX) : Quarto n’a pas de
diapositives Typst, et un export PDF de reveal.js demanderait un
navigateur (impression depuis Chrome avec `?print-pdf`).

Un template de présentation contient un `template.yml`
(`type: presentation`), un `slides.qmd` (en-tête YAML et diapositives)
et les fichiers dont il a besoin. Avec `shared: inrae` dans son
`template.yml`, il réutilise la charte du dossier `inst/shared/inrae/`
(couleurs, polices, logo) que partagent aussi les books : un template
enregistré avec
[`create_template_presentation()`](https://kbosirany.github.io/kquarto.r/reference/create_template_presentation.md)
en reçoit une copie et reste autonome.

## Templates

``` r

# Enregistrer un rapport déjà configuré comme template réutilisable
create_template_book("mon_template", from = "rapport_technique")
list_templates_book()

# L'utiliser dans un autre projet
create_book("nouveau_rapport", template = "mon_template")
```

Les templates utilisateur sont stockés dans
[`template_dir()`](https://kbosirany.github.io/kquarto.r/reference/template_dir.md)
(`tools::R_user_dir("kquarto.r", "data")`), modifiable via
`options(kquarto.r.template_dir = "...")`.

### Template INRAE

Le template `inrae` est livré avec le package : couleurs et polices de
la [charte graphique
INRAE](https://www.inrae.fr/charte-graphique-inrae), logo, favicon, page
de titre et bibliographie (`references.bib`).

``` r

create_book("rapport", template = "inrae", author = "Kevin Orlando")

# Ou comme template par défaut, par exemple dans le .Rprofile
options(kquarto.r.template = "inrae")

# Dériver un template pour une unité (autre logo, chapitres types...)
create_template_book("inrae_mon_unite", from = "inrae")
```

La même charte existe aussi en extension Quarto,
[kquarto.inrae](https://github.com/kbosirany/kquarto.inrae), utilisable
sans R et sans copie des fichiers de la charte dans chaque livre :

``` bash
quarto use template kbosirany/kquarto.inrae/exemples/livre
```

Elle a vocation à remplacer les templates `inrae` et
`inrae-presentation` de ce package.

Contenu du template (`inst/templates/inrae/`) :

- `_quarto.yml` : book HTML en français, page de titre (titre,
  sous-titre, auteurs, date), logo, favicon, pied de page, bibliographie
  ;
- `inrae.scss` : couleurs et polices de la charte (Raleway pour les
  titres, Avenir Next Pro ou Calibri pour le texte) ;
- `references.bib` : bibliographie, citée avec `[@cle]` ;
- `images/logo-inrae.png` et `images/favicon-inrae.png` : logo et sigle
  INRAE.

### Templates livrés par un autre package

Un package (par exemple une charte d’unité) peut livrer ses templates
dans `inst/templates/<nom>/` :

``` r

# Depuis la racine de ce package
create_template_book("charte", from = "inrae", dir = "inst/templates")

# Utilisation
create_book("rapport", template = "monpkg::charte")
list_templates_book(packages = "monpkg")
```

Pour en faire le template par défaut :
`options(kquarto.r.template = "monpkg::charte")`.
