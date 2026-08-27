-- Detect draft status based on project configuration
-- Sets stage-draft to true if a top-level "draft" key is set in _quarto.yml

function Pandoc(doc)
  local config = quarto.project and quarto.project.config
  local draft = config and config["draft"]

  if draft then
    doc.meta["stage-draft"] = true
  end

  return doc
end
