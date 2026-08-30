# Pidgeon Survivor

*It's grilling time!*

Prototipo 2D in Godot 4.7.1, organizzato a partire dal PRD in
[`docs/prd.md`](docs/prd.md).

Target co-primari:

- Windows x64;
- Android 12–16 (API 31–36), ARM64, landscape.

Il vertical slice corrente completa l'implementazione automatizzata B03–B18B, usa il renderer Compatibility e
include movimento 8 direzioni,
joystick touch, arena responsive, nemici inseguitori, spawner dinamico, targeting
del vivo più vicino, fuoco automatico, proiettili, salute Player, danno da
contatto, invulnerabilità, Game Over, restart, drop XP e raccolta magnetica con
accredito singolo, livelli, soglie XP configurabili, overflow e coda delle
scelte, HUD safe-area con vita, XP, livello, timer e abilità attiva, pausa
manuale e lifecycle Android senza resume automatico. Include inoltre il
framework dati/runtime delle abilità e l'Onda d'Urto Tellurica di Magno con
input tastiera, controller e touch, cooldown, danno radiale e knockback. B10
aggiunge inoltre `UpgradeDefinition`, catalogo validato, rank per run e pesca
pesata deterministica di tre ID unici con fallback ripetibili. B11 aggiunge
l'overlay safe-area e la selezione con mouse, tastiera, controller e touch.
B12 applica velocità, frequenza, danno e raggio pickup con stacking
moltiplicativo, cap configurabili e reset completo senza mutare i Resource.
B13–B16 completano upgrade signature, Game Director, Evil Bea, vittoria e run
chiusa. B17 aggiunge gli otto profili approvati e le controparti `Evil <Nome>`;
B17A rende gli otto amici selezionabili e giocabili con ritratto, passiva e
abilità propria. B18 aggiunge icone dedicate, gerarchia VFX leggibile, cue CC0 e
volume/mute persistenti. B18B compatta HUD e controlli, sostituisce la vista
debug dell'arena con un pavimento procedurale discreto e aggiunge reazioni,
particelle e impulsi di combattimento senza cambiare collisioni o bilanciamento.
Lo stato più recente è in
[`docs/b18b-verification.md`](docs/b18b-verification.md) e le approvazioni sono
in [`docs/content-approvals.md`](docs/content-approvals.md).

## Avvio rapido

Da PowerShell, nella root del repository:

```powershell
.\tools\verify-toolchain.ps1 -RunProjectSmoke
.\tools\run-milestone-checks.ps1 -Milestone B54 -Profile Full
godot --editor --path .
```

Tutti i test automatici vivono in `tests/unit/` (contratto GUT, `test_*.gd`) ed
eseguono in un solo processo Godot per profilo; i dettagli sono in
[`docs/verification-workflow.md`](docs/verification-workflow.md).

I comandi di export, i prerequisiti Android e le regole sulla firma sono in
[`docs/setup.md`](docs/setup.md). La
[mappa della documentazione](docs/README.md) separa contratti, card, verifiche e
archivio. Tutto il lavoro e le decisioni operative sono nella
[`board delle card`](docs/cards/README.md).
