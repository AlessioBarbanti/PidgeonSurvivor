---
id: PS-197
titolo: Introduci l'impianto arma per personaggio senza cambiare il gioco
tipo: feat
area: gameplay
stato: BLOCCATO
priorita: alta
dipende_da: [PS-196]
origine:
creato: 2026-09-18
aggiornato: 2026-09-18
---

# PS-197 — Introduci l'impianto arma per personaggio senza cambiare il gioco

## Contesto

[PS-196](./PS-196-contratto-armi-per-personaggio.md) fissa il contratto delle
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

- [ ] Esiste una `Resource` `WeaponDefinition` che dichiara `effect_id:
      StringName` + parametri e i valori base dell'arma, sullo stesso schema
      dichiarativo di `AbilityDefinition` (nessuna logica nei dati).
- [ ] `FriendDefinition` espone un campo che indica l'arma del personaggio,
      sul modello di `active_ability_id`.
- [ ] Esiste un `WeaponEffectRegistry` che possiede **solo l'emissione**:
      ricevute origine e direzione di mira, produce i proiettili dell'arma
      attiva. Nessuna logica di bersagliamento, cooldown o upgrade al suo
      interno.
- [ ] `WeaponController.try_fire()`
      ([weapon_controller.gd:99-149](../../../scripts/combat/weapon_controller.gd))
      resta il **punto unico** di esecuzione dello sparo: sparo automatico e
      manuale ([PS-085](../4_to_test/PS-085-introduci-sparo-manuale-con-secondo-joystick.md))
      continuano a convergere lì senza duplicazione.
- [ ] Tutti e otto i personaggi puntano all'arma di default e il
      comportamento di gioco è invariato: cadenza, danno, velocità, raggio,
      lifetime e muzzle offset effettivi a inizio run restano identici ai
      valori odierni.
- [ ] Tutte le Specialità legate al proiettile (Arrosticini, Tagliata,
      Fiorentina, Salsiccia, Alette) continuano ad applicarsi attraverso gli
      stessi setter di `WeaponController`, senza modifiche a
      `UpgradeEffectRegistry`.
- [ ] `tests/unit/test_b41_weapon_shapes.gd` e
      `tests/unit/test_ps085_manual_fire_mode.gd` restano verdi **senza
      essere modificati nelle aspettative di comportamento**.
- [ ] `RunContractValidator` continua a validare il wiring dell'arma
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

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9
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

## Documenti sincronizzati

- [ ] `CLAUDE.md` — se il registry degli effetti d'arma diventa un contratto
      architetturale al pari di `AbilityEffectRegistry`/`UpgradeEffectRegistry`.

## Note

Card aperte che toccano lo stesso codice e vanno coordinate:
[PS-190](../4_to_test/PS-190-centralizza-letture-e-filtri-upgrade.md)
(centralizzazione dei filtri upgrade),
[PS-121](../4_to_test/PS-121-carte-ripetibili-sature-escono-dal-pool.md),
[PS-160](../4_to_test/PS-160-rendi-competitivi-upgrade-velocita.md),
[PS-085](../4_to_test/PS-085-introduci-sparo-manuale-con-secondo-joystick.md),
[PS-093](../4_to_test/PS-093-nuovi-assi-scarto-base-personaggi.md).
