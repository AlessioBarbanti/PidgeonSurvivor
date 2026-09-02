# Reference fotografiche del cast

Questa cartella è riservata alle fotografie originali fornite e autorizzate dal
proprietario come reference per le caricature pixel-art del cast. Vive sotto
`docs/` perché è materiale di documentazione e provenienza, non un asset da
derivare: non è mai stata, e non deve mai diventare, un percorso runtime.

- Non sono asset runtime e non devono essere referenziate da scene, script o
  Resource.
- `.gdignore` le tiene fuori dall'import Godot e i tre preset export escludono
  `docs/characters/references/**` (`export_presets.cfg`).
- Conservare i file in `references/<id>/source-<numero>.<estensione>`; registrare
  nel manifest del cast (`assets/art/characters/ASSET-MANIFEST.md`) percorso,
  SHA-256, data di consegna e ruolo `subject reference`.
- Non aggiungere fotografie da fonti terze né usarle per un risultato
  fotorealistico.

Il documento di direzione visuale del personaggio corrispondente è in
[`docs/characters/<id>.md`](../). Il registro dei prompt e delle reference
storiche è in
[`docs/archive/generation-prompts-and-references.md`](../../archive/generation-prompts-and-references.md).

Spostata da `assets/art/characters/references/` il 2 settembre 2026 (PS-084):
nessun contenuto binario è cambiato, solo il percorso.
