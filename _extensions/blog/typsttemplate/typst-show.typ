#let title-page(title:[],subtitle:[], authors: none, email:[], first_publish: none, 
abstract: none, year:[],
number:[],
body) = {
  
  let marge = 3.5cm
  let ph = 29.7cm // page height for a4
  let pw = 21.0cm // page width for a4
  let logo_column = 4cm
  let lc_space = 0.5cm
  let line_x = 0cm + (logo_column - marge) + lc_space*2
  
// Author block

let nrows = calc.min(authors.len(), 3)

let authorblock()={
if authors != none {
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
 

  // Colour definition

  let grey0 =  rgb("#030303")
  let grey1 =  rgb("#6B6B6B")
  let grey2 =  rgb("#A6A6A6")
  let grey3 =  rgb("#D6D6D6")
  let scpored = rgb("#e6142d")
  let scpodarkred = rgb("#770C19")

  set page(margin: (top: marge, rest: marge))
  
  set text(font: "Arial", size: 14pt)
  set heading(numbering: "1.1.1")

  // place(top + right, text(blue,"+")) // position tester
      
  /////// 1. logo position and line

  place(top + left, dx: -marge+lc_space,dy:-2cm,
        image("_extensions/ofce/blog/ofce_m.png", width: logo_column) 
        )
        
  place(bottom + left, dx: -marge+lc_space,dy: 2cm,
        image("_extensions/ofce/blog/sciencespo.png", width: logo_column)
      )
  place(left,
        line(start: (line_x, 0cm), end: (line_x,  ph - 2*marge), 
  stroke: (thickness: 1.25pt, paint: grey1)))

  //// 2. Title Position
  


  place(dx: 2cm,dy: 4cm,
    box(width: 13cm,
      align(horizon + left)[
        #text(size: 24pt, title, fill:  scpored,weight: "bold" )
        #v(1em)
        #text(subtitle,fill: grey1)
        #v(2em)

        #authorblock()
        


      ]/// end align
    ) /// end box, 
  )





  //// 3. Publishing date And Issue number

  place(top+right ,dy:-2cm,dx: marge ,
        square(fill: yellow, size: 2cm,align(center+horizon,text(fill: white,size: 1cm,number)))
      )
   place(top+right ,dy:0cm,dx: marge ,
        text(fill: yellow, size: 0.9cm,text(year))
      )
  place(top + right, dx:+1.25cm,dy:-1.5cm, align(horizon,text(fill: gray,size:2cm,font: "Palatino",style:"italic","Blog")))



place(bottom + right, dx: 1.5cm, 
  text({
    if(first_publish != none){[Première publication : #first_publish \ ] } },
    //if(revision != none){text([Dernière révision : #revision]) }} , 
    size: 11pt
    
     )

  //if(first_publish != none){text([Première publication : #first_publish \ ])}
  //
)

  //// 4. Abstract 

  place(bottom, dx: 2*lc_space + line_x, dy: -1*line_x,
  clearance: 4cm,
    box(fill: grey3, baseline: 100%,width: 13cm,inset: 1em,
      text(style: "italic",abstract,size: 10pt)
      ) 
    ) 

  //// 5. Internal cover page
  pagebreak()
  set page(fill: none, margin: auto)

  align(bottom , text("Rédacteurs en chef : Elliot Aurissergues & Paul Malliet") )



  /// start
  //pagebreak()
  body
}


#show: body => title-page(
  title: [$title$],
  email: "mailto: student@youraddress.com",
  subtitle: [$subtitle$],$if(by-author)$
  authors: (
$for(by-author)$
$if(it.name.literal)$
    ( name: [$it.name.literal$],
      affiliation: [$for(it.affiliations)$$it.name$$sep$, $endfor$],
      email: [$it.email$] ),
$endif$
$endfor$
    ),
$endif$
  abstract: [$description$],
  year: [2024],
  number:[$wp$],
  first_publish:[$date$],
  body
)

#show: doc => preprint(
$if(title)$
  title: [$title$],
$endif$
$if(running-head)$
  running-head: [$running-head$],
$endif$
$if(by-author)$
  authors: (
$for(by-author)$
$if(it.name.literal)$
    ( name: [$it.name.literal$],
      affiliation: [$for(it.affiliations)$$it.id$$sep$, $endfor$],
      $if(it.orcid)$orcid: "https://orcid.org/$it.orcid$",$endif$
      $if(it.email)$email: [$it.email$]$endif$),
$endif$
$endfor$
    ),
$endif$
$if(affiliations)$
  affiliations: (
    $for(affiliations)$(
      id: "$it.id$",
      name: "$it.name$",
      $if(it.department)$department: "$it.department$"$endif$
    ),
    $endfor$
  ),
$endif$
$if(date)$
  date: [$date$],
$endif$
$if(leading)$
  leading: $leading$,
$endif$
$if(branding)$
  branding: "$branding$",
$endif$
$if(spacing)$
  spacing: $spacing$,
$endif$
$if(linkcolor)$
  linkcolor: $linkcolor$,
$endif$
$if(citation)$
  citation: (
    type: "$citation.type$",
    container-title: "$citation.container-title$",
    doi: "$citation.doi$",
    url: "$citation.url$"
  ),
$endif$
$if(authornote)$
  authornote: [$authornote$],
$endif$
$if(lang)$
  lang: "$lang$",
$endif$
$if(region)$
  region: "$region$",
$endif$
$if(abstract)$
  abstract: [$abstract$],
$endif$
$if(keywords)$
  keywords: [$for(keywords)$$it$$sep$, $endfor$],
$endif$
$if(margin)$
  margin: ($for(margin/pairs)$$margin.key$: $margin.value$,$endfor$),
$endif$
$if(papersize)$
  paper: "$papersize$",
$endif$
$if(mainfont)$
  font: ("$mainfont$",),
$endif$
$if(fontsize)$
  fontsize: $fontsize$,
$endif$
$if(section-numbering)$
  section-numbering: "$section-numbering$",
$endif$
$if(toc)$
  toc: $toc$,
$endif$
$if(toc_depth)$
  toc_depth: $toc_depth$,
$endif$
$if(toc_title)$
  toc_title: "$toc_title$",
$endif$
$if(toc_indent)$
  toc_indent: "$toc_indent$",
$endif$
$if(cols)$
  cols: $cols$,
$endif$
$if(col-gutter)$
  col-gutter: $col-gutter$,
$endif$
$if(bibliography-style)$
  bibliography-style: [$bibliography-style$],
$endif$
$if(bibliography-title)$
  bibliography-title: [$bibliography-title$],
$endif$
  doc,
)
