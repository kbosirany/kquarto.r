# kquarto.r

Site : <https://kbosirany.github.io/kquarto.r/> (version en
développement : <https://kbosirany.github.io/kquarto.r/dev/>)

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

## Site pkgdown

``` r

# Rendre les books de reports/ dans public/reports/, les ajouter à la
# barre de navigation (_pkgdown.yml) puis construire le site pkgdown
build_site()

# Seulement mettre à jour la barre de navigation
update_pkgdown_yml()
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
