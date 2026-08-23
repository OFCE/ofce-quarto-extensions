# Plan: "staged / not yet published" marker in the `wp` format templates

Status: **draft, not implemented** — proposed template changes only; needs
visual/design review (especially the PDF and Typst title-page positioning)
before merging.

## Context

This is the `ofce-quarto-extensions` half of a cross-repo change. The other
half — a central WP registry (`ofceweb/wp-registry`) that authorizes which
`{annee, wp}` number a given repo may publish under — is designed in
`ofceweb`'s plan file `plans/2026-08-21-1611-plan-wp-central-registry.md`.
Summary of the relevant decisions from that plan, copied here so this
document is self-contained:

- **Every WP repo is either "staged" or "published."** Staged means the
  repo's `{annee, wp}` isn't (yet) confirmed by a matching entry in the
  central registry — this covers both a plain pre-registration draft and a
  WP whose registration PR is still pending admin approval. Published means
  a registry entry confirms the match.
- **Staging is hosted on GitHub Pages, not FTP.** No FTP secrets are
  touched, so a staged WP repo needn't be inside the `ofce` GitHub
  organisation. Only a *published* WP is deployed to the numbered
  `ofce.fr/wp/{annee}/{wp}/` path over FTP, which does require `ofce`-org
  membership.
- **`annee`/`wp` are resolved from the registry, not local config.**
  `ofceweb::render_wp()` fetches `registry.json`, matches the local repo's
  `source-repo` against it, and only sets `annee`/`wp` metadata when a
  `type: "repo"` entry confirms the match. A staged render therefore has
  **no `annee`/`wp` value at all** — templates cannot assume these are
  merely "not yet decided small integers," they may be genuinely absent.
- **A single boolean drives the banner:** `render_wp()` passes
  `metadata = list(stage = TRUE/FALSE)` into `quarto::quarto_render()`. This
  is the one new piece of document metadata every `wp-*` template needs to
  react to.
- **Encryption of staged output is optional** (staticrypt, opt-in per repo)
  — irrelevant to the templates themselves, mentioned only for completeness.

**What this plan covers:** how `wp-html`, `wp-pdf`, and `wp-typst`
(`_extensions/wp/`) should visibly mark output as "staged" when
`stage = true`, and how they should degrade gracefully when `wp`/`annee`
are absent (which, per the design above, is now a normal and expected state
for a staged document, not just a transient one before `setup_wp()` is
run).

## Metadata contract

| Field | Type | Set when | Notes |
|---|---|---|---|
| `stage` | boolean | Always passed by `render_wp()` going forward | `true` → staged/unregistered; `false` → confirmed published. Absent (older `ofceweb` versions, or a render invoked outside `render_wp()`) is treated identically to `false` by every `$if(stage)$`/`stage: false` default below — **no template change here should require every existing WP repo to immediately re-render**, i.e. this must be additive/backward compatible. |
| `wp`, `annee` | integer | Only when `stage = false` | Existing fields, already used pervasively (`toc.html`, PDF header/title page, Typst title page). Templates that currently assume these are always present (see "Existing gaps found" below) need a guard added. |

No new fields are proposed in `_extension.yml`'s `common:` defaults — `stage`
follows the same "just check `$if(stage)$`, treat unset as falsy" pattern
already used for `draft`/`published` in `html/title-metadata.html`, so no
extension-level default declaration is needed.

## Proposed banner text

French (default `lang: fr`): **"Version provisoire — non publiée comme document de travail OFCE."**
English: **"Draft version — not yet published as an OFCE working paper."**

Placeholder wording — not signed off; flagged as an explicit open question
below since this is user-facing copy an OFCE admin should approve, not an
engineering decision.

## Existing gaps found while drafting this (independent of `stage`)

Two spots assume `wp`/`annee` are always present, which was previously safe
(no repo would deploy without them) but is no longer true now that a staged
render legitimately has neither:

- `pdf/before-body.tex` lines 32–35: draws the "n°/année" box unconditionally
  from `$wp$`/`$annee$`, with no `$if(wp)$` guard (unlike `html/toc.html`,
  which already guards this with `$if(wp)$`).
- `typst/typst-template.typ`'s `title-page()`: `number` is placed into the
  top-right square unconditionally (no guard at all).

Both need a fallback branch regardless of the `stage` banner work, since
today they'd silently render an empty box for a staged document.

## Draft changes by format

### HTML (`_extensions/wp/html/`)

**`title-block.html`** — add a visible banner as the very first element,
before the title:

```diff
 <header id="title-block-header" class="quarto-title-block default">
+  $if(stage)$
+  <div class="wp-stage-banner" role="alert">
+    $if(french)$
+    Version provisoire — non publiée comme document de travail OFCE.
+    $else$
+    Draft version — not yet published as an OFCE working paper.
+    $endif$
+  </div>
+  $endif$
   <div class="quarto-title">
     $if(title)$
     <h1 class="title">$title$</h1>
```

**`toc.html`** — replace the numbered-WP badge with a "staged" variant when
there's no `wp` (closes the "Existing gaps" item above and shows the same
message in the sidebar):

```diff
-  $if(wp)$ <p class="wp">
+  $if(wp)$ <p class="wp">
     $if(french)$
       Document de travail<br>de l'
       <img src="_extensions/ofce/ofce/img/ofce.png" width = "30" height="15" style="margin:0px -4px">
       &nbsp;n°$annee$-$wp$</p>
     $else$
       <img src="_extensions/ofce/ofce/img/ofce.png" width = "30" height="15" style="margin:0px -4px 0px 0px">
       &nbsp;working paper<br>
       n°$annee$-$wp$</p>
     $endif$
+  $elseif(stage)$
+    <p class="wp wp-stage">
+    $if(french)$
+      Version provisoire<br>(non publiée)</p>
+    $else$
+      Draft version<br>(unpublished)</p>
+    $endif$
   $endif$
```

**`wp.scss`** — add styling for the new classes (colors/exact styling are a
starting proposal, not final):

```scss
.wp-stage-banner {
  background-color: #fdf0d5;
  border-left: 4px solid #e67e22;
  color: #7a4a00;
  font-weight: 600;
  padding: 0.5em 1em;
  margin-bottom: 0.75em;
}

.wp-stage {
  font-size: 0.875em !important;
  color: #b36a00 !important;
}
```

### PDF (`_extensions/wp/pdf/`, LaTeX/XeLaTeX)

**`before-title.tex`** — extend the existing `draft`-only watermark to also
cover `stage`, mutually exclusive (only one `\usepackage{draftwatermark}`
call can be active per document, so this must stay an `if/elseif`, not two
independent `if`s):

```diff
-$if(draft)$
-\usepackage[stamp,color=red!10]{draftwatermark}
-$endif$
+$if(draft)$
+\usepackage[stamp,color=red!10]{draftwatermark}
+\SetWatermarkText{BROUILLON}
+$elseif(stage)$
+\usepackage[stamp,color=orange!15]{draftwatermark}
+\SetWatermarkText{VERSION PROVISOIRE}
+\SetWatermarkFontSize{4cm}
+$endif$
```

Also guard the running header, which today unconditionally reads
`$annee$-$wp$` (would render as a bare "Document de travail n°-" when both
are empty):

```diff
-\rehead{Document de travail n°$annee$-$wp$}
+$if(wp)$
+\rehead{Document de travail n°$annee$-$wp$}
+$else$
+\rehead{Version provisoire — non publiée}
+$endif$
```

**`before-body.tex`** — the title-page badge box (closes the "Existing
gaps" item above). **Coordinates below are a first pass, copied/adapted
from the existing TikZ block — they have not been visually verified against
a rendered PDF and should be checked before merging:**

```diff
   \draw [thick,black](-5.75,-13) -- (-5.75,13);
+  $if(wp)$
   \draw [color = white, fill=ofcepbbleu] (8.7,11.4) rectangle (10.45,13.15);
   \draw [color = white, fill=ofcepbbleu, very thick] (8.75-.5,11.25-.5) rectangle (8.75+.6,11.25+.6);
   \node [anchor = east] at (11-0.7,13-0.7){\textcolor{white}{\huge\textbf{$wp$}}};
   \node [anchor = east] at (10-0.74,12-0.67){\textcolor{white}{\textbf{$annee$}}};
+  $else$
+  \draw [color = white, fill=orange!60!black] (7.7,11.4) rectangle (10.45,13.15);
+  \node [anchor = east] at (10-0.35,12.6-0.35){\textcolor{white}{\bfseries\footnotesize VERSION}};
+  \node [anchor = east] at (10-0.35,12.0-0.35){\textcolor{white}{\bfseries\footnotesize PROVISOIRE}};
+  $endif$
```

### Typst (`_extensions/wp/typst/`)

**`typst-show.typ`** — pass `stage` through to both template functions:

```diff
 #show: body => title-page(
   title: [$title$],
   email: "mailto: student@youraddress.com",
   subtitle: [$subtitle$],$if(by-author)$
   ...
   number:[$wp$],
+$if(stage)$
+  stage: true,
+$endif$

 $if(date)$
```

```diff
 #show: doc => preprint(
 $if(title)$
   title: [$title$],
 $endif$
   number:[$wp$],
+$if(stage)$
+  stage: true,
+$endif$
 $if(running-head)$
```

**`typst-template.typ`** — `title-page()` gains a `stage: false` parameter
and branches the top-right badge (closes the other "Existing gaps" item):

```diff
 #let title-page(
   title:[],
   subtitle:[],
   authors: none, email:[],
   first_publish: none,
   abstract: none, year: none,
   number:[],
+  stage: false,
   language: "fr",
   body) = {
```

```diff
-  place(top+right ,dy:-2cm,dx: marge ,
-        square(fill: ife1, size: 2cm,align(center+horizon,text(fill: white,size: 1.5cm,number)))
-      )
+  place(top+right ,dy:-2cm,dx: marge ,
+        square(
+          fill: if stage { rgb("#B36A00") } else { ife1 },
+          size: 2cm,
+          align(center+horizon,
+            text(fill: white,
+                 size: if stage { 0.5cm } else { 1.5cm },
+                 if stage { "PROVISOIRE" } else { number })
+          )
+        )
+      )
```

`preprint()` gains the same `stage: false` parameter and branches the
page-3 running header (the only place `number`/`pretty_date` are shown
there):

```diff
 #let preprint(
   title: none,
   ...
   number: none,
+  stage: false,
   bibliography-title: "Références",
```

```diff
       context if here().page() == 3 {
-
         grid(
         columns: (1fr, 1fr),
-        align(left+ bottom)[#text([Document de travail OFCE nº #number\ publié le #pretty_date], style: "italic")],
+        align(left+ bottom)[
+          #text(
+            if stage {
+              [Version provisoire — non publiée]
+            } else {
+              [Document de travail OFCE nº #number\ publié le #pretty_date]
+            },
+            style: "italic"
+          )
+        ],
         align(right + bottom)[#image("/_extensions/ofce/ofce/img/ofce.png", width: 1cm) ]
         )
```

## Open questions

1. **Banner/watermark wording** (proposed above) needs sign-off — this is
   user-facing OFCE branding copy, not an engineering call.
2. **PDF title-page TikZ coordinates** for the staged badge are a first
   guess adapted from the existing box; need a rendered-PDF check before
   merging (font size, box width for the two-line "VERSION / PROVISOIRE"
   text may not fit as cleanly as the single short `$wp$` number does).
3. **Colour choice** (`orange`/`#B36A00`-family, distinct from the existing
   `draftwatermark` red used for plain Quarto `draft`) is provisional —
   should probably be confirmed against OFCE's brand palette
   (`_extensions/ofce/`) rather than picked ad hoc here.
4. **Interaction with `draft`.** Quarto's own `draft` metadata (already
   handled today, e.g. the red watermark in `before-title.tex`) is a
   different concept from `stage` (registry-authorization state) — a
   document could in principle have `draft: true` *and* `stage: true`
   simultaneously. The PDF change above makes these mutually exclusive at
   the watermark level (`if/elseif`, `draft` wins) since only one
   `draftwatermark` package load is possible; HTML and Typst don't have
   that constraint and could show both banners if ever both are true. Worth
   deciding whether that's desired or whether `stage` should imply/absorb
   `draft` instead.
5. **Backward compatibility check.** Needs a smoke-render of an existing WP
   repo (numbered, no `stage` metadata set) across all three formats to
   confirm nothing regresses when `stage` is simply absent, before this is
   merged — not yet done as part of this draft.

## Not in scope here

- The `ofceweb`-side change that computes and passes `stage`
  (`render_wp()`'s registry-fetch/match logic) — tracked in `ofceweb`'s own
  plan file, not duplicated here.
- Any change to `_extensions/ofce/` (the shared base extension) — this
  plan only touches `_extensions/wp/`.
