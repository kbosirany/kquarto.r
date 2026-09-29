# kquarto.r

Créer, modéliser (templates) et générer des rapports Quarto de type *book*,
dans un package R ou dans un projet de rédaction indépendant.

## Utilisation

```r
library(kquarto.r)

# Créer deux rapports avec un _quarto.yml rempli
create_book(
  c("rapport_technique", "note_synthese"),
  title = c(note_synthese = "Note de synthèse"),
  author = "Kevin",
  lang = "fr"
)

# Générer un rapport (par défaut dans rapport_technique/_book)
render_book("rapport_technique")

# ... ou ailleurs, chemin relatif au dossier du rapport
render_book("rapport_technique", output_dir = "../docs/rapport_technique")

# Générer tous les books du dossier courant
render_book()
```

## Templates

```r
# Enregistrer un rapport déjà configuré comme template réutilisable
create_template_book("mon_template", from = "rapport_technique")
list_templates_book()

# L'utiliser dans un autre projet
create_book("nouveau_rapport", template = "mon_template")
```

Les templates utilisateur sont stockés dans `template_dir()`
(`tools::R_user_dir("kquarto.r", "data")`), modifiable via
`options(kquarto.r.template_dir = "...")`.
