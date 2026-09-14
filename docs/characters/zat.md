# Direzione visuale — Zat

Riferimento sintetico per la famiglia visiva di Zat, pensato come aiuto per
`.agents/skills/game-art-designer/SKILL.md` (Claude:
`.claude/agents/game-art-designer.md`; Codex:
`.codex/agents/game-art-designer.toml`). Non sostituisce l'ispezione dei
fratelli visivi correnti: in caso di conflitto con i master o con
`assets/art/characters/ASSET-MANIFEST.md`, questi ultimi restano autorevoli.
Ruolo gameplay, passiva e abilità attiva restano in
[`docs/characters.md`](../characters.md), non duplicati qui.

## Direzione visuale approvata

"Infermiera elettrica con taglio a caschetto e divisa bianco-ciano, simbolo
medico generico a cuore, luce curativa e fulmine giallo-ciano."
(`docs/characters.md`)

## Silhouette, costume e palette

Infermiera elettrica, divisa bianco-ciano, taglio a caschetto teal, simbolo
medico generico a cuore, passo rapido. Il primo output generava un copricapo
non voluto: rimosso nella correzione finale, che allinea caschetto e divisa al
fondale welcome B18O e **non** usa la Croce Rossa
(`assets/art/characters/ASSET-MANIFEST.md`, tabella prompt B18U).

Il prompt integrale originale dell'identity pass non è disponibile nel
checkout. Il registro storico conserva un
[prompt ricostruito](../archive/generation-prompts-and-references.md#prompt-comuni-ricostruiti--non-originali),
etichettato esplicitamente come non originale e utile solo per il riuso, non
come prova di provenienza.

## Variante Evil

Caschetto castano, divisa bianco-ciano, guanti teal e simbolo generico a
cuore; accento ciano con lampo giallo (`evil_zat`,
`assets/art/characters/ASSET-MANIFEST.md`, Parte 2).

Grammatica Evil condivisa con tutto il cast: fumo prugna controllato, occhio
magenta-viola luminoso, poche crepe energetiche e rim light personale;
preserva acconciatura, corporatura, colori dell'abito e accessori del
Player.

## Reference visive riservate

- `docs/characters/references/zat/source-01.png`,
  `docs/characters/references/zat/source-02.png`,
  `docs/characters/references/zat/source-03.png`,
  `docs/characters/references/zat/source-04.png` — 4 file riservati, ruolo
  `subject reference`, fuori da import/export.

## Master e derivati correnti

| File | Ruolo |
|---|---|
| `assets/art/characters/zat/hd/poses.png` | master HD Player, 3 pose (escluso da import/export) |
| `assets/art/characters/zat/hd/evil_portrait.png` | master HD Evil, ritratto busto (escluso da import/export) |
| `assets/art/characters/zat/hd/portrait.png` | master HD Player, busto approvato PS-068 (escluso da import/export) |
| `assets/art/characters/zat/generated/sprite.png` | striscia runtime 96×32 |
| `assets/art/characters/zat/generated/carousel.png` | ritratto carosello selezione 256×256 |
| `assets/art/characters/zat/generated/portrait.png` | ritratto Player runtime 256×256 approvato PS-068 |
| `assets/art/characters/zat/generated/evil_portrait.png` | ritratto Evil runtime 256×256 |

Busto Player dedicato approvato dal proprietario e integrato da PS-068 il 3
settembre 2026; il `FriendDefinition` non usa più il ritaglio CC0 come
`portrait` o `portrait_placeholder`.
