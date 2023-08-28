# Comment utiliser les templates quarto OFCE?
 

## Écrire un nouvel article
Vous pouvez utiliser ce template pour créer un document de travail OFCE. Pour ce faire, taper la commande suivante dans le terminal: 


`quarto use template ofce/ofce-quarto-extension`

## Installer pour un nouveau document 

Cela installera l'extension et créera un fichier `qmd` ainsi qu'une bibliographie. 
This will install the extension and create an example qmd file and bibiography that you can use as a starting place for your article.
Installation for existing document

Vous pouvez également utiliser ce template pour un projet Quarto déjà existant. Depuis le `Rproject` ou du dossier directeur, executer la commande suivante dans le terminal:



`quarto add ofce/ofce-quarto-extension`

## Usage

Pour utiliser ce format, vous pouvez utiliser le format `names ofce-html`. par exemple:

quarto render article.qmd --to ofce-html

ou dans le document `yaml`

`format:
  ofce-html: default
  `

 Vous pouvez prévisualiser le résultat final d'un document de travail OFCE en format html et pdf à l'adresse ![suivante](https://github.com/OFCE/CharteGraphique/blob/main/Templates/WorkingPaper/Working%20Paper.pdf)
