---
id: PS-207
titolo: Fai arroventare l'Attizzatoio di Lollo, che più va lontano più fa male
tipo: fix
area: gameplay
stato: SCARTATA
priorita: media
dipende_da: [PS-200]
origine:
creato: 2026-09-22
aggiornato: 2026-09-22
---

# PS-207 — Fai arroventare l'Attizzatoio di Lollo, che più va lontano più fa male

## Contesto

L'Attizzatoio (PS-200) parte a 420 px/s e accelera fino a 1092 px/s, ma solo
alla fine della sua vita di 1,9 s. Quasi tutti i colpi prendono un nemico nei
primi 300 px, quando il colpo è ancora lento: in partita sembra un colpo
qualunque. L'accelerazione non ha nemmeno un effetto sul gioco, perché il
danno resta 15,4 a ogni distanza. Il proprietario: "non si capisce qual è la
loro particolarità".

## Comportamento atteso

L'Attizzatoio **si arroventa** mentre vola. Appena partito è una brace scura
e fa poco male; più strada fa, più diventa rovente e più fa male, fino al
bianco incandescente e al danno pieno. Una scia dietro il colpo si allunga
con la velocità. Premia chi tiene i nemici a distanza, e si legge a occhio.

Curva di partenza (dati, per il playtest): danno ×0,7 alla bocca, ×1,5 dopo
500 px di volo, lineare in mezzo.

## Criteri di accettazione

- [x] Un colpo dell'Attizzatoio che colpisce appena partito fa il 70%
      (±1%) del danno del colpo; dopo 500 px di volo il 150% (±1%); a 250 px
      il 110% (±1%). Oltre i 500 px resta al 150%.
- [x] Il moltiplicatore vale anche per i colpi che perforano o rimbalzano
      grazie alle Specialità di Barb, applicato sopra il loro calo.
- [x] Il colore del colpo passa in modo continuo da brace scura (appena
      partito) a bianco rovente (500 px), e la scia dietro il colpo si allunga
      con la velocità.
- [x] Danno iniziale, danno finale e distanza di arroventamento stanno in
      `data/weapons/attizzatoio.tres` (`effect_parameters`), non nel codice.
- [x] Le altre sette armi, compresa l'altra traiettoria a rampa (Soffietto),
      colpiscono e si vedono esattamente come oggi.
- [x] Il tetto di kill-rate di PS-200 resta rispettato (il calcolo usa il
      danno nominale dei dati, che resta 15,4).

## Ambito

- `scripts/combat/projectile.gd`: distanza percorsa, moltiplicatore di danno
  in `_current_hit_damage()`, colore e scia per la traiettoria `building`.
- `data/weapons/attizzatoio.tres`: parametri dell'arroventamento; descrizione.
- `docs/characters.md`: sezione Lollo, arma.
- Non toccare: `WeaponController` e `WeaponEffectRegistry` (i parametri
  arrivano già interi al proiettile), `UpgradeEffectRegistry`, le altre armi,
  il danno nominale dell'Attizzatoio, `RunController`.

## Verifica

- Test: `tests/unit/test_ps207_attizzatoio_heat.gd` → marker
  `PS207_ATTIZZATOIO_HEAT_OK`.
- Regressioni: PS-200 (`test_ps200_cast_weapons.gd`), B05 (proiettile),
  aggiornare `tools/milestone-test-map.json`.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows (Lollo: colpi vicini e lontani, colore e scia)
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: stessa partita con Lollo, leggibilità
      del colore sul telefono)
- [ ] Controllo percettivo richiesto: sì (colore e scia, agente
      `direttore-artistico`; sensazione di gioco dal proprietario)

## Decisioni

- **2026-09-22 — Scartata, superata da PS-208.** Subito dopo l'implementazione
  il proprietario ha scelto che Lollo usi sempre l'arma del personaggio
  copiato da Cosplay Casuale: l'Attizzatoio non si spara più in partita e
  resta solo come ripiego nei dati. Il codice dell'arroventamento
  (`830dbac`) è stato ritirato per non lasciare una meccanica che nessuno
  usa; la card resta come traccia della scelta.
- **2026-09-22 — "Si arroventa".** Scelta del proprietario fra tre opzioni:
  danno che cresce con la distanza più segnale visivo (scelta), solo segnale
  visivo, oppure perforazione legata alla velocità.
- **2026-09-22 — Distanza, non tempo.** Il danno segue i px percorsi, perché
  "più va lontano più fa male" si verifica guardando dove sta il nemico, non
  contando il tempo di volo.
- **2026-09-22 — Colore e scia.** Lo sprite della brace è tinto con
  `modulate` da `HEAT_COLD_COLOR` (0,55; 0,24; 0,14) a `HEAT_HOT_COLOR`
  (1,6; 1,5; 1,3): sopra 1 il colore schiarisce lo sprite verso il bianco. La
  scia è lunga quanto la strada fatta in 0,05 s, quindi segue la velocità:
  ~21 px alla bocca, ~41 px a 700 px di volo. Valori di partenza da
  confermare con il controllo percettivo.
- **2026-09-22 — L'arroventamento si attiva solo con `heat_full_distance`.**
  La traiettoria `building` senza quella chiave resta com'era; il Soffietto
  (`fading`) non la legge. L'esplosione alla morte della Specialità resta sul
  danno nominale: è un effetto della Specialità, non del colpo.
- **2026-09-22 — Nessun asset nuovo.** Colore del colpo e scia sono disegnati
  in codice sopra lo sprite della brace esistente: non serve una card `art`.

## Documenti sincronizzati

- [x] `docs/characters.md` — sezione Lollo, arma Attizzatoio.
- [x] `tools/milestone-test-map.json` — regressioni del nuovo test.

## Note

- Evidenza (2026-09-22):
  - `.	ools
un-milestone-checks.ps1 -Milestone PS-207 -Profile Focused -FocusedSmoke tests/unit/test_ps207_attizzatoio_heat.gd`
    → PASS, 3 test, 74 assert. Marker: `PS207_HEAT_CURVE flown250=254.9 cold_trail=21.0 hot_trail=41.0`,
    `PS207_SPECIALITIES_OK`, `PS207_ATTIZZATOIO_HEAT_OK`.
  - Stesso comando con `-Profile Relevant` → PASS, 13/13 passi (PS-200 e
    B05 compresi, 50 test, 2766 assert), nessun `SCRIPT ERROR` /
    `FATAL EXCEPTION`.

- Rischio da osservare, non un criterio: a bruciapelo Lollo fa il 70% del
  danno, e la sua passiva lo fa muovere molto nella fase di iperfocus.
  Potrebbe dover scappare dai nemici invece di andargli addosso.
