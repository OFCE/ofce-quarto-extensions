
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

  // Font definition
  #let main_title_font = "Helvetica"
  #let serif_font = "Palatino"

#let title-page(title:[],subtitle:[], authors: none, email:[], first_publish: datetime.today(), 
abstract: none, year:[],
number:[], language: "fr",
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
 



  // Date formatting 

  let main_date = first_publish.text
  let date_decomp = main_date.split("-")

  let year_fp = int(date_decomp.at(0))
  let month_fp = int(date_decomp.at(1))
  let day_fp = int(date_decomp.at(2))

  let date_formatted = datetime(year: year_fp, month: month_fp, day: day_fp)

  let pretty_date = fmt-date(date_formatted, length: "long", locale: language)



  set page(margin: (top: marge, rest: marge))
  
  set text(font: main_title_font, size: 14pt)
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
        
        // #text(date_decomp, size: 14pt)


      ]/// end align
    ) /// end box, 
  )





  //// 3. Publishing date And Issue number

  place(top+right ,dy:-2cm,dx: marge ,
        square(fill: colourtype, size: 2cm,align(center+horizon,text(fill: white,size: 1cm,number)))
      )
  
  place(top+right ,dy:0cm,dx: marge ,
        text(fill: colourtype, size: 0.9cm,text(year))
      )
  
  place(top + right, dx:+1.25cm,dy:-1.5cm, align(horizon,text(fill: gray ,size:2cm,font: serif_font,style:"italic","Blog")))


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


#import "_extensions/ofce/blog/typsttemplate/typst-core.typ": preprint
