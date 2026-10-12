// Style INRAE pour la sortie PDF (Typst). Les polices sont utilisees si
// elles sont installees ; sinon Typst prend la suivante de la liste.
#let inrae-vert = rgb("#00a3a6")
#let inrae-vert-fonce = rgb("#00787a")
#let titres = ("Raleway", "Avenir Next Pro", "Calibri", "Liberation Sans")

#set text(font: ("Avenir Next Pro", "Calibri", "Liberation Sans"))
#show heading: set text(fill: inrae-vert-fonce, font: titres)
#show link: set text(fill: inrae-vert-fonce)
#set page(
  header: align(right, image("images/logo-inrae.png", width: 3cm)),
  footer: context [
    #set text(fill: rgb("#797870"), size: 9pt)
    INRAE #h(1fr) #counter(page).display()
  ],
)
