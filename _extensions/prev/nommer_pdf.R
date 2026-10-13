# Nom des pdf de la prévision : ife-ofce-prev<prev>-<dossier>-<fichier>.pdf
#
# Quarto nomme le pdf d'après le qmd (fiches/espagne.qmd -> fiches/espagne.pdf)
# et ne sait pas composer un nom à partir du dossier : ce script, lancé après
# chaque rendu (`project: post-render` de _quarto.yml), renomme les pdf qui
# viennent d'être produits et reporte le nouveau nom dans le lien « Autres
# formats » des pages html, dont le libellé (« Typst (prev) ») devient
# « Version pdf ».
#
# Seuls les fichiers du rendu en cours sont touchés : quarto en donne la liste
# dans QUARTO_PROJECT_OUTPUT_FILES. `<prev>` est la clé `prev` de _quarto.yml.

sortie <- Sys.getenv("QUARTO_PROJECT_OUTPUT_DIR")
fichiers <- strsplit(Sys.getenv("QUARTO_PROJECT_OUTPUT_FILES"), "\n", fixed = TRUE)[[1]]
fichiers <- fichiers[nzchar(fichiers) & file.exists(fichiers)]
if (!nzchar(sortie) || length(fichiers) == 0) quit(save = "no")

sortie <- normalizePath(sortie)
fichiers <- normalizePath(fichiers)

config <- readLines("_quarto.yml", encoding = "UTF-8", warn = FALSE)
prev <- gsub("^prev:\\s*|['\"]|\\s+$", "", grep("^prev:", config, value = TRUE)[1])
prefixe <- paste0("ife-ofce-prev", prev, "-")

# Nom du pdf d'un chapitre, d'après son dossier (relatif au site) et son nom.
nom_pdf <- function(dossier, base) {
  relatif <- substring(dossier, nchar(sortie) + 2)
  morceaux <- c(strsplit(relatif, "/", fixed = TRUE)[[1]], base)
  paste0(prefixe, paste(morceaux[nzchar(morceaux)], collapse = "-"), ".pdf")
}

deja_nomme <- function(fichier) startsWith(basename(fichier), prefixe)

## Les pdf
for (pdf in fichiers[grepl("\\.pdf$", fichiers) & !deja_nomme(fichiers)]) {
  base <- tools::file_path_sans_ext(basename(pdf))
  file.rename(pdf, file.path(dirname(pdf), nom_pdf(dirname(pdf), base)))
}

## Le lien vers le pdf, dans les pages html
bloc <- '(?s)<div class="quarto-alternate-formats">.*?</div>'
lien <- 'href="([^"/]+)\\.pdf"([^>]*)>(<i[^>]*></i>)?[^<]*</a>'

for (html in fichiers[grepl("\\.html$", fichiers)]) {
  page <- paste(readLines(html, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  position <- regexpr(bloc, page, perl = TRUE)
  if (position == -1) next
  formats <- regmatches(page, position)
  base <- regmatches(formats, regexec(lien, formats, perl = TRUE))[[1]][2]
  if (is.na(base) || startsWith(base, prefixe)) next
  nouveau <- sub(
    lien,
    paste0('href="', nom_pdf(dirname(html), base), '"\\2>\\3Version pdf</a>'),
    formats,
    perl = TRUE
  )
  regmatches(page, position) <- nouveau
  writeLines(page, html, useBytes = TRUE)
}
