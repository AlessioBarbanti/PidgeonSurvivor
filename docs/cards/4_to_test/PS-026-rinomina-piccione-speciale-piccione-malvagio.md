---
id: PS-026
titolo: Rinomina Piccione Speciale in Piccione Malvagio
tipo: chore
area: gameplay
stato: IN VERIFICA
priorita: media
dipende_da: []
origine: B22
creato: 2026-08-30
aggiornato: 2026-08-31
---

# PS-026 — Rinomina Piccione Speciale in Piccione Malvagio

## Contesto

Il Boss baseline viene ancora presentato con il nome `Piccione Speciale`.

Il nome non comunica correttamente il ruolo antagonista del Boss e deve essere sostituito con **Piccione Malvagio**.

## Comportamento atteso

Ogni testo pubblico che identifica il Boss baseline come `Piccione Speciale` deve mostrare **Piccione Malvagio**.

La modifica riguarda il nome visibile al giocatore e la documentazione autorevole. ID tecnici, path e riferimenti interni possono restare invariati quando la loro modifica non è necessaria al risultato pubblico.

Le varianti `Evil <Nome>` restano invariate.

## Criteri di accettazione

- [x] La Boss Intro mostra `Piccione Malvagio` per il Boss baseline. Implementato
      (`data/bosses/first_boss.tres:13` + `get_safe_title()`) e coperto dal
      test `tests/unit/test_ps026_boss_baseline_display_name.gd`, verde su
      Windows il 2026-08-31.
- [x] Ogni altra UI runtime che mostra il nome del Boss baseline usa `Piccione Malvagio`.
      `get_safe_title()` è l'unico punto che alimenta Boss Intro ed EndScreen
      (`scripts/bosses/boss_definition.gd:63-66`,
      `scripts/bosses/boss_encounter.gd:439`, `scripts/ui/end_screen.gd:31-39`);
      il test composto verifica la Boss Intro.
- [x] Nessun testo pubblico runtime mostra ancora `Piccione Speciale`. Il grep
      di repository conferma zero occorrenze nei dati e nel codice runtime;
      le occorrenze residue sono prosa interna di test/guard o note storiche.
- [x] Le controparti `Evil <Nome>` conservano i propri nomi. Non toccate:
      restano derivate da `FriendDefinition.evil_display_name`
      (`scripts/content/friend_definition.gd:47,233-237`), indipendenti dal
      titolo del Boss baseline.
- [x] Il cambio di nome non modifica statistiche, sprite, hitbox, pattern o
      probabilità di selezione del Boss. Unica riga toccata in
      `first_boss.tres` è `title`; `evil_boss_chance` resta `0.25`
      (`scripts/bosses/boss_encounter.gd:22`, invariato).
- [x] Gli ID tecnici e i path non vengono rinominati senza una necessità
      esplicita. `id = &"special_pigeon"` invariato.
- [x] Restart e selezione seedata dei Boss restano invariati. Nessuna modifica
      a `resolve_variant`/`resolve_definition_for_event`; il test focused e la
      `Full` corrente coprono rispettivamente restart/Evil e la suite B22.

## Ambito

- `BossDefinition` del Boss baseline.
- Copy della Boss Intro e delle UI che mostrano il nome.
- Documentazione che usa il nome pubblico del Boss baseline.
- Test di contenuto relativi ai Boss.

Non modificare:

- asset grafico del Boss;
- probabilità di sostituzione con un `Evil <Nome>`;
- pattern e statistiche;
- ID tecnici stabili salvo necessità dimostrata;
- nomi delle varianti Evil.

## Verifica

- Test: `tests/unit/test_ps026_boss_baseline_display_name.gd` (`extends
  GutGameplayTest`). La card indicava originariamente uno smoke a script
  `SceneTree` con marker `EVIL_PIGEON_NAME_SMOKE_OK`: quel contratto non
  esiste più (vedi `docs/verification-workflow.md`, tutti i test vivono in
  `tests/unit/test_*.gd` con report GUT), quindi la formulazione è corretta
  qui invece di crearne uno stile obsoleto.
- Profilo minimo prima della chiusura: `Relevant` con
  `-FocusedSmoke tests/unit/test_ps026_boss_baseline_display_name.gd`.
- **2026-08-31 — focused PASS su Windows**: 2/2 test, zero failure JUnit,
  log `20260831-233847-PS-026`; nessun marker bloccante.
- **2026-08-31 — `Full` PASS sull'HEAD runtime corrente**: 240/240 test di
  regressione, incluso `test_ps026_boss_baseline_display_name.gd` 2/2;
  toolchain e project smoke verdi, log `20260831-230124-PS-039`.

## Gate manuali

- [x] Runtime Windows — project smoke del profilo `Full` superato.
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: genera Boss baseline → verifica nome in Boss Intro e HUD)
- [x] Controllo percettivo richiesto: no

## Decisioni

- **2026-08-30 — Il Boss baseline si chiama pubblicamente `Piccione Malvagio`.** Il precedente nome `Piccione Speciale` viene rimosso dal copy rivolto al giocatore.
- **Sostituisce:** nome pubblico `Piccione Speciale`.
- **2026-08-31 — Unico punto di verità del nome pubblico.** Il nome vive solo
  in `data/bosses/first_boss.tres:title`; Boss Intro ed EndScreen lo leggono
  entrambi tramite `BossDefinition.get_safe_title()`, quindi una modifica
  localizzata basta senza toccare `boss_ui.gd` o `end_screen.gd`.
- **2026-08-31 — Confine sui test esistenti.** Ho corretto solo l'asserzione
  di `tests/unit/test_b17_friend_content.gd` che confrontava letteralmente il
  titolo pubblico (`get_safe_title() == "PICCIONE SPECIALE"`). I messaggi di
  asserzione in `test_b22_evil_boss_variants.gd`, `test_b30_boss_no_circular_aura.gd`
  e i due controlli interni in `scripts/game/movement_slice.gd:1059,1676` usano
  "piccione speciale" come prosa descrittiva interna, non come copy pubblico:
  restano invariati per non allargare la card oltre il nome mostrato al
  giocatore.
- **2026-08-31 — Verifica automatica eseguita su Windows.** Il contratto GUT
  sostitutivo dello smoke legacy passa sia focused sia nella `Full`; resta
  aperto soltanto il percorso Android dichiarato nei gate.

## Documenti sincronizzati

- [x] `prd.md`: sostituite le tre occorrenze di "piccione speciale" con
  "piccione malvagio" (§3.5A, §3.6).
- [x] `content-approvals.md`: il file non esiste nel repository, nessuna
  sincronizzazione necessaria.
- [x] Nota `*-verification.md`: nessuna nuova nota di verifica creata, in
  linea con le altre card PS-0xx che non ne aprono una dedicata; le evidenze
  restano in questa card.

## Note

Preferire un cambio di contenuto localizzato. Non rinominare automaticamente file e ID storici solo per uniformarli al nuovo copy.

**Stato in verifica (2026-08-31).** Implementazione, focused, suite completa
e project smoke Windows sono chiusi. `adb devices -l` non rileva il Pixel 9:
validazione statica dell'APK e runtime fisico restano aperti, quindi la card
non viene dichiarata `COMPLETATO`.
