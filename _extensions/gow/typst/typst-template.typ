/// SINGLE PAGE BLOG template
#import "@preview/icu-datetime:0.1.2": fmt-datetime, fmt-date

// Colour definition
#let grey0 = rgb("#030303")
#let grey1 = rgb("#6B6B6B")
#let grey2 = rgb("#A6A6A6")
#let grey3 = rgb("#E6E1D8")
#let scpored = rgb("#e6142d")
#let scpodarkred = rgb("#770C19")
#let colourtype = rgb("#DB2E43")

// Font definition
#let main_title_font = "Open sans"
#let serif_font = "Open sans"

#let single-page-blog(
  title: [],
  subtitle: [],
  authors: none,
  extrarefs: none,
  abstract: none,
  first_publish: none,
  year: [],
  number: none,
  language: "fr",
  font: ("Times", "Times New Roman", "Arial"),
  fontsize: 11pt,
  linkcolor: rgb(0, 0, 0),
  linky: none,
  scalepic: 1,
  voir_aussi: none,
  doc,
) = {


  let marge = 0.5cm
  let pw = 29.7cm // page height for a4
  let ph = 21.0cm // page width for a4
  let logo_column = 0cm
  let lc_space = 0.5cm
  let line_x = 0cm + (logo_column - marge) + lc_space*2



  // Date formatting
  let main_date = if first_publish != none {
    first_publish.text
  } else {
    none
  }

  let pretty_date = if main_date != none {
    let date_decomp = main_date.split("-")
    let year_fp = int(date_decomp.at(0))
    let month_fp = int(date_decomp.at(1))
    let day_fp = int(date_decomp.at(2))
    let date_formatted = datetime(year: year_fp, month: month_fp, day: day_fp)
    fmt-date(date_formatted, length: "long", locale: language)
  }
  
   let year_doc = if main_date != none {
    let date_decomp = main_date.split("-")
    str(int(date_decomp.at(0)))
  }
  
 // Function to extract content from divs with a specific class
let extract-div(body, class-name) = {
  let result = ()
  
  // This searches through the body for blocks with your class
  // Note: The exact implementation depends on how Quarto structures the output
  for element in body.children {
    if element.func() == block and element.has("class") {
      if class-name in element.at("class", default: ()) {
        result.push(element.body)
      }
    }
  }
  
  result.join()
}

let myCustomBlock = extract-div(doc, "myCustomBlock")

  // Page settings
  set page(
    paper: "a4",
    flipped: true,
    margin: (left: 2cm, right: 2cm, top: 0.5cm, bottom: 0.5cm),
    numbering: none,
  )

  // Text settings
  set text(
    font: main_title_font,
    size: fontsize
  )

  // Paragraph settings
  set par(
    justify: false,
    leading: 0.6em,
    spacing: 1em
  )

  // Set link colors
  show link: set text(fill: linkcolor)
  show cite: set text(fill: linkcolor)

  // Heading styles
  show heading.where(level: 1): it => block(width: 100%, below: 0.8em, above: 1em)[
    #set text(size: fontsize * 1.1, weight: "bold")
    #it
  ]
  
  show heading.where(level: 2): it => block(width: 100%, below: 0.8em, above: 1em)[
    #set text(size: fontsize * 1.05)
    #it
  ]

  // Header with logos
  
  
  place(top + left, dx: 0cm,dy: 0cm,
        image("/_extensions/ofce/blog/ofce_m.png", width: 2cm)
        )
  place(top + left, dx: 0cm,dy: 0.75cm,
        image("/_extensions/ofce/blog/sciencespo.png", width: 2cm)
        )
      
  place(top+right ,dy:-0cm,dx: marge ,
        square(fill: colourtype, size: 1cm,align(center+horizon,text(fill: white,size: 0.8cm,number)))
        )
  place(top+right ,dy:1.05cm,dx: marge ,
        text(fill: colourtype, size: 0.43cm,align(right+horizon,text(year_doc)))
        )
  place(top + right, dx:-0.5cm, dy:0.25cm, align(horizon,
        text(fill: gray ,size:0.9cm,font: main_title_font,style:"italic","L'ÉcoGraphe "))
        )

  

  
  

  v(5em)

  // Title section
  block(
    text(size: 16pt, weight: "bold", fill: scpored, title)
  )


  v(1em)

  // Authors
  if authors != none {
    for author in authors {
      text(author.name, weight: "bold", size: 11pt)
      if author.affiliation != none and author.affiliation != "" {
        text(", ", size: 11pt)
        text(author.affiliation, style: "italic", size: 11pt)
      }
      linebreak()
    }
  }


  // v(1em)

 let plop = 73 * scalepic * 1%
  // Main document content
    grid(
    columns: (plop, 1fr),
    column-gutter: 0.5em,
    
    // Column 1
    [
      // Graph
      #doc
    ],
    
    // Column 2
    [
    
    /// Publication date
  
      #if pretty_date != none {
      text(size: 10pt, fill: grey1, [Publié le #pretty_date])
      }
  
    /// Abstract in colored box if provided
    #v(0.5em)
    
      #if abstract != none and abstract != [] {
      block(
          fill: grey3,
          inset: 1em,
          radius: 3pt,
          width: 100%,
          text( size: 10pt, abstract)
        )
      }
      
/// Website url 

#if linky != none {
  v(0.5em)
  
  // Extract text content from linky if it's content type
  let url_str = if type(linky) == content {
    // Convert content to plain text by getting all text nodes
    let extract_text(c) = {
      if type(c) == str {
        c
      } else if c.has("text") {
        c.text
      } else if c.has("children") {
        c.children.map(extract_text).join("")
      } else if c.has("body") {
        extract_text(c.body)
      } else {
        ""
      }
    }
    extract_text(linky)
  } else {
    linky
  }
  
  align(left, text(size: 10pt, fill: scpored)[Lien vers le billet sur le site de l'OFCE : #link(url_str)[#url_str]])
}  

  #if extrarefs != none {
    v(0.5em)
    text(size: 10pt, fill: scpored)[Voir aussi :]
    v(0.3em)
    for ref in extrarefs {
      text(size: 9pt)[• #link(ref.lien)[#ref.texte]]
      linebreak()
    }
  }

    ]
  )


}

// Table styling
#set table(
  inset: 6pt,
  stroke: none
)