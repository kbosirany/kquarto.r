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

[`create_book()`](https://kbosirany.github.io/kquarto.r/reference/create_book.md)
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
#> [1] "_quarto.yml"                  "chapitre-01-introduction.qmd"
#> [3] "chapitre-02-methodes.qmd"     "index.qmd"
cat(readLines(file.path(projet, "rapport_technique", "_quarto.yml")), sep = "\n")
#> project:
#>   type: book
#>   output-dir: _book
#> book:
#>   title: rapport_technique
#>   chapters:
#>   - index.qmd
#>   - chapitre-01-introduction.qmd
#>   - chapitre-02-methodes.qmd
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
[`create_book_chapter()`](https://kbosirany.github.io/kquarto.r/reference/create_book_chapter.md)
prend le numéro suivant et met à jour `_quarto.yml` :

``` r

create_book_chapter("rapport_technique", "Résultats", path = projet)
#> Chapter created: rapport_technique/chapitre-03-resultats.qmd
list_books(projet)
#> [1] "note_synthese"     "rapport_technique"
yaml::read_yaml(file.path(projet, "rapport_technique", "_quarto.yml"))$book$chapters
#> [1] "index.qmd"                    "chapitre-01-introduction.qmd"
#> [3] "chapitre-02-methodes.qmd"     "chapitre-03-resultats.qmd"
```

## Générer les rapports

[`render_book()`](https://kbosirany.github.io/kquarto.r/reference/render_book.md)
appelle
[`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html).
Par défaut, le rapport est généré dans `_book/` à l’intérieur de son
dossier ; `output_dir` est un chemin relatif au dossier du rapport.

``` r

render_book("rapport_technique")
render_book("rapport_technique", output_dir = "../docs/rapport_technique")
render_book() # tous les books du dossier courant
```

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
[`template_dir()`](https://kbosirany.github.io/kquarto.r/reference/template_dir.md).
Un package peut aussi livrer ses propres templates dans
`inst/templates/<nom>/`, par exemple pour une charte graphique
institutionnelle :

``` r

# Depuis la racine du package kquarto.r.inrae
create_template_book("inrae", dir = "inst/templates")

# Puis, partout
create_book("rapport", template = "kquarto.r.inrae::inrae")

# Ou comme template par défaut
options(kquarto.r.template = "kquarto.r.inrae::inrae")
```
