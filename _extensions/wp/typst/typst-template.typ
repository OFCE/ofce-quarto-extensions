
/// TITLE PAGE template partial
#import "@preview/icu-datetime:0.1.2": fmt-datetime, fmt-date

///// STYLE ELEMENTS FOR TYPST TEMPLATES


  // Colour definition

  #let grey0 =  rgb("#030303")
  #let grey1 =  rgb("#6B6B6B")
  #let grey2 =  rgb("#A6A6A6")
  #let grey3 =  rgb("#D6D6D6")
  #let scpored = rgb("#e6142d")
  #let scpodarkred = rgb("#770C19")
  #let colourtype = rgb("#EEC900")
  #let ife1 = rgb("#7D0000")
  #let ife2 = rgb("#21606E")
  #let ifegrey = rgb("#DDDBDB")

  // Font definition
  #let main_title_font = "Arimo"
  #let serif_font = "Merriweather"

 // Pseudo-notes des encadrés
//
// Quarto rend les blocs `::: aside` par la fonction `note()` du paquet
// marginalia, qui les renvoie dans la marge — donc hors de l'encadré.
// Comme ces blocs servent ici de notes de bas d'encadré (appels numérotés
// à la main dans le texte), on redéfinit `note` pour qu'elle compose son
// contenu sur place : sous un filet, en plus petit, à l'endroit où l'aside
// est écrit — c'est-à-dire à la fin de l'encadré qui le contient.
// Cette définition masque celle importée plus haut.
#let note(..args) = {
  let body = args.pos().at(0, default: [])
  block(width: 100%, above: 1em, below: 0.2em,
    {
      line(length: 30%, stroke: (thickness: 0.4pt, paint: grey1))
      v(0.4em, weak: true)
      set text(size: 0.8em, fill: grey1)
      body
    })
}

 // Callout settings

#let callout(
body: [],
title: "Callout",
background_color: none,
icon: none,
icon_color: none,
body_background_color: white) = {
  let _bg = rgb("#EDEAEA")
  let _ic = rgb("#EDEAEA")
  let _bbg =  rgb("#EDEAEA")
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
      block(
        breakable: true,
        fill: _bg,
        width: 100%,
        inset: 8pt)[#if icon != none [#text(_ic, weight: 900)[#icon] ]#title]) +
      if(body != []){
        block(
          breakable: true,
          inset: 1pt,
          width: 100%,
          block(breakable: true, fill: _bbg, width: 100%, inset: 8pt, align(left, body)))
      }
    )
}


// Met en forme la date de première publication.
// Renvoie `none` si aucune date n'est fournie, et "????" si la valeur
// fournie n'est pas une date ISO (AAAA-MM-JJ) valide — plutôt que de
// faire échouer la compilation.
#let fmt_first_publish(first_publish, language) = {
  if first_publish == none { return none }

  let raw = if first_publish.has("text") { first_publish.text } else { "" }
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


#let title-page(
  title:[],
  subtitle:[],
  authors: none, email:[],
  first_publish: none,
  abstract: none, year: none,
  thanks: none,
  site-url: none,
  thanks-title-fr: "Remerciements",
  thanks-title-en: "Acknowledgements",
  number:[],
  draft: false,
  doc_version: none,
  language: "fr",
  body) = {

  // « (v0) » accolé à la mention de version préliminaire, si `version` est
  // renseignée dans le yaml ; rien sinon.
  let version_suffix = if doc_version != none and doc_version != [] {
    [ (#doc_version)]
  } else {
    []
  }

  let marge = 3.5cm
  let ph = 29.7cm // page height for a4
  let pw = 21.0cm // page width for a4
  let logo_column = 4cm
  let lc_space = 0.75cm
  let line_x = -0.5cm + (logo_column - marge) + lc_space*2

  let grey0 =  rgb("#030303")
  let grey1 =  rgb("#6B6B6B")
  let grey2 =  rgb("#A6A6A6")
  let grey3 =  rgb("#D6D6D6")
  let scpored = rgb("#e6142d")
  let scpodarkred = rgb("#770C19")
  let colourtype = rgb("#EEC900")
  let ife1 = rgb("#7D0000")
  let ife2 = rgb("#21606E")
  let ifegrey = rgb("#DDDBDB")

  // Font definition
  let main_title_font = "Arimo"
  let serif_font = "Merriweather"

// Author block

let authorblock()={
if authors != none {
    let nrows = calc.min(authors.len(), 3)
    grid(
      rows: nrows,
      row-gutter: 0.5em,
      ..authors.map(author =>
          align(left)[
            #text(author.name, weight: "bold",size: 11pt), #text(author.affiliation,style:"italic",size: 11pt)
          ]
      )
    )

  }

}




  // Date formatting



  let pretty_date = fmt_first_publish(first_publish, language)

    // Page formatting

  // Quarto pose un `set page(numbering: "1")` global qui régit les pages 1 et 2
  // (celui de `preprint` ne prend effet qu'à partir de la page 3) : on le neutralise
  // ici pour la couverture et la page de résumé.
  set page(margin: (top: marge, rest: marge), numbering: none)

  set text(font: main_title_font, size: 14pt)
  set heading(numbering: "1.1.1")

  // place(top + right, text(blue,"+")) // position tester

  /////// 1. logo position and line

  place(top + left, dx: -marge+lc_space,dy:-2cm,
        image("/_extensions/ofce/ofce/img/ofce_m.png", width: logo_column*0.7)
        )

  place(bottom + left, dx: -marge+lc_space,dy: 2cm,
        image("/_extensions/ofce/ofce/img/sciencespo.png", width: logo_column*0.7)
      )
  place(left,
        line(start: (line_x, 0cm), end: (line_x,  ph - 2*marge),
  stroke: (thickness: 1.25pt, paint: grey1)))

  //// 2. Title Position



  place(dx: 2cm,dy: 4cm,
    box(width: 13cm,
      align(horizon + left)[
        #text(size: 24pt, title, fill: ife2, weight: "bold", font: serif_font)
        #v(1em)
        #text(subtitle,fill: grey1)
        #v(2em)

        #authorblock()

        // Lien vers la version en ligne du document (si `site-url` est
        // renseignée dans le yaml). Pandoc échappe « // » en « /\/ » lors de
        // l'interpolation : on rétablit l'URL avant d'en faire un lien.
        #if site-url != none and site-url != "" [
          #let url = site-url.replace("/\\/", "//")
          #v(1.5em)
          #text(size: 10pt, fill: grey1)[
            Version en ligne du document :
            #link(url)[#text(fill: ife2, url)]
          ]
        ]

        // #text(date_decomp, size: 14pt)


      ]/// end align
    ) /// end box,
  )





  //// 3. Publishing date And Issue number

  if not draft {
  place(top+right ,dy:-2cm,dx: marge ,
        square(fill: ife1, size: 2cm,align(center+horizon,text(fill: white,size: 1.5cm,number)))
      )

  // L'année n'est affichée que si `annee` est renseignée dans le yaml ;
  // aucune déduction à partir de la date de publication.
  if year != none and year != [] {
  place(top+right ,dy:0cm,dx: marge ,
        text(fill: ife1, size: 0.9cm, year)
      )
  }
  } else {
  // Brouillon : bandeau rouge sous « Document de travail », à la place
  // du numéro et de l'année.
  place(top+right ,dy:0cm,dx: marge ,
        box(fill: ife1, inset: 8pt, radius: 2pt,
          text(fill: white,size: 20pt, weight: "bold")[Version préliminaire#version_suffix — non publiée])
      )
  place(top+right ,dy:1.2cm,dx: marge - 3cm ,
        box(fill: white, inset: 8pt, radius: 2pt,
          text(fill: ife1,size: 14pt, weight: "bold","NE PAS DIFFUSER NE PAS CITER"))
      )
  }

  place(top + right, dx:+1.25cm,dy:-1.5cm, align(horizon,text(fill: gray ,size:1cm,weight: "bold", font: serif_font,style:"italic","Document de travail")))


  place(bottom + right, dx: 1.5cm,

  [
    #text({
      if(first_publish != none){
        [Première publication : ]
        }
        }, weight: "semibold", size: 10pt

        )
    #text({
      if(first_publish != none){
        [ #pretty_date \ ]
        }
        }, size: 10pt

        )


  ]

  )
  //// 4. Remerciements (facultatif)

  // Encadré facultatif : remerciements.
  if thanks != none and thanks != [] {
    place(bottom, dx: 2cm, dy: -0.5*line_x,
    clearance: 4cm,
      box(fill: rgb("#EDEAEA"), baseline: 100%,width: 13cm,inset: 0.5em)[
        #set par(leading: 0.35em)
        // Titre toujours en français pour l'instant ; la sélection par langue
        // attend le remaniement du template.
        #text(thanks-title-fr,size: 10pt, fill: ife2, weight: "bold" , font: serif_font)
        #linebreak()
        #text(thanks,size: 10pt, fill: grey1, style: "italic")
        ]
      )
  }

  //// 5. Page 2 : résumé
  pagebreak()
  set page(fill: none, margin: auto)

  // Ancre invisible : sans contenu, le `set page` de `preprint` s'appliquerait
  // à la page 2 elle-même et y ferait réapparaître le numéro.
  box()

  if abstract != none and abstract != [] {
    v(2cm)
    text("Résumé", font: serif_font, size: 18pt, weight: "bold", fill: ife2)
    v(0.5em)
    block(fill: white, width: 100%, inset: 1em,
      text( abstract, size: 10pt)
      )
  }

  // Coordonnées, en bas à gauche de la page 2
  place(bottom + left,
    text(size: 9pt, font: main_title_font, fill: black)[
      #text(weight: "bold", font: serif_font, fill: ife2)[Contact] \
      IFE \
      10 place de Catalogne \
      75014 Paris, FRANCE \
      Tel : +33 1 44 18 54 24 \
      #link("https://www.ofce.fr")
    ]
  )





  /// start
  //pagebreak()
  body
}


#import "@preview/icu-datetime:0.1.2": fmt-datetime, fmt-date


///// STYLE ELEMENTS FOR TYPST TEMPLATES

  // Colour definition

  // #let grey0 =  rgb("#030303")
  // #let grey1 =  rgb("#6B6B6B")
  // #let grey2 =  rgb("#A6A6A6")
  // #let grey3 =  rgb("#D6D6D6")
  // #let scpored = rgb("#e6142d")
  // #let scpodarkred = rgb("#770C19")
  // #let colourtype = rgb("#EEC900")

  // // Font definition
  // #let main_title_font = "Open sans"
  // #let serif_font = "Open sans"


/// CORE TEXT


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
  first_publish: none,
  leading: 0.6em,
  spacing: 1em,
  first-line-indent: 0cm,
  linkcolor: rgb(0, 0, 0),
  paper: "a4",
  language:"fr",
  region: "US",
  font: ("Times", "Times New Roman", "Arial"),
  fontsize: 11pt,
  section-numbering: none,
  toc: false,
  toc_title: "Table des matières",
  toc_depth: none,
  toc_indent: 1.5em,
  number: none,
  year: none,
  draft: false,
  doc_version: none,
  bibliography-title: "Références",
  bibliography-style: "apa",
  cols: 1,
  col-gutter: 4.2%,
  doc,
) = {

  /* Document settings */

  let grey0 =  rgb("#030303")
  let grey1 =  rgb("#6B6B6B")
  let grey2 =  rgb("#A6A6A6")
  let grey3 =  rgb("#D6D6D6")
  let scpored = rgb("#e6142d")
  let scpodarkred = rgb("#770C19")
  let colourtype = rgb("#EEC900")

  // Font definition
  let main_title_font = "Arimo"
  let serif_font = "Merriweather"


  // Date formatting

  let pretty_date = fmt_first_publish(first_publish, language)



  // Set link and cite colors
  show link: set text(fill: linkcolor)
  show cite: set text(fill: linkcolor)

 show figure.where(kind: "quarto-float-apptbl"): set block(breakable: true)
 // Les callouts référençables sont enveloppés dans un `figure`, dont le bloc
 // n'est pas sécable : un encadré long refusait alors de se répartir sur
 // deux pages. On rend sécables les figures de type callout.
 // Bandeau de titre des encadrés (seuls blocs à porter `below: 0pt`) :
 // en gras, et `sticky` pour qu'il ne reste pas seul en bas de page.
 // La règle est posée ici, et non dans la règle `show figure` ci-dessous,
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
     text(size: 2.5em, fill: ife2, font: serif_font,
          top-edge: "baseline", bottom-edge: "baseline", baseline: 0.72em)[“],
     {
       set text(size: 0.95em, fill: grey1)
       // Le guillemet fermant est placé à la suite du texte, et non dans une
       // colonne de la grille : il suit ainsi le dernier mot et reste sur la
       // bonne page quand la citation se répartit sur plusieurs pages.
       it.body
       h(0.15em)
       text(size: 2.5em, fill: ife2, font: serif_font,
            top-edge: "baseline", bottom-edge: "baseline", baseline: 0.5em)[”]
     },
   ),
 )

 show figure: it => {
   if type(it.kind) == str and it.kind.starts-with("quarto-callout") {
     set block(breakable: true)
     it
   } else {
     it
   }
 }
 show figure.where(kind: table): set block(breakable: true)
 show figure.where(kind: "quarto-float-tbl"): set block(breakable: true)

  // Allow custom title for bibliography section
  set bibliography(title: bibliography-title, style: bibliography-style, )

  // Format author strings here, so can use in author note
  let author_strings = ()
  if authors != none {
    for a in authors{
      let author_string = [#a.name]
      author_strings.push(author_string)
    }

  }

  // « (v0) » accolé à la mention de version préliminaire, si `version` est
  // renseignée dans le yaml ; rien sinon.
  let version_suffix = if doc_version != none and doc_version != [] {
    [ (#doc_version)]
  } else {
    []
  }

  // Numéro du document de travail, « ?? » tant que `wp` n'est pas renseigné.
  let numero = if number != none and number != [] {
    number
  } else {
    [??]
  }

  // Année, « ???? » tant que `annee` n'est pas renseignée.
  let annee = if year != none and year != [] {
    year
  } else {
    [????]
  }

  // Page settings (including headers & footers)
  set page(
    paper: paper,
    margin: (inside: 3.5cm, outside: 2.5cm, rest: 3cm),
    numbering: "1",
    header-ascent: 50%,
    header:

        // Première page du texte principal (p. 3 sans table des matières).
              context {
              let repere = query(<ofce-main-start>)
              let debut = if repere.len() > 0 { repere.first().location().page() } else { 3 }
              if here().page() == debut {

          grid(
          columns: (1fr, 1fr),
          align(left+ bottom)[#text(if draft [Document de travail IFE \ #text(fill: ife1, weight: "bold")[Version préliminaire#version_suffix — non publiée]] else [Document de travail OFCE nº #numero\ publié le #pretty_date], style: "italic")],
          align(right + bottom)[#image("/_extensions/ofce/ofce/img/ofce.png", width: 1cm) ]

          )


        } else if here().page() < debut {

          // Page(s) de table des matières : entête sans numéro de page.
          grid(
            columns: (1fr, auto),
            align(left)[#text(if draft [Document de travail #text(fill: ife1, weight: "bold")[Version préliminaire#version_suffix]] else [Document de travail nº #numero - #annee], style: "italic")],
            align(right)[#image("/_extensions/ofce/ofce/img/ofce.png", width: 1cm) ]
          )

        line(start: (0cm, -0.5em), end: (15cm,  -0.5em),
  stroke: (thickness: 0.25pt, paint: grey1))

        } else {

          if(calc.even(here().page())){

            grid(
            columns: (1fr, 1fr),
            align(left + bottom)[#counter(page).display()],
            align(right + bottom)[#image("/_extensions/ofce/ofce/img/ofce.png", width: 1cm) ]

          )

          } else {
          grid(
            // `auto` pour le numéro : la mention de version garde toute la
            // largeur restante et tient sur une seule ligne.
            columns: (1fr, auto),
            align(left)[#text(if draft [Document de travail #text(fill: ife1, weight: "bold")[Version préliminaire#version_suffix]] else [Document de travail nº #numero - #annee], style: "italic")],
            align(right)[#counter(page).display()]
          )


          }

          // Page >1 header has running head and page number

        line(start: (0cm, -0.5em), end: (15cm,  -0.5em),
  stroke: (thickness: 0.25pt, paint: grey1))
        }
        }
    ,
    footer-descent: 24pt,
    footer:

              context if here().page() == 3 {

        } else {

        }

  )

  // Paragraph settings
  set par(
    justify: true,
    leading: leading,
    first-line-indent: first-line-indent,
    spacing: spacing
  )


  // Text settings
  set text(
    region: region,
    font: font,
    size: fontsize
  )

  // Headers
  set heading(
    numbering: section-numbering
  )
  // Level 1 headers
  show heading.where(
    level: 1
  ): it => block(width: 100%, below: 1em, above: 1.25em)[
    #set text(size: fontsize*1.3, weight: "bold", font: serif_font)
    #it
  ]
  // Level 2 headers
  show heading.where(
    level: 2
  ): it => block(width: 100%, below: 1em, above: 1.25em)[
    #set text(size: fontsize*1.05)
    #it
  ]
  // Level 3 headers
  show heading.where(
    level: 3
  ): it => block(width: 100%, below: 0.8em, above: 1.2em)[
    #set text(size: fontsize, style: "italic")
    #it
  ]
  // Level 4 headers are in paragraph
  show heading.where(
    level: 4
  ): it => box(
    inset: (top: 0em, bottom: 0em, left: 0em, right: 1em),
    text(size: 1em, weight: "bold", it)
  )
  // Level 5 headers are in paragraph
  show heading.where(
    level: 5
  ): it => box(
    inset: (top: 0em, bottom: 0em, left: 0em, right: 1em),
    text(size: 1em, weight: "bold", style: "italic", it)
  )


pagebreak()

// Table des matières, sur sa propre page, si `toc: true` dans le yaml.
// Le texte principal reprend donc après elle.
if toc {
  v(2cm)
  text(toc_title, size: 18pt, weight: "bold", font: serif_font, fill: ife2)
  v(1em)
  outline(title: none, depth: toc_depth, indent: toc_indent)
  pagebreak()
}

  /* Content */

// Repère du début du texte principal : l'entête particulière (nº de document
// et date de publication) se pose sur cette page, quel que soit le nombre de
// pages occupées par la table des matières.
[#metadata("start") <ofce-main-start>]

v(4cm)



text(title, size: 24pt, weight: "bold", font: serif_font)

if subtitle != none {
v(1em)
text(subtitle, size: 16pt, weight: "semibold")
}


v(1em)

text(author_strings.join(", ", last: " & "))

  // Separate content a bit from front matter
  v(4em)

  // Show document content with cols if specified
  if cols == 1 {
    doc
  } else {
    columns(
      cols,
      gutter: col-gutter,
      doc
    )
  }

v(4cm)


// text("Fin" , size: 14pt, weight: "bold")
}

// Remove gridlines from tables
#set table(
  inset: 6pt,
  stroke: none
)
