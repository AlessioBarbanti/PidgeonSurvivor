# Repository Guidelines

Le istruzioni operative di questo repository vivono in un unico posto:
[`CLAUDE.md`](./CLAUDE.md).

Quel file contiene fonti di verità, lingua, contratti architetturali, stile
GDScript, workflow di verifica, onestà dei gate di piattaforma e igiene del
repository. Vale per qualunque agente lavori qui, non solo per Claude Code:
leggilo prima di toccare il progetto.

Procedure specifiche, in ordine di frequenza d'uso:

- creazione e risoluzione delle card: `.agents/skills/il-gioco-card/SKILL.md`
  (formato Codex) oppure `.claude/skills/card-crea/` e `.claude/skills/card-risolvi/`;
- build e installazione Android: `.claude/skills/build-apk/`;
- smoke test di integrazione: `.claude/skills/smoke-test/`;
- gate Windows e Android: `.claude/skills/gate-piattaforme/`;
- asset grafici e audio (integrazione, derivazione, manifest): `.claude/skills/asset-pipeline/`;
- creazione o generazione di nuovi asset grafici per card `tipo: art`:
  agente Game Art Designer (`.agents/skills/game-art-designer/SKILL.md`), su
  Claude (`.claude/agents/game-art-designer.md`) o su Codex
  (`.codex/agents/game-art-designer.toml`).

Documenti autorevoli: `docs/cards/README.md` come unica fonte di verità
operativa, `docs/prd.md`, `docs/characters.md`, `docs/powerup-catalog.md`,
`docs/verification-workflow.md` e `docs/setup.md`.
