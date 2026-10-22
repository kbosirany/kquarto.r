# Prise en main de kquarto.r

`kquarto.r` gère des rapports Quarto de type *book*, que ce soit dans un
package R (les dossiers de rapport sont alors ajoutés à `.Rbuildignore`)
ou dans un projet de rédaction indépendant.

``` r

library(kquarto.r)

projet <- file.path(tempdir(), "mon_projet")
dir.create(projet)
```

## Créer des rapports

[`create_book()`](https://kbosirany.github.io/kquarto.r/dev/reference/create_book.md)
crée un dossier par rapport, copie les fichiers du template et écrit un
`_quarto.yml` rempli. Le titre vaut par défaut le nom du dossier ; un
vecteur nommé permet de ne changer que certains titres.

``` r

create_book(
  c("rapport_technique", "note_synthese"),
  path = projet,
  title = c(note_synthese = "Note de synthèse"),
  author = c("Kevin Orlando", "Camille Martin"),
  lang = "fr",
  chapters = c("Introduction", "Méthodes")
)
#> Book(s) created: rapport_technique, note_synthese

list.files(file.path(projet, "rapport_technique"))
#> [1] "_quarto.yml"                  "chapitre_01_introduction.qmd"
#> [3] "chapitre_02_methodes.qmd"     "index.qmd"
yml <- file.path(projet, "rapport_technique", "_quarto.yml")
cat(readLines(yml), sep = "\n")
#> project:
#>   type: book
#>   output-dir: _book
#> book:
#>   title: rapport_technique
#>   chapters:
#>   - index.qmd
#>   - chapitre_01_introduction.qmd
#>   - chapitre_02_methodes.qmd
#>   author:
#>   - Kevin Orlando
#>   - Camille Martin
#> lang: fr
#> format:
#>   html:
#>     theme: cosmo
#>     toc: true
#>     number-sections: true
```

Tout autre champ du `_quarto.yml` peut être passé par `...` :

``` r

create_book(
  "rapport",
  format = list(html = list(theme = "flatly", `code-fold` = TRUE))
)
```

## Ajouter des chapitres

Les chapitres sont numérotés après `index.qmd`, avec un préfixe qui suit
la langue du book (`chapitre` en français, `chapter` sinon).
[`create_book_chapter()`](https://kbosirany.github.io/kquarto.r/dev/reference/create_book_chapter.md)
prend le numéro suivant et met à jour `_quarto.yml` :

``` r

create_book_chapter("rapport_technique", "Résultats", path = projet)
#> Chapter created: rapport_technique/chapitre_03_resultats.qmd
list_books(projet)
#> [1] "note_synthese"     "rapport_technique"
yaml::read_yaml(yml)$book$chapters
#> [1] "index.qmd"                    "chapitre_01_introduction.qmd"
#> [3] "chapitre_02_methodes.qmd"     "chapitre_03_resultats.qmd"
```

## Générer les rapports

[`render_book()`](https://kbosirany.github.io/kquarto.r/dev/reference/render_book.md)
appelle
[`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html).
Par défaut, le rapport est généré dans `_book/` à l’intérieur de son
dossier ; `output_dir` est un chemin relatif au dossier du rapport.

``` r

render_book("rapport_technique")
render_book("rapport_technique", output_dir = "../docs/rapport_technique")
render_book() # tous les books du dossier courant
```

## Sortie PDF (Typst ou LaTeX)

Les templates produisent du HTML. L’argument `formats` ajoute un PDF :
`"typst"` (fourni avec Quarto, rien à installer, auteur obligatoire) ou
`"pdf"` (LaTeX, qui nécessite une distribution comme TinyTeX, installée
avec `quarto install tinytex`). `kquarto.r` ne dépend d’aucune
distribution LaTeX.

``` r

create_book("rapport", template = "inrae", author = "Kevin Orlando",
            formats = c("html", "typst", "pdf"))
render_book("rapport", output_format = "typst")
render_book("rapport", output_format = "pdf")
```

Dans le PDF,
[`kable()`](https://kbosirany.github.io/kquarto.r/dev/reference/kable.md)
écrit le tableau complet à la place du tableau déroulant, et les widgets
(`leaflet`, `plotly`…) sont remplacés par une capture d’écran (Chrome ou
Chromium et `webshot2` nécessaires). Un contenu propre à un format se
place dans `::: {.content-visible when-format="html"}`.

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

Le PDF d’une présentation passe par Beamer (LaTeX) : Quarto n’a pas de
diapositives Typst, et un export PDF de reveal.js demanderait un
navigateur (impression depuis Chrome avec `?print-pdf`).

Un template de présentation contient un `template.yml`
(`type: presentation`), un `slides.qmd` (en-tête YAML et diapositives)
et les fichiers dont il a besoin. Avec `shared: inrae` dans son
`template.yml`, il réutilise la charte du dossier `inst/shared/inrae/`
(couleurs, polices, logo) que partagent aussi les books : un template
enregistré avec
[`create_template_presentation()`](https://kbosirany.github.io/kquarto.r/dev/reference/create_template_presentation.md)
en reçoit une copie et reste autonome.

## Templates

Un template est un dossier contenant au moins un `_quarto.yml`, plus
tous les fichiers à copier dans un nouveau rapport (chapitres,
`references.bib`, `styles.css`, logos…). Un rapport déjà mis en forme
peut devenir un template :

``` r

create_template_book("mon_template", from = "rapport_technique")
list_templates_book()
create_book("nouveau_rapport", template = "mon_template")
```

Les templates utilisateur sont stockés dans
[`template_dir()`](https://kbosirany.github.io/kquarto.r/dev/reference/template_dir.md).

### Template INRAE

Le package livre aussi le template `inrae`, conforme à la charte
graphique INRAE (couleurs, polices, logo, favicon, page de titre et
bibliographie) :

``` r

create_book("rapport", template = "inrae")

# Ou comme template par défaut
options(kquarto.r.template = "inrae")
```

### Templates d’autres packages

Un package peut aussi livrer ses propres templates dans
`inst/templates/<nom>/`, par exemple pour la charte d’une unité :

``` r

# Depuis la racine du package monpkg
create_template_book("charte", from = "inrae", dir = "inst/templates")

# Puis, partout
create_book("rapport", template = "monpkg::charte")
```
