# Direzione visuale — Bea

Riferimento sintetico per la famiglia visiva di Bea, pensato come aiuto per
`.agents/skills/game-art-designer/SKILL.md` (Claude:
`.claude/agents/game-art-designer.md`; Codex:
`.codex/agents/game-art-designer.toml`). Non sostituisce l'ispezione dei
fratelli visivi reali: in caso di conflitto con i master o con
`assets/art/characters/ASSET-MANIFEST.md`, questi ultimi restano autorevoli.
Ruolo gameplay, passiva e abilità attiva restano in
[`docs/characters.md`](../characters.md), non duplicati qui.

## Direzione visuale approvata

"Pattinatrice agile senza casco, con capelli scuri lunghi e ricci e un capo
sportivo viola durante un Powerslide basso, accompagnato da una breve scia di
fuoco dietro i roller." (`docs/characters.md`)

## Silhouette, costume e palette

Pattinatrice agile, senza casco, capelli scuri lunghi e ricci, giacca
sportiva viola, protezioni e roller; falcata da skating. Nessuna correzione
richiesta rispetto al primo output: confronto diretto con il fondale welcome
B18O giudicato positivo (`assets/art/characters/ASSET-MANIFEST.md`, tabella
prompt B18U). Scia di fuoco e Powerslide restano VFX separati, non parte
della silhouette del personaggio.

Il prompt integrale originale dell'identity pass non è disponibile nel
checkout. Il registro storico conserva un
[prompt ricostruito](../archive/generation-prompts-and-references.md#prompt-comuni-ricostruiti--non-originali),
etichettato esplicitamente come non originale e utile solo per il riuso, non
come prova di provenienza.

## Variante Evil

Lunghi ricci scuri, occhiali, fascia e giacca sportiva viola; sorriso
predatorio e accento arancio caldo (`evil_bea`,
`assets/art/characters/ASSET-MANIFEST.md`, Parte 2).

Grammatica Evil condivisa con tutto il cast: fumo prugna controllato, occhio
magenta-viola luminoso, poche crepe energetiche e rim light personale;
preserva acconciatura, corporatura, colori dell'abito e accessori del
Player.

## Reference fotografica

- `docs/characters/references/bea/source-01.png`,
  `docs/characters/references/bea/source-02.png`,
  `docs/characters/references/bea/source-03.png` — 3 file, ruolo `subject
  reference`, non editing target, mai output fotorealistico; autorizzate dal
  proprietario, archiviate il 2 settembre 2026.

## Master e derivati correnti

| File | Ruolo |
|---|---|
| `assets/art/characters/bea/hd/poses.png` | master HD Player, 3 pose (escluso da import/export) |
| `assets/art/characters/bea/hd/evil_portrait.png` | master HD Evil, ritratto busto (escluso da import/export) |
| `assets/art/characters/bea/hd/portrait.png` | master HD Player, busto approvato PS-068 (escluso da import/export) |
| `assets/art/characters/bea/generated/sprite.png` | striscia runtime 96×32 |
| `assets/art/characters/bea/generated/carousel.png` | ritratto carosello selezione 256×256 |
| `assets/art/characters/bea/generated/portrait.png` | ritratto Player runtime 256×256 approvato PS-068 |
| `assets/art/characters/bea/generated/evil_portrait.png` | ritratto Evil runtime 256×256 |

Busto Player dedicato approvato dal proprietario e integrato da PS-068 il 3
settembre 2026; il `FriendDefinition` non usa più il ritaglio CC0 come
`portrait` o `portrait_placeholder`.
