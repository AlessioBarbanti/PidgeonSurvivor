---
id: PS-173
titolo: Il clone di Marghe (Reggeton time!) spara ai nemici vicini
tipo: feat
area: gameplay
stato: COMPLETATO
priorita: media
dipende_da: []
origine: conversazione del proprietario 2026-09-13
creato: 2026-09-13
aggiornato: 2026-09-19
---

# PS-173 — Il clone di Marghe (Reggeton time!) spara ai nemici vicini

## Contesto

PS-161 ha ritarato la progressione di `Reggeton time!` (Marghe) sul solo asse
"durata del clone" (`3,0s → 8,5s`): è il cambiamento meno percepibile delle
otto attive, perché un'esca che dura di più non si nota a colpo d'occhio come
un raggio che raddoppia o uno spintone che triplica. Il proprietario ha
proposto di dare al clone un vero output offensivo: attacca i nemici mentre è
in vita, non solo al rango massimo.

## Comportamento atteso

Per tutta la propria durata, il clone (`IllusionDecoy`) spara periodicamente
al nemico vivo più vicino, infliggendo danno reale. L'attacco è presente fin
dal rango 1 e cresce di rango in rango (danno e/o cadenza), non è un unlock
riservato al solo rango 5. Il clone resta concettualmente un'esca: non
guadagna vita propria né intercetta danno al posto del Player da questa
modifica.

## Criteri di accettazione

- [x] L'illusione infligge danno periodico al nemico vivo più vicino durante
      tutta la propria durata, fin dal rango 1. Verificato: al rango 1 il
      primo colpo scatta esattamente a `1,6s` (`clone_attack_interval`) e
      infligge `2,0` danni (`clone_attack_damage`) al nemico più vicino.
- [x] Danno e/o cadenza di fuoco crescono in modo monotono dal rango 1 al
      rango 5. Danno `2,0→5,0`, intervallo `1,6s→0,9s`: entrambi gli assi
      crescono, nessun rango intermedio li lascia invariati (vedi tabella
      completa in Decisioni).
- [x] Il proiettile sparato riusa la pipeline `Projectile` già esistente
      (stesso gruppo/collisione dei colpi del Player), non un nuovo canale
      di danno parallelo. Verificato via `try_hit()` sullo stesso
      `Projectile` che il Player usa.
- [x] Il danno dell'illusione è tracciato indipendentemente dall'arma
      automatica del Player: nessuna sovrapposizione di responsabilità con
      `WeaponController`. Verificato: `weapon.get_effective_damage()` resta
      invariato prima/dopo l'attacco del clone.
- [x] A parità di seed e sequenza di spawn, bersagli e colpi restano
      deterministici. Il bersaglio è sempre il nemico vivo più vicino
      (`TargetingSystem.get_nearest_alive`, nessun RNG), coerente col resto
      della run.
- [x] Alla scadenza naturale, alla morte del Boss/fine effetto o al restart,
      gli attacchi si interrompono immediatamente e nessun proiettile
      dell'illusione resta orfano dopo la pulizia degli effetti attivi
      (`AbilityEffectRegistry.clear_active_effects()`). Verificato: dopo
      `clear_active_effects()`, `get_active_effect_count() == 0` (clone e
      proiettile tracciato entrambi rimossi).

## Ambito

- `scripts/abilities/illusion_decoy.gd`: nuovo ciclo d'attacco periodico
  (nessun movimento, l'illusione resta ferma).
- `scripts/abilities/ability_effect_registry.gd`: spawn/tracking del
  proiettile tramite `_effect_parent`/`_track_effect()`, riuso di
  `scenes/combat/projectile.tscn`.
- `data/abilities/marghe_shadow_deception.tres`: nuovi `effect_parameters`
  (`clone_attack_damage`, `clone_attack_interval`) su tutti e cinque i
  ranghi e sul blocco di primo livello (rango 1).
- `docs/prd.md`/`docs/characters.md`: descrizione del nuovo comportamento.
- Non toccare `WeaponController` né la ritaratura delle altre sette attive
  chiusa da PS-161.

## Verifica

- Nuovo GUT: `tests/unit/test_ps173_marghe_clone_attacks.gd` → marker
  `PS173_MARGHE_CLONE_ATTACKS_SMOKE_OK`. 3/3 test verdi.
- Aggiornato `tests/unit/test_b18g_ability_ranks.gd` per i due nuovi
  parametri nella tabella attesa di Marghe.
- Aggiornato `assets/art/vfx/ASSET-MANIFEST.md` (due tabelle) con lo
  SHA-256 aggiornato di `illusion_decoy.gd`: il file traccia gli script che
  generano VFX runtime, e `test_b18m_ability_visuals.gd::test_manifest_contract`
  verifica l'hash a ogni Relevant.
- Profilo minimo prima della chiusura: `Relevant` — eseguito, 11/11 verdi
  (1 focused + 10 di regressione sul gruppo abilità), nessun
  `SCRIPT ERROR`/`FATAL EXCEPTION`.

## Gate manuali

- [x] Runtime Windows
- [x] Validazione statica APK
- [x] Runtime fisico Pixel 9 (percorso: una run con Marghe, osservare il
      clone in combattimento)
- [x] Controllo percettivo richiesto: sì — il proiettile del clone deve
      leggersi chiaramente come "sparo del clone", distinto dall'arma del
      Player.

## Decisioni

- **2026-09-13 — Attacco presente dal rango 1, non solo al rango massimo.**
  Richiesta esplicita del proprietario ("anche non a rank massimo"): l'asse
  identitario di Marghe diventa "il clone attacca", scalando di rango in
  rango come le altre sette attive, invece di un unlock singolo a fine
  curva.
- **2026-09-13 — Riuso di `Projectile` (pipeline alleata esistente) invece
  di un nuovo tipo di proiettile.** Stessa collisione/gruppo dei colpi del
  Player: i nemici colpiti reagiscono in modo identico, nessuna logica di
  danno duplicata.
- **2026-09-13 — Nessun telegraph per lo sparo del clone.** A differenza dei
  nemici (che devono avvisare un colpo in arrivo per equità), un alleato
  del Player non richiede preavviso: il valore aggiunto è il danno, non la
  minaccia da leggere.
- **2026-09-13 — Danno tenuto ben sotto quello dell'arma di Marghe, non
  allo stesso livello.** Segnalato esplicitamente dal proprietario durante
  l'implementazione ("non deve fare gli stessi danni della proprietaria"):
  la prima proposta (rango 5 a `10` danni) coincideva col danno base
  dell'arma condivisa (`default_weapon_profile.damage = 10.0`). Rivista a
  `2,0→5,0` (rango 1→5): a rango 5, mezzo colpo dell'arma base e una
  cadenza (`0,9s`) molto più lenta dei `0,25s` dell'arma, così il clone
  resta un aiuto minore e non un secondo Player. Tabella completa
  (rango: danno / intervallo): `1: 2,0/1,6s`, `2: 2,5/1,45s`,
  `3: 3,0/1,3s`, `4: 4,0/1,1s`, `5: 5,0/0,9s`.
- **2026-09-13 — Nessuna modifica al disegno del clone, solo al
  comportamento.** `illusion_decoy.gd::_draw()` resta invariato; l'hash
  registrato in `ASSET-MANIFEST.md` è stato comunque aggiornato perché il
  manifest traccia il file intero, non solo la funzione di disegno.
- 2026-09-19: chiusa dal proprietario con il passaggio in blocco di tutte le card `IN VERIFICA` a `COMPLETATO`.

## Documenti sincronizzati

- [x] `docs/prd.md`: aggiunto il comportamento d'attacco alla sezione
      Marghe — Reggeton time! (parametri iniziali e nota tecnica) e alla
      sintesi dei ranghi B18G.
- [x] `docs/characters.md`: la riga dell'attiva di Marghe ora menziona
      esplicitamente l'attacco, non solo l'aggro. La riga Boss/Signature
      resta da aggiornare in PS-174 (tocca il lato Evil Marghe).

## Note

Seguito diretto di PS-161 (stessa sessione, stesso filone di ritaratura
delle attive), proposto dal proprietario durante la revisione della card.
