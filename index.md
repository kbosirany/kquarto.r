# kquarto.r

Site : <https://kbosirany.github.io/kquarto.r/> (version en
développement : [/dev](https://kbosirany.github.io/kquarto.r/dev/))

Créer, modéliser (templates) et générer des rapports Quarto de type
*book*, dans un package R ou dans un projet de rédaction indépendant.

## Utilisation

``` r

library(kquarto.r)

# Créer deux rapports avec un _quarto.yml rempli
create_book(
  c("rapport_technique", "note_synthese"),
  title = c(note_synthese = "Note de synthèse"),
  author = "Kevin Orlando",
  lang = "fr",
  chapters = c("Introduction", "Méthodes")
)
# -> rapport_technique/chapitre-01-introduction.qmd, chapitre-02-methodes.qmd

# Ajouter un chapitre : numéro suivant, ajouté au _quarto.yml
create_book_chapter("rapport_technique", "Résultats")
# -> chapitre-03-resultats.qmd ("chapter-03-..." si lang = "en")

# Générer un rapport (par défaut dans rapport_technique/_book)
render_book("rapport_technique")

# ... ou ailleurs, chemin relatif au dossier du rapport
render_book("rapport_technique", output_dir = "../docs/rapport_technique")

# Générer tous les books du dossier courant
render_book()
```

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

### Templates livrés par un package

Un package (par exemple une charte institutionnelle) peut livrer ses
templates dans `inst/templates/<nom>/` :

``` r

# Depuis la racine de ce package
create_template_book("inrae", from = "default", dir = "inst/templates")

# Utilisation
create_book("rapport", template = "kquarto.r.inrae::inrae")
list_templates_book(packages = "kquarto.r.inrae")
```

Pour en faire le template par défaut, le package peut envelopper les
fonctions (`template = "kquarto.r.inrae::inrae"` par défaut) ou définir
`options(kquarto.r.template = "kquarto.r.inrae::inrae")`.
