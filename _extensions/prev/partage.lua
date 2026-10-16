-- Barre de partage des pages html de la prévision, comme sur le blog : lien
-- vers le pdf du chapitre puis boutons des réseaux sociaux, sous le titre.
--
-- Rien à écrire dans les qmd : l'adresse partagée est celle de la page sur le
-- site publié, le texte est son titre, et le pdf est celui du chapitre
-- (ife-ofce-prev<prev>-<dossier>-<fichier>.pdf). La barre est placée en tête
-- de page, ou dans la div `::: {#socialshare}` si la page en contient une.
--
-- Ce fichier sert deux fois dans _quarto.yml :
--   * comme filtre (`filters`), il pose la barre de partage ;
--   * comme script d'avant rendu (`project: pre-render`), il écrit dans le yaml
--     de chaque chapitre le nom de son pdf (`output-file` du format prev-typst).
--     Quarto nomme sinon le pdf d'après le qmd (fiches/espagne.qmd ->
--     fiches/espagne.pdf) et un filtre ne peut pas changer le nom du fichier
--     produit. Voir la fin du fichier.
--
-- Les pages de liste (`listing`) n'ont pas de barre. La clé `share`, dans
-- _quarto.yml ou dans le yaml d'une page, reste disponible pour les exceptions :
--   share: false            pas de barre sur la page
--   share:
--     pdf: false            pas de lien pdf (ou `pdf: <adresse>` pour l'imposer)
--     reddit: false         retire un réseau (linkedin, facebook, mastodon,
--                           bluesky, reddit, twitter, email)
--     permalink: <adresse>  adresse partagée
--     description: <texte>  texte du partage
--
-- Les icônes sont celles de Bootstrap Icons, que quarto charge sur toutes les
-- pages du site.

local function texte(valeur)
  if valeur == nil then return nil end
  return pandoc.utils.stringify(valeur)
end

-- Titre en texte seul. Le filtre nbsp remplace « Comptes : » par du html brut
-- (une span insécable), que stringify laisserait de côté.
local function texte_du_titre(valeur)
  if valeur == nil then return nil end
  if pandoc.utils.type(valeur) ~= "Inlines" then return texte(valeur) end
  return texte(valeur:walk({
    RawInline = function(el)
      if el.format ~= "html" then return nil end
      return pandoc.Str((el.text:gsub("<[^>]*>", ""):gsub("&thinsp;", "\u{00a0}"):gsub("&nbsp;", "\u{00a0}")))
    end
  }))
end

-- Nom du pdf d'un chapitre, d'après son chemin dans le site sans extension
-- (« fiches/espagne ») ; `prev` est la clé `prev` de _quarto.yml.
local function nom_pdf(prev, sans_ext)
  return "ife-ofce-prev" .. prev .. "-" .. sans_ext:gsub("[/\\]", "-") .. ".pdf"
end

local function lire(chemin)
  local f = io.open(chemin, "r")
  if f == nil then return nil end
  local contenu = f:read("a")
  f:close()
  return contenu
end

-- Même lecture de _quarto.yml que sommaire.lua : quarto ne transmet pas la clé
-- `website` aux filtres.
local function lire_yaml(chemin)
  local contenu = lire(chemin)
  if contenu == nil then return nil end
  contenu = contenu:gsub("</?%a+>", "")
  local ok, doc = pcall(pandoc.read, "---\n" .. contenu .. "\n---\n", "markdown-smart")
  if not ok then
    io.stderr:write("partage : lecture impossible de " .. chemin .. "\n")
    return nil
  end
  return doc.meta
end

-- Adresse du site publié (`site-url` de _quarto.yml, `site-path` de
-- _quarto-publish.yml), quel que soit le profil du rendu.
local function racine_du_site(projet)
  local url, chemin = nil, nil
  for _, fichier in ipairs({ "_quarto.yml", "_quarto-publish.yml" }) do
    local m = lire_yaml(pandoc.path.join({ projet, fichier }))
    if m ~= nil and m.website ~= nil then
      url = texte(m.website["site-url"]) or url
      chemin = texte(m.website["site-path"]) or chemin
    end
  end
  if url == nil then return nil end
  url = url:gsub("/+$", "")
  if chemin ~= nil and chemin ~= "" then
    url = url .. "/" .. chemin:gsub("^/+", ""):gsub("/+$", "")
  end
  return url .. "/"
end

-- La page a un pdf si le projet rend le format prev-typst et que son propre
-- yaml ne restreint pas les formats (`format: ofce-html` seul, par exemple).
local function a_un_pdf(projet, source)
  local config = lire(pandoc.path.join({ projet, "_quarto.yml" })) or ""
  if not config:find("\n  prev%-typst:") then return false end
  local page = lire(source) or ""
  local entete = page:match("^%-%-%-\r?\n(.-)\n%-%-%-") or ""
  if ("\n" .. entete):find("\nformat:") and not entete:find("prev%-typst") then return false end
  return true
end

local function url_encode(s)
  return (s:gsub("[^A-Za-z0-9%-%._~]", function(c) return string.format("%%%02X", string.byte(c)) end))
end

local function attribut(s)
  return (s:gsub("&", "&amp;"):gsub('"', "&quot;"):gsub("<", "&lt;"))
end

local function bouton(classe, icone, libelle, href, extra)
  return '<a href="' .. attribut(href) .. '" class="' .. classe .. '" title="' .. libelle ..
    '" aria-label="' .. libelle .. '" ' .. (extra or 'target="_blank" rel="noopener"') ..
    '><i class="bi bi-' .. icone .. '"></i></a>'
end

local function barre(meta)
  local share = meta.share
  if share == false then return nil end
  if share == nil and meta.listing ~= nil then return nil end
  if type(share) ~= "table" then share = {} end
  local function actif(cle) return share[cle] ~= false end

  local projet = quarto.project.directory
  local source = quarto.doc.input_file
  if projet == nil or source == nil then return nil end
  local relatif = pandoc.path.make_relative(source, projet)
  local sans_ext = pandoc.path.split_extension(relatif)

  local url = texte(share.permalink)
  if url == nil then
    local racine = racine_du_site(projet)
    if racine == nil then return nil end
    -- La page d'accueil d'un dossier se partage sans « index.html ».
    url = racine .. (sans_ext .. ".html"):gsub("index%.html$", "")
  end
  local titre = texte_du_titre(share.description) or texte_du_titre(meta.title) or ""
  local u, t = url_encode(url), url_encode(titre)

  local html = {}

  local pdf = nil
  if type(share.pdf) == "table" then
    pdf = texte(share.pdf)
  elseif actif("pdf") and a_un_pdf(projet, source) then
    -- Le pdf est à côté de la page.
    pdf = nom_pdf(texte(meta.prev) or "", sans_ext)
  end
  if pdf ~= nil then
    table.insert(html, bouton("pdf", "file-earmark-pdf", "Version pdf", pdf, 'download target="_blank"'))
    table.insert(html, '<span class="separateur"></span>')
  end

  if actif("linkedin") then
    table.insert(html, bouton("linkedin", "linkedin", "LinkedIn",
      "https://www.linkedin.com/sharing/share-offsite/?url=" .. u))
  end
  if actif("facebook") then
    table.insert(html, bouton("facebook", "facebook", "Facebook",
      "https://www.facebook.com/sharer.php?u=" .. u))
  end
  if actif("mastodon") then
    -- L'instance mastodon est demandée au clic, comme sur le blog.
    table.insert(html, bouton("mastodon", "mastodon", "Mastodon", "#",
      'target="_blank" rel="noopener" data-partage="' .. attribut(titre .. " " .. url) .. '" ' ..
      'onclick="var i=prompt(\'Instance mastodon ?\');if(!i){return false;}' ..
      'this.href=\'https://\'+i+\'/share?text=\'+encodeURIComponent(this.dataset.partage);"'))
  end
  if actif("bluesky") then
    table.insert(html, bouton("bluesky", "bluesky", "Bluesky",
      "https://bsky.app/intent/compose?text=" .. url_encode(titre .. " " .. url)))
  end
  if actif("reddit") then
    table.insert(html, bouton("reddit", "reddit", "Reddit",
      "https://reddit.com/submit?url=" .. u .. "&title=" .. t))
  end
  if actif("twitter") then
    table.insert(html, bouton("twitter", "twitter-x", "X",
      "https://twitter.com/share?url=" .. u .. "&text=" .. t))
  end
  if actif("email") then
    table.insert(html, bouton("email", "envelope", "Courriel",
      "mailto:?subject=" .. t .. "&body=" .. u))
  end

  if #html == 0 then return nil end
  return pandoc.RawBlock("html", '<div class="social-share">' .. table.concat(html) .. '</div>')
end

function Pandoc(doc)
  -- Lancé comme script d'avant rendu, il n'y a pas de document à traiter.
  if quarto == nil or quarto.doc == nil then return nil end
  if not quarto.doc.is_format("html") then return nil end
  local contenu = barre(doc.meta)
  if contenu == nil then return nil end

  quarto.doc.add_html_dependency({
    name = "prev-partage",
    version = "0.1.0",
    stylesheets = { "partage.css" }
  })

  local place = false
  doc.blocks = doc.blocks:walk({
    Div = function(div)
      if div.identifier == "socialshare" then
        place = true
        div.content = { contenu }
        return div
      end
    end
  })
  if not place then
    doc.blocks:insert(1, pandoc.Div({ contenu }, pandoc.Attr("socialshare")))
  end
  return doc
end

-- Avant le rendu : le nom du pdf est écrit dans le yaml des chapitres, sous la
-- forme
--
--   format:
--     ofce-html: default
--     prev-typst:
--       output-file: ife-ofce-prev2609-fiches-espagne.pdf
--
-- `ofce-html: default` est nécessaire : le `format` d'une page remplace la
-- liste des formats du projet au lieu de s'y ajouter.
--
-- Une page qui a déjà une clé `format` sans prev-typst (l'accueil, la liste des
-- analyses) n'a pas de pdf et n'est pas touchée. Un fichier n'est réécrit que si
-- le nom change : rien ne bouge d'un rendu à l'autre, seulement quand `prev`
-- change ou qu'un chapitre est ajouté ou déplacé.
local function yaml_avec_pdf(entete, nom)
  local ligne = "    output-file: " .. nom
  local e = "\n" .. entete .. "\n"
  if not e:find("\nformat:") then
    return entete .. "\n# nom du pdf du chapitre, écrit par partage.lua avant chaque rendu\n" ..
      "format:\n  ofce-html: default\n  prev-typst:\n" .. ligne
  end
  if not e:find("prev%-typst") then return entete end
  local debut, fin = e:find("\n  prev%-typst:[ \t]*\n")
  if debut == nil then return nil end
  local suite = e:sub(fin + 1)
  if suite:find("^    output%-file:") then
    suite = suite:gsub("^    output%-file:[^\n]*", function() return ligne end, 1)
  else
    suite = ligne .. "\n" .. suite
  end
  return (e:sub(1, fin) .. suite):sub(2, -2)
end

local function nommer_les_pdf(fichiers)
  local projet = pandoc.system.get_working_directory()
  local config = lire_yaml("_quarto.yml")
  local prev = config ~= nil and texte(config.prev) or ""

  for fichier in fichiers:gmatch("[^\r\n]+") do
    local relatif = pandoc.path.is_absolute(fichier) and pandoc.path.make_relative(fichier, projet) or fichier
    local sans_ext, ext = pandoc.path.split_extension(relatif)
    local page = ext == ".qmd" and lire(fichier) or nil
    local avant, entete, apres = nil, nil, nil
    if page ~= nil then
      avant, entete, apres = page:match("^(%-%-%-\r?\n)(.-)(\n%-%-%-[ \t]*\r?\n.*)$")
    end
    if entete ~= nil then
      local nouveau = yaml_avec_pdf(entete, nom_pdf(prev, sans_ext))
      if nouveau == nil then
        io.stderr:write("partage : `prev-typst` de " .. relatif .. " n'est pas sur sa propre ligne, " ..
          "le nom du pdf n'est pas écrit\n")
      elseif nouveau ~= entete then
        local f = assert(io.open(fichier, "w"))
        f:write(avant, nouveau, apres)
        f:close()
        io.stderr:write("partage : nom du pdf écrit dans " .. relatif .. "\n")
      end
    end
  end
end

-- `quarto` n'existe que lorsque le fichier est chargé comme filtre.
local fichiers = os.getenv("QUARTO_PROJECT_INPUT_FILES")
if (quarto == nil or quarto.doc == nil) and fichiers ~= nil and fichiers ~= "" then
  nommer_les_pdf(fichiers)
end
