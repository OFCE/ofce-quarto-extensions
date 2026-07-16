
/// NOTE OFCE — typst template
#import "@preview/icu-datetime:0.1.2": fmt-datetime, fmt-date

///// STYLE ELEMENTS

  // Colour definition
  #let grey0 =  rgb("#030303")
  #let grey1 =  rgb("#6B6B6B")
  #let grey2 =  rgb("#A6A6A6")
  #let grey3 =  rgb("#D6D6D6")
  #let scpored = rgb("#e6142d")
  #let scpodarkred = rgb("#770C19")

  // Font definition
  #let main_title_font = "Open Sans"
  #let serif_font = "Open Sans"


#let note(
  title: none,
  subtitle: none,
  authors: none,
  abstract: none,
  first_publish: none,
  number: none,
  language: "fr",
  leading: 0.6em,
  spacing: 1em,
  first-line-indent: 0cm,
  linkcolor: rgb(0, 0, 0),
  paper: "a4",
  region: "FR",
  font: ("Open Sans", "Arial"),
  fontsize: 10pt,
  section-numbering: none,
  bibliography-title: "Références",
  bibliography-style: "apa",
  cols: 1,
  col-gutter: 4.2%,
  doc,
) = {

  // Date formatting
  let main_date = if first_publish != none { first_publish.text } else { none }

  let pretty_date = if main_date != none {
    let date_decomp = main_date.split("-")
    let year_fp = int(date_decomp.at(0))
    let month_fp = int(date_decomp.at(1))
    let day_fp = int(date_decomp.at(2))
    let date_formatted = datetime(year: year_fp, month: month_fp, day: day_fp)
    fmt-date(date_formatted, length: "long", locale: language)
  }

  // Link / cite colours
  show link: set text(fill: linkcolor)
  show cite: set text(fill: linkcolor)
 show figure.where(kind: "quarto-float-apptbl"): set block(breakable: true)
 show figure.where(kind: table): set block(breakable: true)
 
  set bibliography(title: bibliography-title, style: bibliography-style)

  // Page settings — header alternates page numbers on subsequent pages
  set page(
    paper: paper,
    margin: (inside: 2.5cm, outside: 2.5cm, top: 2.5cm, bottom: 2.5cm),
    numbering: none,
    footer: none,
    header-ascent: 40%,
    header:
      context if here().page() == 1 {
        // No header on the title page
      } else {
        let pn = counter(page).display()
        if calc.even(here().page()) {
          align(left)[#text(pn, size: 9pt, fill: grey1)]
        } else {
          align(right)[#text(pn, size: 9pt, fill: grey1)]
        }
        v(-0.4em)
        line(start: (0cm, 0cm), end: (100%, 0cm),
          stroke: (thickness: 0.5pt, paint: grey1))
      },
  )

  // Paragraph and text settings
  set par(
    justify: true,
    leading: leading,
    first-line-indent: first-line-indent,
    spacing: spacing,
  )

  set text(
    region: region,
    font: font,
    size: fontsize,
    lang: language,
  )

  set heading(numbering: section-numbering)
  show heading.where(level: 1): it => block(width: 100%, below: 1em, above: 1.25em)[
    #set text(size: fontsize*1.3, weight: "bold", fill: scpored)
    #it
  ]
  show heading.where(level: 2): it => block(width: 100%, below: 1em, above: 1.25em)[
    #set text(size: fontsize*1.15, weight: "bold")
    #it
  ]
  show heading.where(level: 3): it => block(width: 100%, below: 0.8em, above: 1.2em)[
    #set text(size: fontsize*1.05, style: "italic")
    #it
  ]
  show heading.where(level: 4): it => box(
    inset: (top: 0em, bottom: 0em, left: 0em, right: 1em),
    text(size: 1em, weight: "bold", it),
  )
  show heading.where(level: 5): it => box(
    inset: (top: 0em, bottom: 0em, left: 0em, right: 1em),
    text(size: 1em, weight: "bold", style: "italic", it),
  )

  /* ---------------- Title page ---------------- */

  // Top row: logo top-left, date top-right
  grid(
    columns: (1fr, 1fr),
    column-gutter: 1em,
    align(left + top)[
      #image("/_extensions/ofce/ofce-website/img/ofce_m.png", width: 3cm)
    ],
    align(right + top)[
      #if pretty_date != none {
        text(pretty_date, size: 10pt, fill: grey1)
      }
      #if number != none and number != [] {
        linebreak()
        text([Note nº #number], size: 10pt, fill: grey1, style: "italic")
      }
    ],
  )

  v(1.5cm)

  // Title and subtitle
  text(title, size: 22pt, weight: "bold", fill: scpored, font: main_title_font)
  if subtitle != none {
    v(0.5em)
    block(text(subtitle, size: 14pt, fill: grey1, font: main_title_font))
  }

  v(1.5em)

  // Authors — right justified
  if authors != none {
    align(right)[
      #grid(
        rows: authors.len(),
        row-gutter: 0.4em,
        ..authors.map(author => align(right)[
          #text(author.name, weight: "bold", size: 10pt)
          #if author.affiliation != none and author.affiliation != [] [
            , #text(author.affiliation, style: "italic", size: 10pt)
          ]
        ])
      )
    ]
  }

  v(1.5em)

  // Abstract
  if abstract != none and abstract != [] {
    block(
      fill: rgb("#F2F2F2"),
      inset: 1em,
      width: 100%,
      text(abstract, style: "italic", size: 9.5pt),
    )
  }

  v(1em)
  line(start: (0cm, 0cm), end: (100%, 0cm),
    stroke: (thickness: 0.5pt, paint: grey1))
  v(1em)

  // Body
  if cols == 1 {
    doc
  } else {
    columns(cols, gutter: col-gutter, doc)
  }
}

// Remove gridlines from tables
#set table(
  inset: 6pt,
  stroke: none,
)
