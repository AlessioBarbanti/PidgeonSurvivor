---
id: PS-197
titolo: Introduci l'impianto arma per personaggio senza cambiare il gioco
tipo: feat
area: gameplay
stato: IN VERIFICA
priorita: alta
dipende_da: [PS-196]
origine:
creato: 2026-09-18
aggiornato: 2026-09-21
---

# PS-197 — Introduci l'impianto arma per personaggio senza cambiare il gioco

## Contesto

[PS-196](../5_completed/PS-196-contratto-armi-per-personaggio.md) fissa il contratto delle
armi per personaggio. Questa card costruisce il solo impianto tecnico che lo
regge, **senza cambiare nulla di percepibile**: al termine, tutti e otto i
personaggi sparano esattamente come oggi, ma passando dalla nuova strada.

Serve perché oggi l'arma è cablata staticamente nella scena del Player
([scenes/actors/player.tscn:5,79-80](../../../scenes/actors/player.tscn):
`WeaponProfile` e `projectile_scene` sono `ExtResource` fissi) e non esiste
alcun punto in cui un personaggio possa dichiarare la propria.

Il modello architetturale esiste già nel progetto:
`AbilityEffectRegistry`
([scripts/abilities/ability_effect_registry.gd:264](../../../scripts/abilities/ability_effect_registry.gd))
dispatcha su `effect_id` comportamenti strutturalmente diversi, scelti per
personaggio via `FriendDefinition.active_ability_id`. L'impianto delle armi ne
è il gemello per l'attacco automatico.

Separare questo passo dalle armi vere è ciò che rende reversibile l'intera
iniziativa: se il set pilota non convince, l'impianto resta neutro e non ha
tolto nulla.

## Comportamento atteso

Ogni personaggio dichiara nei dati quale arma usa; `WeaponController` chiede a
un registry di effetti d'arma di produrre i proiettili invece di costruirli da
sé. Con tutti i personaggi assegnati all'arma di default, il gioco è
indistinguibile da prima: stessa cadenza, stesso danno, stessa traiettoria,
stessi effetti delle Specialità.

## Criteri di accettazione

- [x] Esiste una `Resource` `WeaponDefinition` che dichiara `effect_id:
      StringName` + parametri e i valori base dell'arma, sullo stesso schema
      dichiarativo di `AbilityDefinition` (nessuna logica nei dati).
- [x] `FriendDefinition` espone un campo che indica l'arma del personaggio,
      sul modello di `active_ability_id`.
- [x] Esiste un `WeaponEffectRegistry` che possiede **solo l'emissione**:
      ricevute origine e direzione di mira, produce i proiettili dell'arma
      attiva. Nessuna logica di bersagliamento, cooldown o upgrade al suo
      interno.
- [x] `WeaponController.try_fire()`
      ([weapon_controller.gd:99-149](../../../scripts/combat/weapon_controller.gd))
      resta il **punto unico** di esecuzione dello sparo: sparo automatico e
      manuale ([PS-085](../5_completed/PS-085-introduci-sparo-manuale-con-secondo-joystick.md))
      continuano a convergere lì senza duplicazione.
- [x] Tutti e otto i personaggi puntano all'arma di default e il
      comportamento di gioco è invariato: cadenza, danno, velocità, raggio,
      lifetime e muzzle offset effettivi a inizio run restano identici ai
      valori odierni.
- [x] Tutte le Specialità legate al proiettile (Arrosticini, Tagliata,
      Fiorentina, Salsiccia, Alette) continuano ad applicarsi attraverso gli
      stessi setter di `WeaponController`, senza modifiche a
      `UpgradeEffectRegistry`.
- [x] `tests/unit/test_b41_weapon_shapes.gd` e
      `tests/unit/test_ps085_manual_fire_mode.gd` restano verdi **senza
      essere modificati nelle aspettative di comportamento**.
- [x] `RunContractValidator` continua a validare il wiring dell'arma
      ([run_contract_validator.gd:453-465](../../../scripts/app/run_contract_validator.gd))
      e le statistiche iniziali (righe 604-637), aggiornato solo per leggere
      l'arma dalla nuova sorgente, non per allentare i controlli.

## Ambito

- `scripts/combat/`: nuova `WeaponDefinition`, nuovo `WeaponEffectRegistry`,
  `weapon_controller.gd` (delega dell'emissione, `_spawn_projectile()` righe
  152-197).
- `scripts/content/friend_definition.gd`: campo dell'arma.
- `data/weapons/`: definizione dell'arma di default che riproduce
  `default_weapon_profile.tres`.
- `data/friends/*.tres`: assegnazione dell'arma di default a tutti e otto.
- `scenes/actors/player.tscn` e `scenes/game/movement_slice.tscn`: wiring del
  registry, sul modello di come è montato `AbilityEffectRegistry`.
- `scripts/app/run_contract_validator.gd`: lettura dell'arma dalla nuova
  sorgente.
- Non toccare:
  - `scripts/progression/upgrade_effect_registry.gd` e i setter delle
    Specialità: devono continuare a funzionare invariati, è la prova che
    l'invariante di PS-196 regge;
  - il contratto `RunController` (stati, pausa, arbitraggio modali) e il
    flusso `welcome → tutorial → selezione → run → pausa`;
  - `FireModeSettings` e la modalità di sparo (impostazione condivisa, PS-085);
  - il bilanciamento: nessun valore numerico cambia in questa card.

## Verifica

- Smoke: `tests/unit/test_ps197_weapon_definition_wiring.gd` → marker
  `PS197_WEAPON_DEFINITION_WIRING_SMOKE_OK` — verifica che ogni
  `FriendDefinition` risolva un'arma valida nel registry, che i valori
  effettivi a inizio run coincidano con quelli odierni per tutti e otto i
  personaggi, e che lo sparo passi da `try_fire()` sia in automatico sia in
  manuale.
- Regressioni obbligatorie: `test_b41_weapon_shapes.gd`,
  `test_ps085_manual_fire_mode.gd`. Aggiornare
  [tools/milestone-test-map.json](../../../tools/milestone-test-map.json) per
  i nuovi file.
- Profilo minimo prima della chiusura: `Full` — tocca il cuore del combattimento
  e il validatore dei contratti, `Relevant` non basta.

## Gate manuali

- [x] Runtime Windows — chiuso dalla `Release` di PS-198, che contiene
      anche questo codice: `windows-export` e `windows-runtime` PASS
- [x] Validazione statica APK — stessa `Release`: `android-static` PASS
- [ ] Runtime fisico Pixel 9 — **aperto**: nessun device collegato
- [ ] Controllo percettivo richiesto: sì, ma in negativo — la prova è che
      **non si percepisca alcuna differenza** rispetto a oggi

## Decisioni

- **2026-09-18 — Passo deliberatamente neutro.** Nessuna arma nuova qui:
  separare impianto e contenuto è ciò che rende l'iniziativa reversibile e
  permette di validare l'impianto con i test esistenti come rete di
  sicurezza.
- **2026-09-18 — L'emissione è l'unica responsabilità del registry.**
  Bersagliamento, cooldown, mira manuale e modificatori delle Specialità
  restano dove sono: il registry riceve origine e direzione e restituisce
  proiettili, così ogni arma futura eredita gratis sparo automatico e manuale.

- **2026-09-21 — `WeaponDefinition` estende `WeaponProfile`** invece di
  affiancarlo. Motivazione: i valori base dell'arma sono esattamente i campi
  gia' validati da `WeaponProfile` e gia' letti da `WeaponController`; un
  secondo Resource da tenere allineato sarebbe stato solo una copia da
  sincronizzare. Come effetto, `weapon_profile` resta il campo di sempre e
  `default_weapon_profile.tres` e' stato convertito sul posto (stessi valori,
  stesso percorso), cosi' i test che ne asseriscono la baseline restano
  verdi senza modifiche.
- **2026-09-21 — Il registry e' senza stato e non conosce l'RNG.**
  `build_emissions()` riceve direzione e restituisce posizione di partenza e
  direzione di ciascun colpo; la dispersione di Alette viene applicata dal
  controller ruotando *dello stesso angolo* direzione e offset. E' la
  reinterpretazione dichiarata in PS-196, ed e' invariante per l'arma
  condivisa (offset nullo, una sola emissione, stesso consumo di RNG).
- **2026-09-21 — Il registry e' opzionale in `configure()`.** Le fixture che
  montano un `WeaponController` isolato (test_b05) non hanno una scena
  composta: senza registry l'arma ricade sul colpo dritto invece di non
  sparare. Il wiring reale resta obbligatorio ed e' `RunContractValidator` a
  imporlo.
- **2026-09-21 — L'arma viene assegnata in `_equip_friend()` prima di
  `FriendPassiveController`**, perche' i moltiplicatori di personaggio devono
  comporsi sopra i valori base dell'arma nuova, non di quella precedente.
- **2026-09-21 — Lo smoke verifica i due strati separati, non il loro
  prodotto.** Una prima stesura confrontava `get_base_damage()` con
  `baseline x FriendDefinition`, e falliva su Aleo e Lollo: Termostato Interno
  e Iperfocus muovono il moltiplicatore di personaggio a run in corso. Il
  contratto da provare e' che l'arma porti la baseline e il personaggio vi si
  componga sopra, ed e' quello che il test misura ora.

## Documenti sincronizzati

- [x] `CLAUDE.md` — `WeaponEffectRegistry` è ora dichiarato accanto a
      `AbilityEffectRegistry`/`UpgradeEffectRegistry`, con il perimetro della
      sua responsabilità (sola emissione).

## Note

Comando di verifica e marker usati come evidenza:

```powershell
.	ools
un-milestone-checks.ps1 -Milestone PS-197 -Profile Focused `
  -FocusedSmoke tests/unit/test_ps197_weapon_definition_wiring.gd -RefreshEditor
.	ools
un-milestone-checks.ps1 -Milestone PS-197 -Profile Full
```

`Full` → `status=PASS focused=1/1 regression=163/163 toolchain=1/1`, marker
`PS197_WEAPON_DEFINITION_WIRING_SMOKE_OK`, zero occorrenze di `SCRIPT ERROR` o
`FATAL EXCEPTION` nei log. `test_b41_weapon_shapes.gd` e
`test_ps085_manual_fire_mode.gd` sono passati **senza modifiche**.

I gate di piattaforma sono stati esercitati una sola volta a valle di
[PS-198](./PS-198-armi-pilota-primo-set.md), che riscrive lo stesso codice: un
export prodotto prima sarebbe stato sostituito prima di poter essere provato.
Windows runtime e validazione statica dell'APK sono chiusi da quella
`Release`; il runtime fisico su Pixel 9 resta **aperto** perche' non c'era
alcun device collegato.


Card aperte che toccano lo stesso codice e vanno coordinate:
[PS-190](../5_completed/PS-190-centralizza-letture-e-filtri-upgrade.md)
(centralizzazione dei filtri upgrade),
[PS-121](../5_completed/PS-121-carte-ripetibili-sature-escono-dal-pool.md),
[PS-160](../5_completed/PS-160-rendi-competitivi-upgrade-velocita.md),
[PS-085](../5_completed/PS-085-introduci-sparo-manuale-con-secondo-joystick.md),
[PS-093](../5_completed/PS-093-nuovi-assi-scarto-base-personaggi.md).
