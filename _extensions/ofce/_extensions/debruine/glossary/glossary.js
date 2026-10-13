document.addEventListener("DOMContentLoaded", function() {
  const glossaryButtons = document.querySelectorAll("button.glossary");

  glossaryButtons.forEach(button => {
    const definition = button.getAttribute("title");
    const term = button.textContent.trim();
    button.removeAttribute("title"); // Désactiver le tooltip natif

    const tooltip = document.createElement("span");
    tooltip.className = "glossary-tooltip";

    // Titre : icône glossaire + terme défini
    const title = document.createElement("span");
    title.className = "glossary-tooltip-title";
    title.appendChild(document.createTextNode("📖 Glossaire — "));
    const termEl = document.createElement("em");
    termEl.textContent = term;
    title.appendChild(termEl);

    tooltip.appendChild(title);
    tooltip.appendChild(document.createTextNode(definition));

    button.appendChild(tooltip);
  });

  // Fonction pour repositionner les tooltips
  function repositionTooltips() {
    const tooltips = document.querySelectorAll(".glossary-tooltip");
    
    tooltips.forEach(tooltip => {
      const button = tooltip.parentElement;
      const rect = button.getBoundingClientRect();
      const tooltipRect = tooltip.getBoundingClientRect();
      
      // Réinitialiser les classes
      tooltip.classList.remove("glossary-tooltip-bottom");
      
      // Si le tooltip dépasse le haut de la fenêtre (y < 0)
      if (tooltipRect.top < 0) {
        tooltip.classList.add("glossary-tooltip-bottom");
      }
    });
  }

  // Repositionner au survol
  document.addEventListener("mouseover", function(e) {
    if (e.target.closest("button.glossary")) {
      repositionTooltips();
    }
  });
});
