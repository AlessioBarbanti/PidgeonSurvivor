# Direzione visuale — Aleo

Riferimento sintetico per la famiglia visiva di Aleo, pensato come aiuto per
`.agents/skills/game-art-designer/SKILL.md` (Claude:
`.claude/agents/game-art-designer.md`; Codex:
`.codex/agents/game-art-designer.toml`). Non sostituisce l'ispezione dei
fratelli visivi reali: in caso di conflitto con i master o con
`assets/art/characters/ASSET-MANIFEST.md`, questi ultimi restano autorevoli.
Ruolo gameplay, passiva e abilità attiva restano in
[`docs/characters.md`](../characters.md), non duplicati qui.

Aleo è l'unico profilo del cast la cui direzione visuale è dichiaratamente
ispirata ai tratti di una persona reale, con consenso esplicito del
proprietario (rework del 28 agosto 2026): resta comunque "una caricatura
pixel-art e non una somiglianza fotografica" (`docs/characters.md`,
sezione "Direzione visuale del cast").

## Direzione visuale approvata

"Termotecnico giovane e robusto, occhiali e barba ramata, chiave regolabile e
manometro alla cintura, metà aura ciano di brina e metà aura arancio di
calore." (`docs/characters.md`)

## Silhouette, costume e palette

Il ruolo gameplay di Aleo è cambiato da muratore a termotecnico nel rework del
28 agosto 2026: il prompt originale (muratore con casco, cazzuola, secchio,
stivali) è superato. La direzione corrente — giovane, robusto, occhiali,
barba ramata, chiave regolabile e manometro — è documentata per intero in
[`docs/archive/generation-prompts-and-references.md`](../archive/generation-prompts-and-references.md#aleo--originale-recuperato),
non riassunta qui per evitare due fonti divergenti.

## Variante Evil

Capelli castani, barba ramata, occhiali, tuta nera, manometri e tubi; accento
ciano-rame (`evil_aleo`, `assets/art/characters/ASSET-MANIFEST.md`, Parte 2).
Ha richiesto un passaggio correttivo `background-extraction` per rimuovere il
checkerboard incorporato, senza ridisegnare il soggetto.

Grammatica Evil condivisa con tutto il cast: fumo prugna controllato, occhio
magenta-viola luminoso, poche crepe energetiche e rim light personale;
preserva acconciatura, corporatura, colori dell'abito e accessori del
Player.

## Reference fotografica

- `docs/characters/references/aleo/source-01.png`, `source-02.png` — 2 file,
  ruolo `subject reference`, non editing target, mai output fotorealistico;
  autorizzate dal proprietario, archiviate il 2 settembre 2026. Per il busto
  Player PS-068 hanno fornito soltanto citazioni fisionomiche semplificate;
  `poses.png` è rimasto dominante per proporzioni, identità di gioco e stile.

## Master e derivati correnti

| File | Ruolo |
|---|---|
| `assets/art/characters/aleo/hd/poses.png` | master HD Player, 3 pose (escluso da import/export) |
| `assets/art/characters/aleo/hd/evil_portrait.png` | master HD Evil, ritratto busto (escluso da import/export) |
| `assets/art/characters/aleo/generated/sprite.png` | striscia runtime 96×32 |
| `assets/art/characters/aleo/generated/carousel.png` | ritratto carosello selezione 256×256 |
| `assets/art/characters/aleo/hd/portrait.png` | master HD Player, busto approvato PS-068 (escluso da import/export) |
| `assets/art/characters/aleo/generated/portrait.png` | ritratto Player runtime 256×256 approvato PS-068 |
| `assets/art/characters/aleo/generated/evil_portrait.png` | ritratto Evil runtime 256×256 |
| `assets/art/icons/passives/hd/aleo_internal_thermostat_source.png` | master HD dell'icona Termostato Interno, escluso da import/export |
| `assets/art/icons/passives/generated/aleo_internal_thermostat.png` | icona passiva runtime 128×128 approvata PS-131 |

Busto Player dedicato (`portrait.png`, analogo a `evil_portrait.png`): master
e derivato approvati esplicitamente dal proprietario e integrati da PS-068 il
3 settembre 2026. `data/friends/aleo.tres` usa il derivato definitivo sia per
`portrait` sia per `portrait_placeholder` e dichiara
`portraits_are_placeholders = false`.

L'icona di `Termostato Interno`, approvata con PS-131 l'8 settembre 2026, è un
singolo tizzone a silhouette libera: metà brace arancio-oro e metà carbone
congelato bianco-ghiaccio/ciano. Lo split materiale circa 50/50 sostituisce il
precedente quadrante con bezel e fondo opaco, senza cambiare il percorso
referenziato da `data/friends/aleo.tres`.
