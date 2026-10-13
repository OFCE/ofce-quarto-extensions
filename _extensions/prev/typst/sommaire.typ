///// SOMMAIRE COMMUN DE LA PRÉVISION
//
// Liste de tous les chapitres de la prévision, identique d'un pdf à l'autre ;
// le chapitre du pdf en cours est mis en avant. Les sections et les chapitres
// viennent de la barre latérale du site, par le filtre sommaire.lua.
//
// `sections` : tableau de `(titre: [..], chapitres: (..))`, chaque chapitre
// étant `(titre: [..], url: ".." ou none, courant: true ou false)`.
//
// Le sommaire est posé en couverture, sous le titre et les auteurs : le gabarit
// (typst-template.typ, chargé avant ce fichier, d'où viennent couleurs et
// polices) le reçoit par l'argument `sommaire` de `title-page`.

#let sommaire-prev(titre: [], sections: ()) = {
  let bloc_section(section) = block(width: 100%, breakable: false, below: 1.3em, {
    text(section.titre, weight: "bold", fill: ife1)
    v(0.5em, weak: true)
    line(length: 100%, stroke: (thickness: 0.4pt, paint: grey2))
    v(0.6em, weak: true)
    for chapitre in section.chapitres {
      let libelle = if chapitre.url != none { link(chapitre.url, chapitre.titre) } else { chapitre.titre }
      // Le chapitre en cours : en gras, sur un filet de couleur à gauche.
      block(
        width: 100%,
        above: 0.2em,
        below: 0.2em,
        inset: (left: 0.6em, y: 0.2em),
        stroke: if chapitre.courant { (left: 2pt + ife2) } else { (left: 2pt + white) },
        if chapitre.courant { text(libelle, weight: "bold", fill: ife2) } else { text(libelle, fill: grey0) },
      )
    }
  })

  block(width: 100%, {
    set par(justify: false, leading: 0.5em)
    set text(size: 9pt, font: main_title_font)
    text(titre, font: serif_font, size: 12pt, weight: "bold", fill: ife2)
    v(1em)
    // Deux colonnes de longueur voisine : une section va dans la première si
    // son milieu tombe avant la moitié des lignes (titres de section compris).
    let lignes = sections.map(s => s.chapitres.len() + 2)
    let moitie = lignes.sum(default: 0) / 2
    let gauche = ()
    let droite = ()
    let cumul = 0
    for (i, section) in sections.enumerate() {
      if cumul + lignes.at(i) / 2 <= moitie { gauche.push(section) } else { droite.push(section) }
      cumul += lignes.at(i)
    }
    grid(
      columns: (1fr, 1fr),
      column-gutter: 0.8cm,
      // Les deux colonnes partent du haut, quel que soit l'alignement ambiant.
      align: top + left,
      for section in gauche { bloc_section(section) },
      for section in droite { bloc_section(section) },
    )
  })
}
