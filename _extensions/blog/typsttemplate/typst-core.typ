
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
  // #let main_title_font = "Helvetica"
  // #let serif_font = "Palatino"


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
  toc_title: "contents",
  toc_depth: none,
  toc_indent: 1.5em,
  number: none, 
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
  let main_title_font = "Helvetica"
  let serif_font = "Palatino"


  let main_date = first_publish.text
  let date_decomp = main_date.split("-")

  let year_fp = int(date_decomp.at(0))
  let month_fp = int(date_decomp.at(1))
  let day_fp = int(date_decomp.at(2))

  let date_formatted = datetime(year: year_fp, month: month_fp, day: day_fp)

  let pretty_date = fmt-date(date_formatted, length: "long", locale: language)




  // Set link and cite colors
  show link: set text(fill: linkcolor)
  show cite: set text(fill: linkcolor)

  // Allow custom title for bibliography section
  set bibliography(title: bibliography-title, style: bibliography-style, )

  // Format author strings here, so can use in author note
  let author_strings = ()
  if authors != none {
    for a in authors {
      let author_string = [
        // Solo manuscripts don't have institutional id
        #a.name#if authors.len() > 1 [#super[#a.affiliation]]#if a.keys().contains("affiliation") {[\*]}
        #if a.keys().contains("orcid") {
            box(
              height: 1em,
              link(
                a.orcid, 
                figure( 
                  image("orcid.svg", height: 0.9em)
                )
              )
            )
          }
        ]
      if a.keys().contains("affiliation") {
        authornote = [\* #a.affiliation\ #authornote]
      }
      author_strings.push(author_string)
    }
  }

  // Page settings (including headers & footers)
  set page(
    paper: paper, 
    margin: (inside: 3.5cm, outside: 2.5cm, rest: 3cm),
    numbering: "1",
    header-ascent: 50%,
    header: locate(
        // Page 3 
        loc => if [#loc.page()] == [3] {
          
          grid(
          columns: (1fr, 1fr),
          align(left+ bottom)[#text([Blog OFCE nº #number\ publié le #pretty_date], style: "italic")],
          align(right + bottom)[#image("../ofce_m.png", width: 1cm) ]

          )

    
        } else {

          if(calc.even(here().page())){
            
            grid(
            columns: (1fr, 1fr),
            align(left + bottom)[#counter(page).display()],
            align(right + bottom)[#image("../ofce_m.png", width: 1cm) ]

          )

          } else {
          grid(
            columns: (1fr, 1fr),
            align(left)[#image("../ofce_m.png", width: 1cm) ],
            align(right)[#counter(page).display()]
          )
          

          }

          // Page >1 header has running head and page number

        line(start: (0cm, -0.5em), end: (15cm,  -0.5em), 
  stroke: (thickness: 0.25pt, paint: grey1))
        }
    ),
    footer-descent: 24pt,
    footer: locate(
        // Page 1 footer has author note
        loc => if [#loc.page()] == [3] {
          [#text(size: 0.85em)[#authornote]]
        } else {
          []
        }
    )
  )
  
  // Paragraph settings
  set par(
    justify: true, 
    leading: leading,
    first-line-indent: first-line-indent
  )
  // Set space between paragraphs
  show par: set block(spacing: spacing)

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
    #set text(size: fontsize*1.1, weight: "bold")
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

  /* Content front matter */

  // let titleblock(
  //   body, 
  //   width: 100%, 
  //   size: 1.5em, 
  //   weight: "bold", 
  //   above: 1em, 
  //   below: 0em
  // ) = [
  //   #align(center)[
  //     #block(width: width, above: above, below: below)[
  //       #text(weight: weight, size: size)[#body]
  //     ]
  //   ]
  // ]

  // if title != none {
  //   titleblock(title)
  // }

  // if authors != none {
  //   titleblock(
  //     weight: "regular", size: 1.25em,
  //     [#author_strings.join(", ", last: " & ")]
  //   )
  // }

  // if affiliations != none {
  //   titleblock(
  //     weight: "regular", size: 1.1em, below: 2em,
  //     for a in affiliations [
  //       #if authors.len() > 1 [#super[#a.id]]#a.name#if a.keys().contains("department") [, #a.department] \
  //     ]
  //   )
  // }
  
  // // Abstract and keywords block
  // block(inset: (top: 2em, bottom: 0em, left: 2.4em, right: 2.4em))[
  //   #set text(size: 0.92em)
  //   #if abstract != none {
  //     abstract
  //   }
  //   #if keywords != none {
  //     [#v(0.4em)#text(style: "italic")[Keywords:] #keywords]
  //   }
  // ]

  // No table of contents because it's a blog
  // if toc {
  //   pagebreak()

  //   let title = if toc_title == none {
  //     auto
  //   } else {
  //     toc_title
  //   }
  //   block(inset: (top: 2em, bottom: 0em, left: 2.4em, right: 2.4em))[
  //     #outline(
  //       title: toc_title,
  //       depth: toc_depth,
  //       indent: toc_indent
  //     )
  //   ]
  // }

pagebreak()


  /* Content */



v(4cm)



text(title, size: 20pt, weight: "bold")

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
