# Direzione visuale — Magno

Riferimento sintetico per la famiglia visiva di Magno, pensato come aiuto per
`.agents/skills/game-art-designer/SKILL.md` (Claude:
`.claude/agents/game-art-designer.md`; Codex:
`.codex/agents/game-art-designer.toml`). Non sostituisce l'ispezione dei
fratelli visivi reali: in caso di conflitto con i master o con
`assets/art/characters/ASSET-MANIFEST.md`, questi ultimi restano autorevoli.
Ruolo gameplay, passiva e abilità attiva restano in
[`docs/characters.md`](../characters.md), non duplicati qui.

## Direzione visuale approvata

"Energumeno tellurico con richiami bovini, posa pesante e onda d'urto che
crepa il terreno." (`docs/characters.md`)

## Silhouette, costume e palette

Uomo energumeno, molto largo e muscoloso, capelli lunghi e barba, passo
pesante. Outfit color terra con piccoli richiami bovini — solo motivi a
corna/emblema, **nessuna anatomia animale**: la prima generazione B18U
introduceva corna e tratti animali sul corpo, rimossi nella correzione finale
perché Magno resta umano (`assets/art/characters/ASSET-MANIFEST.md`, tabella
prompt B18U). Il prompt completo dell'identity pass recuperato da
`img_char_prompts.md` è archiviato in
[`docs/archive/generation-prompts-and-references.md`](../archive/generation-prompts-and-references.md#magno--originale-recuperato).

## Variante Evil

Canotta nera con emblema bovino dorato; posa pesante e accento ambra
tellurico (`evil_magno`, `assets/art/characters/ASSET-MANIFEST.md`, Parte 2).

Grammatica Evil condivisa con tutto il cast: fumo prugna controllato, occhio
magenta-viola luminoso, poche crepe energetiche e rim light personale;
preserva acconciatura, corporatura, colori dell'abito e accessori del
Player.

## Reference fotografica

- `docs/characters/references/magno/source-01.png` — 1 file, ruolo `subject
  reference`, non editing target, mai output fotorealistico; autorizzata dal
  proprietario, archiviata il 2 settembre 2026.

## Master e derivati correnti

| File | Ruolo |
|---|---|
| `assets/art/characters/magno/hd/poses.png` | master HD Player, 3 pose (escluso da import/export) |
| `assets/art/characters/magno/hd/evil_portrait.png` | master HD Evil, ritratto busto (escluso da import/export) |
| `assets/art/characters/magno/hd/portrait.png` | master HD Player, busto approvato PS-068 (escluso da import/export) |
| `assets/art/characters/magno/generated/sprite.png` | striscia runtime 96×32 |
| `assets/art/characters/magno/generated/carousel.png` | ritratto carosello selezione 256×256 |
| `assets/art/characters/magno/generated/portrait.png` | ritratto Player runtime 256×256 approvato PS-068 |
| `assets/art/characters/magno/generated/evil_portrait.png` | ritratto Evil runtime 256×256 |

Busto Player dedicato approvato dal proprietario e integrato da PS-068 il 3
settembre 2026; il `FriendDefinition` non usa più il ritaglio CC0 come
`portrait` o `portrait_placeholder`.
