// Style INRAE pour la sortie PDF (Typst). Les polices sont utilisees si
// elles sont installees ; sinon Typst prend la suivante de la liste.
// La couleur principale et le logo viennent de _brand.yml.
#set text(font: ("Avenir Next Pro", "Calibri", "Liberation Sans"))
#show heading: set text(font: ("Raleway", "Calibri", "Liberation Sans"))
#set page(
  footer: context [
    #set text(fill: rgb("#797870"), size: 9pt)
    INRAE #h(1fr) #counter(page).display()
  ],
)
