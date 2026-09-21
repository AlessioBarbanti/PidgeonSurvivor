---
id: PS-200
titolo: Completa il cast con il secondo set di armi
tipo: feat
area: gameplay
stato: IN VERIFICA
priorita: alta
dipende_da: [PS-198]
origine:
creato: 2026-09-21
aggiornato: 2026-09-21
---

# PS-200 — Completa il cast con il secondo set di armi

## Contesto

[PS-198](./PS-198-armi-pilota-primo-set.md) ha dimostrato con
quattro armi che l'escursione fra un personaggio e l'altro è percepibile.
Il proprietario ha approvato il 2026-09-21 l'estensione ai quattro
personaggi rimasti — Zat, Aleo, Lollo, Marghe — chiudendo il cast: dopo
questa card nessuno usa più l'arma condivisa `Scintilla`, che resta solo
come fallback dei dati.

L'osservazione che ha guidato la proposta: le quattro armi pilota **non
usano mai il quinto asse** di [PS-196](../5_completed/PS-196-contratto-armi-per-personaggio.md)
(comportamento a fine vita). Tutte si limitano a spegnersi. È lì che restava
lo spazio di progetto più largo, ed è da lì che parte questo set.

## Il secondo set

Quattro armi, approvate dal proprietario il 2026-09-21:

| Personaggio | Nome | Concept | Assi che lo distinguono |
|---|---|---|---|
| Zat | **Paletta** | la paletta da griglia lanciata: va, e a distanza fissa **torna indietro** | traiettoria a ritorno; ritmo lento; corpo largo e piatto |
| Aleo | **Soffietto** | una soffiata di brace che parte forte e **rallenta fino a spegnersi**, portata corta | traiettoria calante; ritmo rapidissimo (secondo del cast); portata corta |
| Lollo | **Attizzatoio** | colpo che parte lento e **accelera** mentre va | traiettoria crescente; ritmo medio; corpo sottile e lento in partenza |
| Marghe | **Marinata** | arriva a fine corsa, **si ferma e resta** a bagnare chi passa | traiettoria che si ancora; comportamento a fine vita; corpo medio |

Tutti i nomi stanno nel registro utensile/brace/condimento imposto da PS-196.

**Legame tematico dichiarato**, perché l'arma non sia decorazione:

- **Paletta / Zat** — Guarigione Ritardata è "quello che perdi torna
  indietro". L'arma dice la stessa frase con un oggetto.
- **Soffietto / Aleo** — lo sbalzo termico è una vampata che si esaurisce; la
  portata corta lo tiene alla distanza dove il Termostato Interno conta.
- **Attizzatoio / Lollo** — eco di Iperfocus ADHD senza duplicarlo: la passiva
  cambia il ritmo di *Lollo*, l'arma cambia la velocità del *colpo* lungo il
  suo volo. Sono due grandezze diverse e non si sommano (vedi Decisioni).
- **Marinata / Marghe** — Sorriso Contagioso marca i nemici vicini *a lei*; la
  Marinata marca un *punto*, ed è il clone di Reggaeton time! ad aiutarla a
  tenerlo. Estende la sua identità nello spazio invece che addosso.

## Comportamento atteso

Giocando due personaggi qualsiasi del cast di seguito, la differenza di
attacco base è immediatamente percepibile, e ogni Specialità di Barb continua
a produrre un effetto sensato su entrambi.

## Criteri di accettazione

- [x] Ogni arma del cast differisce da ciascuna delle altre **sette** su
      almeno tre dei cinque assi dichiarati in PS-196 — non più solo dentro
      il proprio set.
- [x] Ogni arma nuova è dichiarata interamente come dati: nessun nuovo
      `effect_id` di emissione dove la differenza è di sola traiettoria.
- [x] Tutte e cinque le Specialità legate al proiettile (Arrosticini,
      Tagliata, Fiorentina, Salsiccia, Alette) producono un effetto
      osservabile su **ogni** arma nuova.
- [x] Il tetto aritmetico di
      `WeaponController.calculate_full_build_kill_rate_per_second()` resta,
      per tutte e otto le armi del cast, entro il margine del 10% già
      dichiarato in PS-198.
- [x] Sparo automatico e manuale (PS-085) funzionano su ogni arma nuova.
- [x] Nessun personaggio resta sull'arma condivisa `Scintilla`, che sopravvive
      solo come default di `FriendDefinition.weapon_id`.

## Ambito

- `scripts/combat/projectile.gd`: nuove traiettorie (ritorno, calante,
  crescente, ancorata) accanto a `split` e `orbit`.
- `scripts/combat/weapon_effect_registry.gd`: il colpo frontale singolo legge
  la traiettoria dai dati dell'arma, senza un `effect_id` per ognuna.
- `data/weapons/`: una `WeaponDefinition` per arma nuova.
- `data/friends/{zat,aleo,lollo,marghe}.tres`: assegnazione dell'arma.
- `scenes/game/movement_slice.tscn`: registrazione delle quattro armi.
- `docs/characters.md`: l'arma entra nell'identità dei quattro personaggi.
- Non toccare:
  - `UpgradeEffectRegistry` e i setter delle Specialità;
  - le quattro armi pilota e l'arma condivisa;
  - i moltiplicatori di `FriendDefinition`.

## Verifica

- Smoke: `tests/unit/test_ps200_cast_weapons.gd` → marker
  `PS200_CAST_WEAPONS_SMOKE_OK` — matrice degli assi su tutte e otto le armi
  del cast, tetto di kill-rate di tutte e otto entro il margine, e per ogni
  arma nuova emissione attesa, sparo automatico e manuale, e le cinque
  Specialità osservabili sui proiettili emessi.
- Regressioni obbligatorie: `test_ps198_pilot_weapons.gd`,
  `test_ps197_weapon_definition_wiring.gd`, `test_b41_weapon_shapes.gd`.
- Profilo minimo prima della chiusura: `Full`.

## Gate manuali

- [x] Runtime Windows — `windows-export` e `windows-runtime` PASS
- [x] Validazione statica APK — `android-static` PASS (export uscito sul
      marker `[ DONE ] export` con l'APK gia' completo, caso noto Windows)
- [ ] Runtime fisico Pixel 9 — **aperto**: nessun device collegato
      (`adb devices` vuoto, `android_runtime=OPEN_ADB_SERVER_NOT_RUNNING`)
- [ ] Controllo percettivo richiesto: sì — giocare due personaggi qualsiasi
      di seguito e sentire che l'attacco base è un'altra cosa

## Decisioni

- **2026-09-21 — Nessun `effect_id` nuovo.** Tutte e quattro le armi hanno la
  stessa geometria d'emissione dell'arma condivisa (un colpo frontale) e
  differiscono per sola traiettoria: quella è un dato dell'arma, letto dal
  ramo di default di `WeaponEffectRegistry`. Un `effect_id` serve solo dove
  cambia *da dove partono* i colpi, come lo Spiedo alternato o l'anello della
  Graticola.
- **2026-09-21 — `fading` e `building` restano due traiettorie distinte** pur
  condividendo la stessa riga di matematica (un fattore di velocità
  interpolato, minore o maggiore di 1). Sono due scelte di progetto opposte e
  il criterio dei cinque assi di PS-196 le deve poter distinguere: con un solo
  nome `ramp`, Soffietto e Attizzatoio si sarebbero fermati a due assi di
  differenza e avrebbero violato la regola — era il rischio segnalato al
  proprietario in fase di proposta.
- **2026-09-21 — La Marinata non ridanneggia lo stesso nemico.** Un'area che
  colpisce a ripetizione avrebbe richiesto un tick che azzera periodicamente
  `_hit_target_ids`, cioè il primo concetto di danno ripetuto in `Projectile`.
  Il colpo si ferma e basta: bagna fino a quattro nemici *distinti*, uno per
  volta, e si esaurisce. Stessa semantica di danno di sempre, comportamento a
  fine vita nuovo, zero meccanica in più — ed è leggibile in partita, perché
  la marinata finisce.
- **2026-09-21 — La Paletta non ricolpisce al rientro.** `_hit_target_ids`
  glielo impedisce, e l'ho tenuto: azzerarlo all'inversione raddoppierebbe il
  danno su bersaglio singolo e sfonderebbe il tetto di kill-rate. Al rientro
  prende chi si è chiuso alle spalle, che in un survivor è il caso che conta.
- **2026-09-21 — Calibrazione sull'ancora, non a sensazione.** Stesso metodo di
  PS-198: il prodotto `cadenza × danno × emissioni × somma del decadimento di
  perforazione` è tenuto costante sul valore dell'arma condivisa
  (≈5,70 kill/s). Su tutte e otto le armi del cast lo scarto fra la più forte
  e la più debole è dello **0,48%**, contro il margine ammesso del 10%.
- **2026-09-21 — L'arma condivisa resta fuori dalla matrice degli assi.**
  `Scintilla` è la baseline da cui le altre si scostano, non un'ottava
  identità che debba distinguersi dalle altre sette. Va detto perché non è
  gratis: la Carbonella si distingue da `Scintilla` solo su ritmo e corpo,
  cioè due assi. È voluto — la Carbonella è l'archetipo "colpo frontale"
  portato all'estremo — ma se un domani `Scintilla` tornasse in mano a
  qualcuno, quella coppia andrebbe rivista.
- **2026-09-21 — Trovato e corretto un bug vero nella traiettoria ancorata.**
  La prima stesura confrontava `_elapsed` con la durata della corsa dopo
  averlo già incrementato: un frame più lungo della corsa saltava il movimento
  per intero e la Marinata restava incollata alla volata. Ora si muove per la
  sola porzione di passo che cade dentro la finestra. Non era un problema del
  test: sarebbe successo in partita a ogni hitch.
- **2026-09-21 — Due regressioni riagganciate all'arma condivisa.** Chiudendo
  il cast non esiste più un personaggio neutro su cui misurare: in PS-198
  `test_b41_weapon_shapes.gd` era stato spostato su Zat proprio perché usava
  ancora `Scintilla`, e ora Zat impugna la Paletta. Sia b41 sia
  `test_ps197_weapon_definition_wiring.gd` montano adesso l'arma condivisa
  direttamente con `set_weapon_definition()`, il che è anche più onesto: non
  dipendono più da chi per caso non ha un'arma propria. In
  `test_ps198_pilot_weapons.gd` è caduta la clausola "gli altri restano su
  Scintilla", che valeva solo finché il cast era aperto.

## Documenti sincronizzati

- [x] `docs/characters.md`

## Note

Comandi di verifica e marker usati come evidenza:

```powershell
.\tools\run-milestone-checks.ps1 -Milestone PS-200 -Profile Focused ``
  -FocusedSmoke tests/unit/test_ps200_cast_weapons.gd -RefreshEditor
.\tools\run-milestone-checks.ps1 -Milestone PS-200 -Profile Full
.\tools\run-milestone-checks.ps1 -Milestone PS-200 -Profile Release
```

`Full` → `status=PASS focused=4/4 regression=162/162 toolchain=1/1`, marker
`PS200_CAST_WEAPONS_SMOKE_OK`, `PS198_PILOT_WEAPONS_SMOKE_OK` e
`PS197_WEAPON_DEFINITION_WIRING_SMOKE_OK`, zero occorrenze di `SCRIPT ERROR`
o `FATAL EXCEPTION`.

`Release` → `windows=2/2`, `android_static=True`,
`android_runtime=OPEN_ADB_SERVER_NOT_RUNNING`. I tre esiti restano distinti:
Windows runtime chiuso, validazione statica dell'APK chiusa, runtime fisico su
Pixel 9 **aperto** e non surrogato da nulla.

Gate ancora aperti, entrambi di competenza del proprietario:

1. **Runtime fisico Pixel 9** — richiede il device collegato.
2. **Controllo percettivo** — giocare due personaggi qualsiasi di seguito e
   sentire che l'attacco base è un'altra cosa. Nessun test lo sostituisce.

Il nome `Spiedo` (Bea, PS-198) confligge con la lista di parole vietate del
progetto: la decisione è isolata in
[PS-201](../1_idea/PS-201-nome-spiedo-contro-lista-parole-vietate.md) e non
blocca questa card.

Da riverificare ora che tutte e otto le armi divergono:
[PS-093](../5_completed/PS-093-nuovi-assi-scarto-base-personaggi.md) e
[PS-157](../5_completed/PS-157-ricalibra-difficolta-primi-cinque-minuti.md)
hanno **chiuso** il proprio controllo percettivo quando tutto il roster
condivideva un'arma sola. Quei due giudizi non sono piu' garantiti: non sono
gate aperti, sono gate chiusi su un presupposto che questa card ha rimosso. Restano da aprire le card
`art` per le icone (ora otto, non quattro) e l'integrazione UI.
