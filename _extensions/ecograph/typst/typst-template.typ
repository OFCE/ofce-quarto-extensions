///// GABARIT TYPST — ECOGRAPH (GRAPHIQUE DE LA SEMAINE)
//
// Hiérarchie des commentaires : ///// une page du document, //// une section,
// /// une sous-section, // une remarque ponctuelle.
//
// Le fichier est traité comme un template pandoc : le signe dollar y est un
// caractère d'échappement et doit être doublé (voir la regex de `fmt_date_iso`).
//
// Le format tient sur deux pages à l'italienne : un bandeau de titre puis le
// graphique centré, et en seconde page deux colonnes — résumé, dates et liens
// à gauche, texte d'accompagnement à droite.

#import "@preview/icu-datetime:0.1.2": fmt-datetime, fmt-date

///// PRÉAMBULE — styles et fonctions communes

//// Constantes de style

/// Couleurs
#let grey0 = rgb("#030303")
#let grey1 = rgb("#6B6B6B")
#let grey2 = rgb("#A6A6A6")
#let grey3 = rgb("#E6E1D8")
#let scpored = rgb("#e6142d")
#let scpodarkred = rgb("#770C19")
#let colourtype = rgb("#DB2E43")
#let ife1 = rgb("#7D0000")
#let ife2 = rgb("#21606E")
#let ifegrey = rgb("#DDDBDB")

/// Polices
//
// Mêmes polices que les autres gabarits OFCE : Arimo pour le texte, posé par
// `mainfont` dans le yaml, Merriweather pour les titres — titre du bandeau,
// mention du format et titres de section.
#let serif_font = "Merriweather"

/// Tableaux : pas de filets, ce sont les tableaux gt qui posent les leurs
#set table(inset: 6pt, stroke: none)

//// Libellés du gabarit

// Le français est la langue par défaut ; `lang: en` dans le yaml bascule
// l'ensemble des textes inscrits en dur. Les variantes régionales (en-GB,
// fr-BE, ...) sont ramenées à leur langue.
#let is_en(language) = language != none and lower(language).starts-with("en")

// Choisit entre deux libellés (chaîne ou contenu) selon la langue.
#let tr(language, fr, en) = if is_en(language) { en } else { fr }

//// Instituts

// `institut` dans le yaml choisit le logo du bandeau de titre. Valeur par
// défaut : « ofce », c'est-à-dire le comportement d'avant l'ajout de cet
// argument. Le logo Sciences Po posé en dessous ne dépend pas de l'institut,
// et la mention « EcoGraph » non plus.
#let instituts = (
  "ofce": (logo: "ofce.png", sigle: [OFCE], nom: [OFCE]),
  "ife": (logo: "IFE_Institut_logo_noir.png", sigle: [IFE], nom: [Institut français d'économie]),
  "ife-ofce": (logo: "IFE-OFCE_logo_noir.png", sigle: [IFE|OFCE], nom: [IFE|OFCE]),
  "ife-cepii": (logo: "IFE-CEPII_logo_noir.png", sigle: [IFE|CEPII], nom: [IFE|CEPII]),
  "ife-ofce-cepii": (logo: "IFE-OFCE-CEPII_logo_noir.png", sigle: [IFE|OFCE|CEPII], nom: [IFE|OFCE|CEPII]),
)

// Les logos n'ont pas le même format : ils sont dimensionnés en hauteur, pour
// un poids visuel identique d'un institut à l'autre. Cette hauteur est celle
// du logo OFCE tel qu'il était posé en largeur (2 cm).
#let hauteur_logo = 0.92cm

// Le logo Sciences Po est posé à côté de celui de l'institut, et plus petit
#let hauteur_sciencespo = hauteur_logo * 0.55

// sciencespo.png porte une marge blanche d'environ 15 % de sa hauteur, en haut
// comme en bas, là où le logo de l'institut est détouré au plus près. Aligner
// les deux images par le bas laisse donc le Sciences Po flotter de cette marge
// au-dessus de la ligne de base de l'autre ; on l'en redescend d'autant.
// Mesuré sur le fichier : 13 pixels de blanc sous un visuel de 85 pixels.
#let marge_basse_sciencespo = 13 / 85

// Fiche de l'institut demandé ; erreur explicite si la valeur est inconnue.
#let fiche_institut(institut) = {
  let cle = if institut == none { "ife" } else { lower(str(institut).trim()) }
  if cle not in instituts {
    panic("institut inconnu : « " + cle + " ». Valeurs possibles : " + instituts.keys().join(", ") + ".")
  }
  instituts.at(cle)
}

#let chemin_logo(fichier) = "/_extensions/ofce/ofce/img/" + fichier

//// Fonctions communes

/// Mise en forme d'une date ISO (première publication, dernière modification)
//
// Renvoie `none` si aucune date n'est fournie, et "????" si la valeur fournie
// n'est pas une date ISO (AAAA-MM-JJ) valide — plutôt que de faire échouer la
// compilation.
#let fmt_date_iso(value, language) = {
  if value == none { return none }

  let raw = if type(value) == str { value } else if value.has("text") { value.text } else { "" }
  if raw.trim() == "" { return none }

  // `$$` : échappement pandoc, le fichier est traité comme un template.
  let m = raw.trim().match(regex("^(\\d{4})-(\\d{1,2})-(\\d{1,2})$$"))
  if m == none { return "????" }

  let y = int(m.captures.at(0))
  let mo = int(m.captures.at(1))
  let d = int(m.captures.at(2))
  if mo < 1 or mo > 12 { return "????" }

  let leap = calc.rem(y, 4) == 0 and (calc.rem(y, 100) != 0 or calc.rem(y, 400) == 0)
  let last_day = if mo == 2 and leap {
    29
  } else {
    (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31).at(mo - 1)
  }
  if d < 1 or d > last_day { return "????" }

  fmt-date(datetime(year: y, month: mo, day: d), length: "long", locale: language)
}

/// Année affichée sous le numéro
//
// `annee` dans le yaml si elle est renseignée ; à défaut, l'année de la date
// de publication ; `none` si l'on ne dispose ni de l'une ni de l'autre.
#let annee_doc(year, first_publish) = {
  if year != none and year != [] { return year }
  if first_publish == none { return none }
  let raw = if type(first_publish) == str { first_publish } else if first_publish.has("text") { first_publish.text } else { "" }
  let m = raw.trim().match(regex("^(\\d{4})-"))
  if m == none { none } else { m.captures.at(0) }
}

/// Texte brut d'une valeur transmise par pandoc
//
// `urlblog` arrive sous forme de contenu : on en extrait la chaîne pour
// pouvoir la passer à `link()`. Pandoc échappe « // » en « /\/ » : on rétablit
// l'URL au passage.
#let texte_brut(valeur) = {
  let extrait(c) = {
    if type(c) == str { c }
    else if c.has("text") { c.text }
    else if c.has("children") { c.children.map(extrait).join("") }
    else if c.has("body") { extrait(c.body) }
    else { "" }
  }
  let brut = if type(valeur) == str { valeur } else { extrait(valeur) }
  brut.replace("/\\/", "//")
}

///// LA PAGE — bandeau de titre, puis graphique et texte en regard

#let single-page-blog(
  title: [],
  subtitle: [],
  authors: none,
  extrarefs: none,
  abstract: none,
  analyse: none,
  first_publish: none,
  modified: none,
  year: none,
  number: none,
  institut: none,
  language: "fr",
  font: ("Arimo", "Arial"),
  fontsize: 11pt,
  linkcolor: rgb(0, 0, 0),
  linky: none,
  scalepic: 1,
  voir_aussi: none,
  doc,
) = {

  //// Valeurs dérivées des métadonnées

  let fiche = fiche_institut(institut)

  let pretty_date = fmt_date_iso(first_publish, language)
  let pretty_modified = fmt_date_iso(modified, language)
  let annee = annee_doc(year, first_publish)

  //// Géométrie

  let marge = 0.5cm

  //// Réglages de page et de texte

  set page(
    paper: "a4",
    flipped: true,
    margin: (left: 2cm, right: 2cm, top: 0.5cm, bottom: 0.5cm),
    numbering: none,
  )

  set text(font: font, size: fontsize, region: "FR")
  set par(justify: false, leading: 0.6em, spacing: 1em)

  show link: set text(fill: linkcolor)
  show cite: set text(fill: linkcolor)

  /// Titres de section : Merriweather à tous les niveaux, comme le titre ;
  /// la page est courte, seuls les deux premiers niveaux sont mis en forme.
  show heading: set text(font: serif_font)
  show heading.where(level: 1): it => block(width: 100%, below: 0.8em, above: 1em)[
    #set text(size: fontsize * 1.1, weight: "bold")
    #it
  ]
  show heading.where(level: 2): it => block(width: 100%, below: 0.8em, above: 1em)[
    #set text(size: fontsize * 1.05)
    #it
  ]

  ///// BANDEAU DE TITRE — compact, pour laisser la hauteur au graphique

  //// Logos, numéro, année et mention du format

  // Les deux logos sur une même ligne : la grille s'adapte à la largeur du logo
  // de l'institut, qui varie de l'un à l'autre. Le logo Sciences Po, plus petit,
  // est aligné sur le bas de la ligne et non sur son milieu.
  place(top + left, dx: 0cm, dy: 0cm,
    grid(columns: 2, column-gutter: 0.7cm, align: (horizon, bottom),
      image(chemin_logo(fiche.logo), height: hauteur_logo),
      move(dy: hauteur_sciencespo * marge_basse_sciencespo,
        image(chemin_logo("sciencespo.png"), height: hauteur_sciencespo))))

  place(top + right, dy: 0cm, dx: marge,
    square(fill: ife2, size: 1cm, align(center + horizon, text(fill: white, size: 0.8cm, number))))

  // L'année n'est affichée que si elle est connue (`annee` dans le yaml, ou
  // déduite de la date de publication).
  if annee != none {
    place(top + right, dy: 1.05cm, dx: marge,
      text(fill: ife2, size: 0.43cm, align(right + horizon, annee)))
  }

  v(2em)
  
  place(top + right, dx: -0.5cm, dy: 0.15cm,
    align(horizon, text(fill: gray, size: 0.9cm, font: serif_font, style: "italic", "EcoGraph ")))

  v(2em)

  //// Titre, puis signature
  //
  // Le titre occupe toute la largeur, au-dessus des deux colonnes, et la
  // signature se pose sous lui. Les dates, elles, restent dans la colonne de
  // texte : sur une page unique, chaque ligne du bandeau est prise sur le
  // graphique.

  block(text(size: 15pt, weight: "bold", fill: ife1, font: serif_font, title))

  v(0.55em)

  if authors != none {
    for author in authors {
      text(author.name, weight: "bold", size: 10pt)
      if author.affiliation != none and author.affiliation != "" {
        text(", ", size: 10pt)
        text(author.affiliation, style: "italic", size: 10pt, fill: grey1)
      }
      linebreak()
    }
  }

  v(0.5em)

  ///// LES DEUX COLONNES — graphique à gauche, repères et texte à droite

  // Le graphique prend toute la largeur que la colonne de texte lui laisse ;
  // celle-ci est dimensionnée au plus juste de ce qu'elle a à porter.
  // `scalepic` reste disponible pour le réduire encore.
  let largeur_graphique = 100 * scalepic * 1%

  // Quarto pose le graphique en largeur (`#box(image(.., width: 95%))`) : à
  // fig-asp élevé, la hauteur obtenue dépasse celle de la page. On mesure donc
  // sa taille naturelle à la largeur de la colonne et on le réduit du facteur
  // qui le fait tenir dans la hauteur disponible. Le facteur est plafonné à 1 :
  // un graphique qui tient déjà n'est jamais agrandi.
  //
  // Le bloc n'a pas de hauteur fixe : un bloc haut d'exactement la place
  // restante ne tient pas toujours — au pt près, Typst le renvoie alors en
  // entier sur la page suivante. Seul le facteur de réduction se calcule sur la
  // hauteur disponible, et le bloc prend la hauteur du graphique réduit.
  let graphique_ajuste(contenu, hauteur) = block(width: largeur_graphique,
    layout(dispo => {
      let bloc = box(width: dispo.width, contenu)
      let naturel = measure(bloc)
      let facteur = calc.min(1, hauteur / naturel.height) * 100%
      align(center, scale(x: facteur, y: facteur, reflow: true, bloc))
    }))

  // Renvois « Voir aussi », si `extraref` est renseignée dans le yaml. Ils sont
  // posés sous le graphique : la colonne de texte n'a ainsi à porter que le
  // résumé, les dates et le texte d'accompagnement.
  let renvois = if extrarefs == none { none } else {
    block(width: 100%, {
      text(size: 9pt, fill: ife2, weight: "bold", font: serif_font)[#tr(language, [Voir aussi :], [See also:])]
      v(0.3em)
      for ref in extrarefs {
        let lien = ref.at("lien", default: "")
        if lien != "" {
          text(size: 8pt)[• #link(texte_brut(lien))[#ref.texte]]
        } else {
          text(size: 8pt)[• #ref.texte]
        }
        linebreak()
      }
    })
  }

  // Hauteur laissée par le bandeau, mesurée sur la page plutôt que demandée en
  // `fr` : un `1fr` posé ici n'est pas transmis aux cellules de la grille, et le
  // graphique ne saurait pas de quelle hauteur il dispose. `here()` donne la
  // position courante dans la page, d'où l'on déduit ce qui reste.
  //
  // /!\ La hauteur du bloc de texte vient de `layout` et non de `page.height` :
  // en `flipped: true`, `page.height` renvoie la hauteur du papier avant
  // bascule (841,89 pt pour l'A4), pas celle de la page. `zone.height` est la
  // hauteur utile réelle ; `here().position().y` se compte depuis le haut de la
  // page, d'où la marge haute rajoutée.
  layout(zone => context {
  let hauteur_dispo = zone.height + page.margin.top - here().position().y

  grid(
    columns: (1fr, 29%),
    column-gutter: 1.4em,

    /// Colonne de gauche : le graphique, aussi grand que la place le permet,
    /// puis les renvois « Voir aussi ». La hauteur de ces derniers est mesurée
    /// à la largeur de la colonne et retirée de celle offerte au graphique.
    /// L'écart entre les deux est posé à la main : l'espacement que Typst
    /// glisse entre deux blocs successifs n'entre pas dans la mesure, et le
    /// graphique débordait alors de la hauteur de cet espacement — assez pour
    /// renvoyer les renvois sur une seconde page.
    layout(cellule => {
      let ecart = 8pt
      let hauteur_renvois = if renvois == none { 0pt } else {
        measure(box(width: cellule.width, renvois)).height + ecart
      }
      block(width: 100%, {
        set block(spacing: 0pt)
        graphique_ajuste(doc, hauteur_dispo - hauteur_renvois)
        v(ecart)
        renvois
      })
    }),

    /// Colonne de droite : signature, résumé, dates, lien, puis le texte
    /// d'accompagnement sorti du corps du document par `analyse.lua`.
    [
      #set text(size: 9pt)

      #if abstract != none and abstract != [] {
        // Résumé justifié : c'est un bloc de texte suivi, pas un titre.
        block(fill: grey3, inset: 0.8em, radius: 3pt, width: 100%, {
          set par(justify: true)
          text(size: 9pt, abstract)
        })
      }

      #if pretty_date != none {
        v(0.5em)
        text(fill: grey1, [#tr(language, [Publié le], [Published]) #pretty_date])
        linebreak()
      }
      #if pretty_modified != none {
        text(fill: grey1, [#tr(language, [Modifié le], [Modified]) #pretty_modified])
        linebreak()
      }

      // Lien vers le billet en ligne, si `urlblog` est renseignée dans le yaml.
      #if linky != none {
        v(0.5em)
        let url_str = texte_brut(linky)
        // Le libellé en gras et en serif, l'URL dans la graisse du texte
        // courant : `align` ne prend qu'un seul corps, les deux sont donc
        // réunis dans un même bloc de contenu.
        align(left, text(fill: ife2)[
          #text(weight: "bold", font: serif_font)[#tr(language, [Lien vers le billet sur le site de l'IFE|OFCE :], [Read this post on the IFE|OFCE website:])]
          #link(url_str)[#url_str]
        ])
      }

      #if analyse != none and analyse != [] {
        v(0.6em)
        set par(justify: true, spacing: 0.75em)
        set text(size: 8.5pt, lang: language, hyphenate: true)
        analyse
      }
    ],
  )
  })
}
