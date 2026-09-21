---
id: PS-202
titolo: Prova il Coperchio di Magno come prima arma in mischia
tipo: feat
area: gameplay
stato: IN VERIFICA
priorita: alta
dipende_da: [PS-198]
origine:
creato: 2026-09-22
aggiornato: 2026-09-22
---

# PS-202 — Prova il Coperchio di Magno come prima arma in mischia

## Contesto

Dopo PS-197/198/200 le otto armi si distinguono solo per come viaggia il
colpo: tutte sparano un corpo verso il nemico più vicino e tutte si vedono
come lo stesso puntino di brace (`player_projectile.png`). Il proprietario
chiede di cambiare concetto: non proiettili, ma **armi** vere. Si parte da un
solo personaggio, Magno, perché la sua arma attuale (Carbonella, palla lenta a
corto raggio) è già pensata per la mischia che la sua passiva gli chiede.

## Comportamento atteso

Magno impugna il **Coperchio**: a ogni colpo fa roteare davanti a sé un
coperchio da barbecue lungo un arco di circa 150° centrato sulla mira. Il
coperchio resta agganciato a Magno mentre si muove, colpisce ogni nemico che
spazza (fino a un tetto di bersagli) e sparisce a fine arco. Non respinge: la
spinta resta dell'Onda d'Urto Tellurica.

Nessuna arte: coperchio e scia dell'arco sono disegnati con primitive
poligonali, abbastanza da leggere la forma in partita.

## Criteri di accettazione

- [x] Magno dichiara `weapon_id = coperchio`; gli altri sette personaggi non
      cambiano arma.
- [x] Il colpo nasce a mezzo arco *prima* della mira, sulla circonferenza di
      raggio dichiarato attorno a Magno, e a metà della propria durata passa
      sulla linea di mira.
- [x] Se Magno si sposta durante il fendente, il coperchio resta alla stessa
      distanza da lui.
- [x] A fine durata il coperchio scade da solo.
- [x] Il coperchio è disegnato con primitive (disco, bordo, maniglia e scia
      dell'arco), non con lo sprite della brace; le altre armi restano sullo
      sprite.
- [x] Le cinque Specialità legate al proiettile arrivano al coperchio dagli
      stessi setter di sempre (verificato dalla matrice di PS-198).
- [x] Il tetto aritmetico di kill-rate del cast resta entro il 10% dichiarato
      da PS-198/PS-200.

## Ambito

- `data/weapons/coperchio.tres` (nuovo), `data/friends/magno.tres`,
  registrazione in `scenes/game/movement_slice.tscn`.
- `WeaponEffectRegistry`: una geometria d'emissione `sweeping_arc`.
- `Projectile`: disegno poligonale provvisorio dichiarato dai dati dell'arma.
- Non toccare:
  - `RunController`, flusso `welcome → tutorial → selezione → run → pausa`;
  - l'invariante di PS-196 "ogni arma emette `Projectile`": il fendente è un
    `Projectile` su traiettoria orbitale limitata, così le Specialità restano
    valide per costruzione;
  - le armi degli altri sette personaggi;
  - `data/weapons/carbonella.tres`, che resta registrata ma non assegnata
    finché il proprietario non decide l'esito della prova.

## Verifica

- Smoke: `tests/unit/test_ps202_coperchio_sweep.gd` → marker
  `PS202_COPERCHIO_SWEEP_SMOKE_OK`
- Regressioni: `test_ps198_pilot_weapons.gd` (Magno passa al Coperchio),
  `test_ps200_cast_weapons.gd`, `test_ps197_weapon_definition_wiring.gd`.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows (percorso: run con Magno, fendenti su orda e su nemico
      isolato, con e senza Tagliata/Salsiccia)
- [ ] Validazione statica APK — non pertinente
- [ ] Runtime fisico Pixel 9 — non pertinente per una prova di concetto
- [ ] Controllo percettivo richiesto: sì, del proprietario: il fendente si
      legge come un'arma e non come un proiettile?

## Decisioni

- **2026-09-22 — Arma in mischia come corpo `Projectile` agganciato, non come
  nuovo atomo "colpo".** Il fendente riusa la traiettoria orbitale della
  Graticola su un arco parziale centrato sulla mira. Motivazione: è la prova
  più economica del concetto "arma, non proiettile" dal punto di vista di chi
  gioca, e non tocca le Specialità, l'assorbimento della zona Zen, l'audio né
  il restart. Se la prova regge, il refactor verso un atomo "colpo" ipotizzato
  in chat non serve.
- **2026-09-22 — Ampiezza dell'arco = portata dell'arma.** L'arco è
  `velocità × durata` avvolto sul raggio, la stessa grandezza che per un colpo
  dritto è la portata: un bonus di velocità allunga il fendente come
  allungherebbe la corsa di un proiettile, senza un parametro in più.
- **2026-09-22 — Solo poligoni, niente arte** su richiesta del proprietario.
  L'arte del coperchio si apre come card `art` solo se la prova passa.
- **Aperte, da osservare in partita:**
  - con **Salsiccia** il coperchio si ferma al primo nemico, perché la catena
    prevale sulla perforazione (regola esistente di `Projectile`, vale già per
    la Graticola): per un'arma in mischia potrebbe sembrare un peggioramento;
  - con **Tagliata** i coperchi extra partono ruotati di 12° e si
    sovrappongono quasi del tutto al principale;
  - il fendente ruota sempre nello stesso verso: alternarlo è rimandato.
- **Sostituisce:** la Carbonella come arma di Magno (PS-198), solo se la prova
  viene approvata.

## Documenti sincronizzati

- [x] `docs/characters.md` — arma di Magno.
- [x] `docs/prd.md` §3.1A — la mischia è ammessa come corpo `Projectile`
      agganciato al personaggio.

## Note

Build di riferimento del tetto (PS-198): Alette ×1,25 cadenza, danno ×1,5,
Tagliata a tre proiettili, Arrosticini +3 perforazioni a decadimento 0,7.
Con il Coperchio (1 fendente/s, 32,3 danno, 5 bersagli) il tetto è 5,707
kill/s contro 5,699 dell'arma condivisa: scarto dell'intero cast 0,5%.

Parametri del fendente: raggio d'orbita 62 px (Magno ha raggio 24), coperchio
di raggio 30, quindi spazza la fascia 32–92 px dal centro; velocità 740 ×
durata 0,22 s su raggio 62 = arco di ~150°.

Tre test di mira (`test_b05_combat_slice`, `test_b13_signature_upgrades`,
`test_ps085_manual_fire_mode`) leggevano `projectile.direction` con l'arma del
personaggio di default, che era frontale. Ora montano esplicitamente l'arma
condivisa `Scintilla` con l'helper `GutGameplayTest.mount_shared_weapon()`:
verificano la mira, non l'arma di Magno.

Evidenze:

- `.\tools\run-milestone-checks.ps1 -Milestone PS-202 -Profile Relevant
  -FocusedSmoke tests/unit/test_ps202_coperchio_sweep.gd` → `status=PASS
  focused=1/1 regression=141/141`, nessun `SCRIPT ERROR`/`FATAL EXCEPTION`
  nei log; marker `PS202_COPERCHIO_SWEEP_SMOKE_OK` e
  `PS198_PILOT_WEAPONS_SMOKE_OK`.
- Cattura di sviluppo con renderer Windows reale (script usa e getta, non
  versionato): coperchio con bordo e maniglia che spazza l'arco attorno a
  Magno, con la scia dell'arco già percorso. Non sostituisce il controllo
  percettivo del proprietario.
