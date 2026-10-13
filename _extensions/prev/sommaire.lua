-- Sommaire commun aux pdf de la prévision.
--
-- La liste des chapitres est celle de la barre latérale du site
-- (`website.sidebar.contents` de _quarto.yml) : mêmes sections, même ordre,
-- mêmes libellés. Le filtre la transmet au gabarit typst dans la métadonnée
-- `sommaire-sections`, en marquant le chapitre en cours de rendu (`courant`).
-- L'adresse du site publié est transmise elle aussi (`url-prevision`), pour la
-- mention « Version en ligne de la prévision » de la couverture.
--
-- Quarto ne transmet pas la clé `website` aux filtres : _quarto.yml est donc
-- relu ici. Faute d'analyseur yaml en lua, le fichier est confié à pandoc comme
-- bloc de métadonnées d'un document markdown vide.

local function lire_yaml(chemin)
  local f = io.open(chemin, "r")
  if f == nil then return nil end
  local contenu = f:read("a")
  f:close()
  -- Les balises html des libellés (« <b>France</b> ») sont retirées avant lecture.
  contenu = contenu:gsub("</?%a+>", "")
  local ok, doc = pcall(pandoc.read, "---\n" .. contenu .. "\n---\n", "markdown-smart")
  if not ok then
    quarto.log.warning("sommaire : lecture impossible de " .. chemin)
    return nil
  end
  return doc.meta
end

local function texte(valeur)
  if valeur == nil then return nil end
  return pandoc.utils.stringify(valeur)
end

-- Chaîne typst entre guillemets, insérée telle quelle dans le gabarit : passée
-- comme texte, pandoc y échapperait « // ».
local function chaine_typst(s)
  return pandoc.MetaInlines({
    pandoc.RawInline("typst", '"' .. s:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"')
  })
end

-- Adresse du site publié (`site-url` de _quarto.yml, `site-path` de
-- _quarto-publish.yml), quel que soit le profil du rendu.
local function racine_du_site(projet, metas)
  local url, chemin = nil, nil
  for _, m in ipairs(metas) do
    if m.website ~= nil then
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

local function adresse(racine, cible)
  if cible:match("^https?://") then return cible end
  if racine == nil then return nil end
  return racine .. cible:gsub("^/+", ""):gsub("%.qmd$", ".html")
end

function Meta(meta)
  if not quarto.doc.is_format("typst") then return nil end
  if quarto.project.directory == nil then return nil end

  local projet = quarto.project.directory
  local config = lire_yaml(pandoc.path.join({ projet, "_quarto.yml" }))
  if config == nil or config.website == nil or config.website.sidebar == nil then return nil end

  -- Les liens du pdf pointent vers le site publié, y compris quand le rendu
  -- se fait sous le profil staging.
  local metas = { config }
  local publication = lire_yaml(pandoc.path.join({ projet, "_quarto-publish.yml" }))
  if publication ~= nil then table.insert(metas, publication) end
  local racine = racine_du_site(projet, metas)
  if racine ~= nil then meta["url-prevision"] = chaine_typst(racine) end
  if meta.sommaire == false then return meta end

  local page = pandoc.path.make_relative(quarto.doc.input_file, projet)

  -- Sections de la barre latérale laissées hors du sommaire (`sommaire-exclure`
  -- de _extension.yml), désignées par leur titre.
  local exclues = {}
  for _, titre in ipairs(meta["sommaire-exclure"] or {}) do
    exclues[texte(titre)] = true
  end

  local sections = pandoc.List()
  for _, section in ipairs(config.website.sidebar.contents or {}) do
    local chapitres = pandoc.List()
    local contenu = exclues[texte(section.section)] and {} or (section.contents or {})
    for _, item in ipairs(contenu) do
      local fichier = texte(item.file)
      local cible = fichier or texte(item.href)
      if cible ~= nil then
        local url = adresse(racine, cible)
        chapitres:insert({
          titre = item.text or pandoc.MetaInlines({ pandoc.Str(cible) }),
          url = url and chaine_typst(url) or nil,
          courant = fichier == page,
        })
      end
    end
    if #chapitres > 0 then
      sections:insert({ titre = section.section, chapitres = chapitres })
    end
  end

  if #sections > 0 then meta["sommaire-sections"] = sections end
  return meta
end
