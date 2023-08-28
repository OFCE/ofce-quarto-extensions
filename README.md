# Comment utiliser les templates quarto OFCE?
 

## Installer pour un nouveau document 
Vous pouvez utiliser ce template pour créer un document de travail OFCE. Pour ce faire, taper la commande suivante dans le terminal: 


`quarto use template ofce/ofce-quarto-extension`

Cela installera l'extension et créera un fichier `qmd` ainsi qu'une bibliographie `references.bib` qui pourront servir de base de rédaction. 

## Installer pour un document existant 

Vous pouvez également utiliser ce template pour un projet Quarto déjà existant. Depuis le `Rproject` ou son dossier directeur, exécuter la commande suivante dans le terminal:

`quarto add ofce/ofce-quarto-extension`

## Usage

Pour retenir ce format, vous pouvez utiliser le format `names ofce-html`. par exemple:

quarto render article.qmd --to ofce-html

ou dans le document `yaml`

`format:
  ofce-html: default
  `

 Vous pouvez prévisualiser le résultat final d'un document de travail OFCE en format html et pdf à l'adresse ![suivante](https://github.com/OFCE/CharteGraphique/blob/main/Templates/WorkingPaper/Working%20Paper.pdf)
