# Direzione visuale — Migi

Riferimento sintetico per la famiglia visiva di Migi, pensato come aiuto per
`.agents/skills/game-art-designer/SKILL.md` (Claude:
`.claude/agents/game-art-designer.md`; Codex:
`.codex/agents/game-art-designer.toml`). Non sostituisce l'ispezione dei
fratelli visivi reali: in caso di conflitto con i master o con
`assets/art/characters/ASSET-MANIFEST.md`, questi ultimi restano autorevoli.
Ruolo gameplay, passiva e abilità attiva restano in
[`docs/characters.md`](../characters.md), non duplicati qui. Il soprannome
"Tartarughina" (Guscio Tartarughina, PS-045/B45) va mantenuto nei testi.

## Direzione visuale approvata

"Donna con occhiali e capelli neri, calma e concentrata dentro uno scudo
ciano a guscio di tartaruga e onde rallentanti; non è vincolata a un
archetipo monastico." (`docs/characters.md`)

## Silhouette, costume e palette

Donna calma, capelli neri, occhiali, outfit teal, scudo a guscio compatto,
passo deliberato. Nessuna correzione richiesta rispetto al primo output:
confronto diretto con il fondale welcome B18O giudicato positivo
(`assets/art/characters/ASSET-MANIFEST.md`, tabella prompt B18U). Il guscio
resta uno scudo compatto sul personaggio, non un'anatomia da tartaruga
letterale.

Il prompt integrale originale dell'identity pass non è disponibile nel
checkout. Il registro storico conserva un
[prompt ricostruito](../archive/generation-prompts-and-references.md#prompt-comuni-ricostruiti--non-originali),
etichettato esplicitamente come non originale e utile solo per il riuso, non
come prova di provenienza.

## Variante Evil

Capelli neri raccolti, occhiali, tuta protettiva teal e guscio segmentato;
minaccia controllata e accento menta (`evil_migi`,
`assets/art/characters/ASSET-MANIFEST.md`, Parte 2).

Grammatica Evil condivisa con tutto il cast: fumo prugna controllato, occhio
magenta-viola luminoso, poche crepe energetiche e rim light personale;
preserva acconciatura, corporatura, colori dell'abito e accessori del
Player.

## Reference fotografica

- `docs/characters/references/migi/source-01.png`, `source-02.png` — 2 file,
  ruolo `subject reference`, non editing target, mai output fotorealistico;
  autorizzate dal proprietario, archiviate il 2 settembre 2026.

## Master e derivati correnti

| File | Ruolo |
|---|---|
| `assets/art/characters/migi/hd/poses.png` | master HD Player, 3 pose (escluso da import/export) |
| `assets/art/characters/migi/hd/evil_portrait.png` | master HD Evil, ritratto busto (escluso da import/export) |
| `assets/art/characters/migi/hd/portrait.png` | master HD Player, busto approvato PS-068 (escluso da import/export) |
| `assets/art/characters/migi/generated/sprite.png` | striscia runtime 96×32 |
| `assets/art/characters/migi/generated/carousel.png` | ritratto carosello selezione 256×256 |
| `assets/art/characters/migi/generated/portrait.png` | ritratto Player runtime 256×256 approvato PS-068 |
| `assets/art/characters/migi/generated/evil_portrait.png` | ritratto Evil runtime 256×256 |

Busto Player dedicato approvato dal proprietario e integrato da PS-068 il 3
settembre 2026; il `FriendDefinition` non usa più il ritaglio CC0 come
`portrait` o `portrait_placeholder`.
