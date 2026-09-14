# Reference visive riservate del cast

Questa cartella conserva reference visive riservate per la continuità delle
caricature pixel-art del cast. Vive sotto `docs/` perché è materiale sorgente e
di provenienza, non un asset da derivare: non è mai stata, e non deve mai
diventare, un percorso runtime.

- Non sono asset runtime e non devono essere referenziate da scene, script o
  Resource.
- `.gdignore` le tiene fuori dall'import Godot e i tre preset export escludono
  `docs/characters/references/**` (`export_presets.cfg`).
- Conservare i file in `references/<id>/source-<numero>.<estensione>`; registrare
  nel manifest del cast (`assets/art/characters/ASSET-MANIFEST.md`) percorso,
  SHA-256, data di consegna e ruolo `subject reference`.
- Non aggiungere reference da fonti terze né usarle come `edit target`.

Il documento di direzione visuale del personaggio corrispondente è in
[`docs/characters/<id>.md`](../). Il registro dei prompt e delle reference
storiche è in
[`docs/archive/generation-prompts-and-references.md`](../../archive/generation-prompts-and-references.md).

Spostata da `assets/art/characters/references/` il 2 settembre 2026 (PS-084):
nessun contenuto binario è cambiato, solo il percorso.
