///// GABARIT TYPST — BLOG DE L'OFCE
//
// Hiérarchie des commentaires : ///// une page du document, //// une section,
// /// une sous-section, // une remarque ponctuelle.
//
// Le fichier est traité comme un template pandoc : le signe dollar y est un
// caractère d'échappement et doit être doublé (voir la regex de `fmt_date_iso`).

#import "@preview/icu-datetime:0.1.2": fmt-datetime, fmt-date

///// PRÉAMBULE — styles et fonctions communes

//// Constantes de style

/// Couleurs
#let grey0 = rgb("#030303")
#let grey1 = rgb("#6B6B6B")
#let grey2 = rgb("#A6A6A6")
#let grey3 = rgb("#D6D6D6")
#let scpored = rgb("#e6142d")
#let scpodarkred = rgb("#770C19")
#let colourtype = rgb("#EEC900")
#let ife1 = rgb("#7D0000")
#let ife2 = rgb("#21606E")
#let ifegrey = rgb("#DDDBDB")
// Gris des encadrés (callouts), repris pour le fond du résumé.
#let grey_encadre = rgb("#EDEAEA")
#let ifeanthracite = rgb("#28252F")

/// Polices
//
// Mêmes polices que le document de travail : Arimo pour le corps du texte (posé par `mainfont` dans le yaml), Merriweather pour les
// titres de niveau 1, la table des matières et les guillemets de citation.
#let main_title_font = "Arimo"
#let serif_font = "Merriweather"

/// Filets des tableaux
//
// Trois sources dessinaient des filets d'épaisseurs et de couleurs
// différentes dans un même tableau :
//   - pandoc pose un `table.hline()` sans argument sous l'en-tête et au-dessus
//     du pied de tableau ; sans stroke explicite, typst les trace en 1pt noir ;
//   - les bordures des groupes de lignes viennent de la CSS de gt, converties
//     en `stroke:` sur les cellules : gris clair (#d3d3d3) et 1,5pt ;
//   - le filet du haut n'était pas tracé du tout : gt le dessine en html, mais
//     ni `table.border.top` ni `column_labels.border.top` ne survivent à la
//     conversion html -> pandoc -> typst.
//
// Tout est ramené à `filet_tableau` ici, sans rien changer du côté R
#let filet_tableau = 0.4pt + ifeanthracite

// Les filets de pandoc (sous l'en-tête, au-dessus du pied).
#set table.hline(stroke: filet_tableau)

// Le filet du haut, que gt ne transmet pas : il est posé ici, sur le bord
// supérieur des cellules de la première ligne. Les autres bords restent nus —
// les filets intérieurs sont ceux de gt et de pandoc, pas ceux du `table`.
#set table(
  inset: 6pt,
  stroke: (x, y) => if y == 0 { (top: filet_tableau) },
)

/// Reprise des traits que gt pose lui-même
//
// Les bordures des groupes de lignes arrivent en argument explicite sur la
// cellule (`table.cell(stroke: (top: ..., bottom: ...))`), gris clair et en
// 1,5pt. Un argument explicite l'emporte sur toute règle `set`, et une règle
// `show table.cell` ne peut remplacer que le contenu d'une cellule, pas ses
// traits : il faut reconstruire les enfants du tableau.
//
// Chaque côté effectivement dessiné prend `filet_tableau` ; les côtés nus le
// restent. `auto` et `none` sont laissés tels quels : ils relèvent du `set
// table` ci-dessus, qui a déjà la bonne épaisseur.
//
// Le trait est lu par `fields()`, et non par `enfant.stroke` : une cellule qui
// n'en porte pas explicitement fait échouer l'accès direct au champ
// (« field "stroke" in cell is not known at this point »).
#let trait_cellule(enfant) = enfant.fields().at("stroke", default: auto)

#let filet_normalise(trait) = {
  if type(trait) == dictionary {
    let sortie = (:)
    for (cote, valeur) in trait {
      sortie.insert(cote, if valeur == none { none } else { filet_tableau })
    }
    sortie
  } else if trait == none or trait == auto {
    trait
  } else {
    filet_tableau
  }
}

#let cellule_a_reprendre(enfant) = {
  enfant.func() == table.cell and filet_normalise(trait_cellule(enfant)) != trait_cellule(enfant)
}

// Le filet sous un libellé de regroupement de colonnes (`tab_spanner`), que gt
// dessine en html et que la conversion perd, comme celui du haut. La cellule
// du libellé se reconnaît à son `colspan` : dans un en-tête gt, seul un
// spanner couvre plusieurs colonnes. Le trait ne court alors que sur les
// colonnes regroupées, puisqu'il est porté par cette cellule.
//
// La cellule du pied de tableau porte elle aussi un `colspan`, mais le pied
// n'est pas parcouru : seuls les enfants de `table.header` le sont.
// Les parenthèses sont nécessaires : typst ne poursuit pas une expression
// d'une ligne sur l'autre, que l'opérateur soit en fin ou en début de ligne.
#let spanner_a_reprendre(enfant) = (
  enfant.func() == table.cell
    and enfant.fields().at("colspan", default: 1) >= 2
    and trait_cellule(enfant) == auto
)

#let reprendre_cellule(enfant, trait) = {
  let cf = enfant.fields()
  let corps = cf.remove("body")
  // `default` est indispensable : une cellule de spanner n'a pas de champ
  // `stroke`, et `remove` sur une clé absente est une erreur.
  let _ = cf.remove("stroke", default: none)
  table.cell(..cf, stroke: trait, corps)
}

#let reprendre_entete(entete) = {
  if not entete.children.any(spanner_a_reprendre) { return entete }
  let champs = entete.fields()
  let _ = champs.remove("children")
  table.header(
    ..champs,
    ..entete.children.map(enfant => {
      if spanner_a_reprendre(enfant) {
        reprendre_cellule(enfant, (bottom: filet_tableau))
      } else {
        enfant
      }
    }),
  )
}

// La règle se rappelle sur le tableau qu'elle reconstruit ; elle s'arrête au
// second passage, où plus rien n'est à reprendre.
#show table: it => {
  let entete_a_faire = it.children.any(enfant => {
    enfant.func() == table.header and enfant.children.any(spanner_a_reprendre)
  })
  if not it.children.any(cellule_a_reprendre) and not entete_a_faire {
    return it
  }
  let champs = it.fields()
  let _ = champs.remove("children")
  table(
    ..champs,
    ..it.children.map(enfant => {
      if enfant.func() == table.header {
        reprendre_entete(enfant)
      } else if cellule_a_reprendre(enfant) {
        reprendre_cellule(enfant, filet_normalise(trait_cellule(enfant)))
      } else {
        enfant
      }
    }),
  )
}

/// Air entre la légende et le flottant
#set figure(gap: 1.1em)

/// Air au-dessus des graphiques et des tableaux (1,5em en dessous)
#let espacement_flottant = 3em

//// Libellés du gabarit

// Le français est la langue par défaut ; `lang: en` dans le yaml bascule
// l'ensemble des textes inscrits en dur. Les variantes régionales (en-GB,
// fr-BE, ...) sont ramenées à leur langue.
#let is_en(language) = language != none and lower(language).starts-with("en")

// Choisit entre deux libellés (chaîne ou contenu) selon la langue.
#let tr(language, fr, en) = if is_en(language) { en } else { fr }

//// Rédaction du blog

// Nom des rédacteurs en chef, imprimé en fin de billet, sous la citation suggérée.
#let redaction_fr = "Rédacteurs en chef : Elliot Aurissergues & Paul Malliet"
#let redaction_en = "Editors-in-chief: Elliot Aurissergues & Paul Malliet"

//// Instituts

// `institut` dans le yaml choisit le logo des entêtes de page et le sigle qui
// précède le numéro du billet dans les entêtes et la citation suggérée. Valeur
// par défaut : « ife », le blog paraissant sous la bannière de l'Institut
// français d'économie.
// `sigle` : forme courte, seule à tenir dans une entête de page.
// `nom` : forme développée, pour les usages où la place ne manque pas.
#let instituts = (
  "ofce": (
    logo: "ofce.png", logo_entete: "ofce.png",
    sigle: [OFCE], nom: [OFCE]),
  "ife": (
    logo: "IFE_Institut_logo_noir.png", logo_entete: "IFE_Institut_logo_noir.png",
    sigle: [IFE], nom: [Institut français d'économie]),
  "ife-ofce": (
    logo: "IFE-OFCE_logo_noir.png", logo_entete: "IFE-OFCE_logo_noir.png",
    sigle: [IFE|OFCE], nom: [IFE|OFCE]),
  "ife-cepii": (
    logo: "IFE-CEPII_logo_noir.png", logo_entete: "IFE-CEPII_logo_noir.png",
    sigle: [IFE|CEPII], nom: [IFE|CEPII]),
  "ife-ofce-cepii": (
    logo: "IFE-OFCE-CEPII_logo_noir.png", logo_entete: "IFE-OFCE-CEPII_logo_noir.png",
    sigle: [IFE|OFCE|CEPII], nom: [IFE|OFCE|CEPII]),
)

// Les logos n'ont pas le même format : ils sont dimensionnés en hauteur, pour
// un poids visuel identique d'un institut à l'autre. Cette hauteur est celle
// du logo OFCE tel qu'il était posé en largeur (1 cm).
#let hauteur_logo_entete = 0.46cm

// Logos du haut de la première page : celui de l'institut, et en dessous celui
// de Sciences Po, au tiers de sa hauteur majoré de 30 %.
#let hauteur_logo_premiere = 1.3cm
#let hauteur_sciencespo = hauteur_logo_premiere / 3 * 1.3

// Fiche de l'institut demandé ; erreur explicite si la valeur est inconnue.
#let fiche_institut(institut) = {
  let cle = if institut == none { "ife" } else { lower(str(institut).trim()) }
  if cle not in instituts {
    panic("institut inconnu : « " + cle + " ». Valeurs possibles : " + instituts.keys().join(", ") + ".")
  }
  instituts.at(cle)
}

#let chemin_logo(fichier) = "/_extensions/ofce/ofce/img/" + fichier

// Mention du blog dans les entêtes de page : « Blog OFCE nº 12 » en français,
// « OFCE blog no. 12 » en anglais.
#let mention_blog(language, sigle, numero) = {
  if is_en(language) [#sigle blog no. #numero] else [Blog #sigle nº #numero]
}

// Nom de la série tel qu'il paraît dans la citation suggérée : « Blog OFCE »
// en français, « OFCE blog » en anglais.
#let serie_blog(language, sigle) = {
  if is_en(language) [#sigle blog] else [Blog #sigle]
}

//// Fonctions communes

/// Pseudo-notes des encadrés
//
// Quarto rend les blocs `::: aside` par la fonction `note()` du paquet
// marginalia, qui les renvoie dans la marge — donc hors de l'encadré.
// Comme ces blocs servent ici de notes de bas d'encadré (appels numérotés
// à la main dans le texte), on redéfinit `note` pour qu'elle compose son
// contenu sur place : sous un filet, en plus petit, à l'endroit où l'aside
// est écrit — c'est-à-dire à la fin de l'encadré qui le contient.
// Cette définition masque celle importée par quarto.
#let note(..args) = {
  let body = args.pos().at(0, default: [])
  block(width: 100%, above: 1em, below: 0.2em, {
    line(length: 30%, stroke: (thickness: 0.4pt, paint: grey1))
    v(0.4em, weak: true)
    set text(size: 0.8em, fill: grey1)
    body
  })
}

/// Encadrés (callouts)
#let callout(
  body: [],
  title: "Callout",
  background_color: none,
  icon: none,
  icon_color: none,
  body_background_color: white,
) = {
  let _bg = rgb("#EDEAEA")
  let _ic = rgb("#EDEAEA")
  let _bbg = rgb("#EDEAEA")
  block(
    breakable: true,
    fill: _bg,
    stroke: (paint: _ic, thickness: 0.5pt, cap: "round"),
    width: 100%,
    radius: 2pt,
    block(
      breakable: true,
      // Le `below: 0pt` identifie ce bandeau de titre : la règle `show block`
      // de `preprint` s'en sert pour le passer en gras et le rendre `sticky`.
      inset: 1pt,
      width: 100%,
      below: 0pt,
      block(breakable: true, fill: _bg, width: 100%, inset: 8pt)[#if icon != none [#text(_ic, weight: 900)[#icon] ]#title],
    ) + if body != [] {
      block(
        breakable: true,
        inset: 1pt,
        width: 100%,
        block(breakable: true, fill: _bbg, width: 100%, inset: 8pt, align(left, body)),
      )
    },
  )
}

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

/// Année affichée dans les entêtes et la citation suggérée
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

///// PAGES DE TEXTE — CORPS DU BILLET

#let preprint(
  title: none,
  subtitle: none,
  running-head: none,
  authors: none,
  affiliations: none,
  abstract: none,
  keywords: none,
  authornote: none,
  citation: none,
  stable-url: none,
  first_publish: none,
  modified: none,
  number: none,
  year: none,
  institut: none,
  leading: 0.6em,
  spacing: 1em,
  first-line-indent: 0cm,
  linkcolor: rgb(0, 0, 0),
  paper: "a4",
  language: "fr",
  region: "US",
  font: ("Times", "Times New Roman", "Arial"),
  fontsize: 11pt,
  section-numbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  bibliography-title: none,
  bibliography-style: "apa",
  cols: 1,
  col-gutter: 4.2%,
  doc,
) = {

  //// Valeurs dérivées des métadonnées

  let pretty_date = fmt_date_iso(first_publish, language)
  let pretty_modified = fmt_date_iso(modified, language)

  let fiche = fiche_institut(institut)
  let logo_entete = chemin_logo(fiche.logo_entete)

  // Noms d'auteurs, réutilisés sous le titre et dans la note d'auteur.
  let author_strings = ()
  if authors != none {
    for a in authors {
      author_strings.push([#a.name])
    }
  }

  // Numéro du billet, « ?? » tant que `wp` n'est pas renseigné.
  let numero = if number != none and number != [] { number } else { [??] }

  // Année, « ???? » tant qu'elle n'est ni renseignée ni déductible.
  let annee = {
    let a = annee_doc(year, first_publish)
    if a != none { a } else { [????] }
  }

  // Pandoc échappe « // » en « /\/ » à l'interpolation : on rétablit l'URL.
  let url_stable = if stable-url != none and stable-url != "" { stable-url.replace("/\\/", "//") } else { none }

  // Titres transmis par quarto s'ils sont définis, sinon repli selon la langue.
  let titre_toc = if toc_title != none { toc_title } else { tr(language, "Table des matières", "Contents") }
  let titre_biblio = if bibliography-title != none { bibliography-title } else { tr(language, [Références], [References]) }

  //// Mise en page : entêtes et pieds de page

  set page(
    paper: paper,
    margin: (inside: 3.5cm, outside: 2.5cm, rest: 3cm),
    numbering: "1",
    header-ascent: 50%,
    header: context {
      let repere = query(<ofce-main-start>)
      let debut = if repere.len() > 0 { repere.first().location().page() } else { 1 }

      /// Première page du texte principal : pas d'entête, les logos, le
      /// numéro et les dates sont posés dans la page elle-même
      if here().page() == debut {

      /// Page(s) de table des matières : entête sans numéro de page
      } else if here().page() < debut {
        grid(
          columns: (1fr, auto),
          align(left)[#text([#mention_blog(language, fiche.sigle, numero) - #annee], style: "italic")],
          align(right)[#image(logo_entete, height: hauteur_logo_entete)],
        )
        line(start: (0cm, -0.5em), end: (15cm, -0.5em), stroke: (thickness: 0.25pt, paint: grey1))

      /// Pages suivantes : numéro de page à l'extérieur
      } else {
        if calc.even(here().page()) {
          grid(
            columns: (1fr, 1fr),
            align(left + bottom)[#counter(page).display()],
            align(right + bottom)[#image(logo_entete, height: hauteur_logo_entete)],
          )
        } else {
          grid(
            columns: (1fr, auto),
            align(left)[#text([#mention_blog(language, fiche.sigle, numero) - #annee], style: "italic")],
            align(right)[#counter(page).display()],
          )
        }
        line(start: (0cm, -0.5em), end: (15cm, -0.5em), stroke: (thickness: 0.25pt, paint: grey1))
      }
    },
    footer-descent: 24pt,
    // Pied de page vide, conservé pour le `footer-descent`.
    footer: [],
  )

  //// Réglages de texte

  set par(justify: true, leading: leading, first-line-indent: first-line-indent, spacing: spacing)
  set text(region: region, font: font, size: fontsize)
  set bibliography(title: titre_biblio, style: bibliography-style)

  show link: set text(fill: linkcolor)
  show cite: set text(fill: linkcolor)

  //// Titres de section

  set heading(numbering: section-numbering)

  /// Niveaux 1 à 3 : titres en bloc, au fer à gauche (jamais justifiés)
  show heading.where(level: 1): it => block(width: 100%, below: 1em, above: 1.25em)[
    #set par(justify: false)
    #set text(size: fontsize * 1.1, weight: "bold", font: serif_font)
    #it
  ]
  show heading.where(level: 2): it => block(width: 100%, below: 1em, above: 1.25em)[
    #set par(justify: false)
    #set text(size: fontsize * 1.05)
    #it
  ]
  show heading.where(level: 3): it => block(width: 100%, below: 0.8em, above: 1.2em)[
    #set par(justify: false)
    #set text(size: fontsize, style: "italic")
    #it
  ]

  /// Niveaux 4 et 5 : titres dans le paragraphe
  show heading.where(level: 4): it => box(
    inset: (top: 0em, bottom: 0em, left: 0em, right: 1em),
    text(size: 1em, weight: "bold", it),
  )
  show heading.where(level: 5): it => box(
    inset: (top: 0em, bottom: 0em, left: 0em, right: 1em),
    text(size: 1em, weight: "bold", style: "italic", it),
  )

  //// Encadrés, figures et citations

  // Les callouts référençables sont enveloppés dans un `figure`, dont le bloc
  // n'est pas sécable : un encadré long refusait alors de se répartir sur
  // deux pages. On rend sécables les figures de type callout.
  //
  // Les graphiques et les tableaux, eux, sont précédés d'`espacement_flottant` et suivis de 1,5em.
  // L'espacement est posé par un bloc enveloppant, et non par un `set block`
  // sur la figure : celui-ci vaudrait aussi pour les blocs intérieurs, et
  // écarterait la légende de son contenu.
  show figure: it => {
    if type(it.kind) == str and it.kind.starts-with("quarto-callout") {
      set block(breakable: true)
      it
    } else {
      block(above: espacement_flottant, below: 1.5em, it)
    }
  }
  show figure.where(kind: table): set block(breakable: true)
  show figure.where(kind: "quarto-float-tbl"): set block(breakable: true)
  show figure.where(kind: "quarto-float-apptbl"): set block(breakable: true)

  // Légendes des graphiques et des tableaux
  //
  // Alignées à gauche (et non centrées, comme le veut le défaut de typst),
  // avec l'appel « Graphique 3 : » en gras et le libellé en romain.
  //
  // Le deux-points est précédé d'une espace fine insécable en français, et
  // d'aucune espace en anglais. L'espace est posée par `h()` plutôt que par le
  // caractère U+202F : elle ne dépend alors pas de la fonte, et n'offre aucune
  // occasion de retour à la ligne.
  //
  // Les légendes placées au-dessus du contenu sont `sticky`, pour ne pas
  // rester seules en bas de page. `cap-location: top` dans _extension.yml les
  // met toutes au-dessus, graphiques compris ; la condition sur `position`
  // n'est là que pour le jour où ce réglage changerait, `sticky` rattachant un
  // bloc à ce qui le suit et non à ce qui le précède.
  //
  // Seules les figures sécables en tirent parti — les tableaux, rendus tels
  // ci-dessus —, une figure insécable emportant déjà sa légende avec elle.
  show figure.caption: it => block(
    width: 100%,
    sticky: it.position == top,
    {
      set par(justify: false)
      set align(left)
      // Pas de numérotation (figure non référençable) : il n'y a pas d'appel
      // à composer, seul le libellé est rendu.
      if it.numbering != none {
        text(weight: "bold", {
          it.supplement
          [ ]
          context it.counter.display(it.numbering)
          tr(language, h(0.16em), none)
          [:]
        })
        [ ]
      }
      it.body
    },
  )

  // Bandeau de titre des encadrés (seuls blocs à porter `below: 0pt`) :
  // en gras, et `sticky` pour qu'il ne reste pas seul en bas de page.
  // La règle est posée ici, et non dans la règle `show figure` ci-dessus,
  // afin de couvrir aussi les encadrés sans référence croisée, qui ne sont
  // pas enveloppés dans un `figure`. `sticky: false` dans le sélecteur évite
  // que la règle ne s'applique à son propre résultat (récursion infinie).
  show block.where(below: 0pt, sticky: false): b => {
    let f = b.fields()
    let inner = f.remove("body")
    if f.at("below", default: none) != none { f.below = f.below.abs }
    block(..f, sticky: true, text(weight: "bold", inner))
  }

  // Citations en bloc : retrait des deux côtés, encadrées par de grands
  // guillemets. Ne concerne que les blocs `>` (`quote(block: true)`),
  // pas les citations en ligne.
  show quote.where(block: true): it => block(
    width: 100%,
    above: 1.4em,
    below: 1.4em,
    inset: (left: 1.5em, right: 1.5em),
    grid(
      columns: (auto, 1fr),
      column-gutter: 0.5em,
      align: (left + top, left + top),
      // `top-edge`/`bottom-edge` sur la ligne de base : les guillemets ne
      // comptent pas dans la hauteur, ils ne déforment donc ni une citation
      // d'une seule ligne ni la dernière ligne d'une longue citation.
      text(size: 2.5em, fill: ife2, font: serif_font, top-edge: "baseline", bottom-edge: "baseline", baseline: 0.72em)[“],
      {
        set text(size: 0.95em, fill: grey1)
        // Le guillemet fermant est placé à la suite du texte, et non dans une
        // colonne de la grille : il suit ainsi le dernier mot et reste sur la
        // bonne page quand la citation se répartit sur plusieurs pages.
        it.body
        h(0.15em)
        text(size: 2.5em, fill: ife2, font: serif_font, top-edge: "baseline", bottom-edge: "baseline", baseline: 0.5em)[”]
      },
    ),
  )

  ///// TABLE DES MATIÈRES — sur sa propre page, si `toc: true` dans le yaml

  // Pas de couverture : le billet commence en page 1, ou après la table des
  // matières si elle est demandée.
  if toc {
    v(2cm)
    text(titre_toc, size: 18pt, weight: "bold", font: serif_font, fill: ife2)
    v(1em)
    outline(title: none, depth: toc_depth, indent: toc_indent)
    pagebreak()
  }

  ///// TEXTE PRINCIPAL

  // Repère du début du texte principal : l'entête particulière (nº du billet
  // et date de publication) se pose sur cette page, quel que soit le nombre de
  // pages occupées par la table des matières.
  [#metadata("start") <ofce-main-start>]

  //// Bandeau du haut : mention « Blog » et numéro, logos

  // À gauche, le logo de l'institut et celui de Sciences Po ; à droite,
  // « Blog » suivi du carré portant le numéro, l'année en dessous.
  //
  // Le carré, l'année et la mention reprennent les cotes de la couverture du
  // document de travail et du Policy Brief, mesurées depuis les bords de la
  // page : carré de 2 cm contre le bord droit, à 1,5 cm du haut ; mention à
  // 2,25 cm du bord droit et à 2 cm du haut ; année sous le carré. Les cotes
  // sont ramenées ici à la zone de texte de la première page (marge haute de
  // 3 cm, marge extérieure — à droite sur une page impaire — de 2,5 cm).
  let marge_haute = 3cm
  let marge_droite = 2.5cm
  let annee_bandeau = annee_doc(year, first_publish)

  place(top + right, dx: marge_droite, dy: 1.5cm - marge_haute,
    square(fill: ife1, size: 2cm, align(center + horizon, text(fill: white, size: 1.5cm, numero))))

  if annee_bandeau != none {
    place(top + right, dx: marge_droite, dy: 3.5cm - marge_haute,
      text(fill: ife1, size: 0.9cm, annee_bandeau))
  }

  place(top + right, dx: marge_droite - 2.25cm, dy: 2cm - marge_haute,
    text(fill: gray, size: 1cm, weight: "bold", font: serif_font, style: "italic", "Blog"))

  // Logos à la hauteur du carré, légèrement sortis dans la marge de gauche.
  place(top + left, dx: -1.5cm, dy: 1.5cm - marge_haute,
    stack(
      dir: ttb,
      spacing: 0.25cm,
      image(chemin_logo(fiche.logo), height: hauteur_logo_premiere),
      image(chemin_logo("sciencespo.png"), height: hauteur_sciencespo),
    ))

  //// Titre, sous-titre, auteurs et dates

  // Place laissée aux éléments posés ci-dessus, qui n'occupent pas de hauteur.
  v(2.5cm)

  // Les titres ne se justifient pas : ils restent au fer à gauche. Couleurs de
  // l'ancienne couverture : titre en bleu, sous-titre en gris.
  block(width: 100%)[
    #set par(justify: false)
    #text(title, size: 20pt, weight: "bold", font: serif_font, fill: ife2)
    #if subtitle != none {
      v(1em)
      text(subtitle, size: 16pt, weight: "semibold", fill: grey1)
    }
  ]

  v(1em)
  text(author_strings.join(", ", last: " & "))

  // Date de publication, et de dernière modification si `date-modified` est
  // renseignée dans le yaml.
  if pretty_date != none or pretty_modified != none {
    v(0.5em)
    text(size: 10pt, fill: grey1, style: "italic")[
      #if pretty_date != none [#tr(language, [Publié le], [Published]) #pretty_date]#if pretty_date != none and pretty_modified != none [ — ]#if pretty_modified != none [#tr(language, [modifié le], [modified]) #pretty_modified]
    ]
  }

  //// Résumé, dans un bandeau gris sous les auteurs

  if abstract != none and abstract != [] {
    v(1.5em)
    // Résumé justifié : c'est un bloc de texte suivi, pas un titre.
    block(fill: grey_encadre, width: 100%, inset: 1em, {
      set par(justify: true)
      text(style: "italic", abstract, size: 10pt)
    })
  }

  //// Corps du billet

  v(2em)

  if cols == 1 {
    doc
  } else {
    columns(cols, gutter: col-gutter, doc)
  }

  //// Citation suggérée, en fin de billet

  // Reprise de la mention « Veuillez citer ce travail comme suit » de la
  // version html. Construite à partir des métadonnées (auteurs, année, titre,
  // nom de la série, numéro du billet), faute d'une référence formatée par
  // citeproc en typst. `citation.container-title` ne remplace le nom de la
  // série que si `institut` n'est pas renseigné. Le titre renvoie à la version
  // en ligne si `stable-url` (ou à défaut `citation.url`) est renseignée.
  if authors != none and authors.len() > 0 and title != none and title != [] {
    let auteurs = authors.map(a => [#a.name]).join(", ", last: " & ")
    let revue = if institut == none and citation != none and citation.container-title != "" {
      citation.container-title
    } else {
      serie_blog(language, fiche.sigle)
    }
    let titre_cite = if url_stable != none { link(url_stable)[#title] } else { title }
    let annee_cite = annee_doc(year, first_publish)

    // Le bloc reste entier : l'intitulé ne se sépare pas de la référence.
    block(above: 3em, breakable: false, width: 100%, {
      text(weight: "bold", font: serif_font, size: 10pt, fill: ife2)[#tr(language, [Veuillez citer ce travail comme suit : ], [For attribution, please cite this work as: ])]
      block(width: 100%, fill: white, stroke: 0.5pt + grey2, radius: 2pt, inset: 0.75em,
        text(size: 9pt)[
          #set par(justify: false)
          #auteurs#if annee_cite != none [ (#annee_cite)]. #tr(language, [«~#titre_cite~»], [“#titre_cite”]), #emph(revue)#if number != none and number != [] [#tr(language, [, nº #number], [, no. #number])].
        ])
    })
  }

  //// Rédaction du blog

  v(1em)
  text(size: 9pt, fill: grey1, tr(language, redaction_fr, redaction_en))
}
