-- Sort le div `.analyse` du corps du document pour le poser dans la colonne de
-- droite du gabarit typst, après le résumé.
--
-- Le corps d'un ecograph contient le graphique puis, dans un div `.analyse`, le
-- texte d'accompagnement. Le gabarit met le corps restant à gauche ; le contenu
-- du div est passé au gabarit par la métadonnée `analyse`.
--
-- Le filtre est posé après `quarto` dans la liste des filtres : le contenu du
-- div a donc déjà été traité (shortcodes, renvois, citations).
--
-- En html le div reste en place, dans le fil du billet.

if FORMAT ~= "typst" then
  return {}
end

function Pandoc(doc)
  local analyse = pandoc.List()
  local blocks = pandoc.List()

  for _, blk in ipairs(doc.blocks) do
    if blk.t == "Div" and blk.classes:includes("analyse") then
      analyse:extend(blk.content)
    else
      blocks:insert(blk)
    end
  end

  if #analyse > 0 then
    doc.meta.analyse = pandoc.MetaBlocks(analyse)
    doc.blocks = blocks
  end

  return doc
end
