-- Detect draft status based on website configuration
-- Sets stage-draft to true if website.site-path contains "staging"

function Pandoc(doc)
  local site_path = quarto.project.config["website"]["site-path"]
  
  if site_path and string.find(site_path, "staging") then
    doc.meta["stage-draft"] = true
  end
  
  return doc
end
