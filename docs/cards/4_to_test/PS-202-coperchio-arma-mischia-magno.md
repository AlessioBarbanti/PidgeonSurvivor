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
- [x] In automatico il Coperchio non colpisce se il nemico più vicino è
      oltre la sua portata, e il cooldown resta pronto; le armi a distanza non
      hanno limite di portata.
- [x] In automatico il fendente è centrato sull'ultima direzione di
      movimento di Magno; un nemico a portata ma alle spalle non lo fa
      partire, e voltandosi verso di lui il fendente parte.
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
- **2026-09-22 — Prima prova su Pixel 9: "molto difficile da usare, non
  faccio tempo a colpire i nemici che mi colpiscono loro".** Le cause erano
  due. (1) In automatico il fendente partiva verso il nemico più vicino a
  qualunque distanza: girava nel vuoto e consumava il cooldown di 1 s, che non
  era pronto quando il nemico arrivava. (2) La portata era corta: il coperchio
  arrivava a ~112 px dal centro di Magno contro i ~44 px del contatto, e uno
  sciame a 210 px/s copre quel margine in 0,3 s. Correzioni: in automatico il
  fendente parte solo con il nemico più vicino entro la portata dell'arma
  (`WeaponEffectRegistry.get_engage_distance()`, illimitata per le armi a
  distanza; in manuale decide il giocatore), e l'arco passa a raggio 90 con
  coperchio da 40, cioè fascia 50–130 px e portata 150 px. Cadenza e danno
  invariati, per tenere il colpo singolo sul nemico corazzato (31 HP).
- **2026-09-22 — Il fendente va dove Magno va.** Proposta del proprietario:
  in automatico il coperchio spazza l'arco centrato sull'ultima direzione di
  movimento (`Player.get_last_movement_direction()`, la stessa dello scatto
  di Bea), non verso il nemico più vicino. Parte solo se un nemico è dentro la
  portata **e** dentro l'arco: un nemico alle spalle non consuma il cooldown
  con un colpo che lo mancherebbe. Motivazione: Flusso Aerodinamico Bovino
  premia già chi corre dritto, e il coperchio davanti ne fa un ariete che si
  apre la strada. Dichiarato nei dati (`WeaponDefinition.aims_along_movement`),
  non per personaggio nel codice; in manuale vince la mira del giocatore.
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

Parametri del fendente (dopo la prima prova su Pixel): raggio d'orbita 90 px
(Magno ha raggio 24), coperchio di raggio 40, quindi spazza la fascia 50–130
px dal centro; velocità 1070 × durata 0,22 s su raggio 90 = arco di ~150°.
Portata in automatico 90 + 40 + 20 (raggio di un nemico base) = 150 px.

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
  `PS198_PILOT_WEAPONS_SMOKE_OK`. Dopo la correzione di portata: `status=PASS
  focused=1/1 regression=11/11`, log puliti.
- Primo APK su Pixel 9: export `PASS`, statica `PASS`, installato e avviato
  fino a `B18O_RUN_STARTED friend=magno` senza errori; prova del proprietario
  negativa (vedi Decisioni), da ripetere con l'APK corretto.
- Mira sul movimento: `-Profile Full` → `status=PASS focused=1/1
  regression=166/166 toolchain=1/1`, log puliti. Il `Full` ha trovato quattro
  test (`test_b12_upgrade_effects`, `test_b26_damage_upgrade`,
  `test_b18n_pause_change_character`, `test_ps005_boss_warning`) che
  sparavano col personaggio di default a bersagli oltre i 150 px di portata
  o non davanti a Magno: rotti già dalla correzione di portata, che il
  `Relevant` di allora non aveva selezionato. Ora montano l'arma condivisa
  con `mount_shared_weapon()`, come i test di mira.
- Cattura di sviluppo con renderer Windows reale (script usa e getta, non
  versionato): coperchio con bordo e maniglia che spazza l'arco attorno a
  Magno, con la scia dell'arco già percorso. Non sostituisce il controllo
  percettivo del proprietario.
