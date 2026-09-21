---
id: PS-198
titolo: Progetta e implementa il primo set di armi pilota
tipo: feat
area: gameplay
stato: IN VERIFICA
priorita: alta
dipende_da: [PS-197]
origine:
creato: 2026-09-18
aggiornato: 2026-09-21
---

# PS-198 — Progetta e implementa il primo set di armi pilota

## Contesto

Con il contratto di [PS-196](../5_completed/PS-196-contratto-armi-per-personaggio.md)
e l'impianto neutro di
[PS-197](./PS-197-impianto-arma-per-personaggio-neutro.md), questa
card produce le **prime armi realmente diverse**. Il proprietario ha scelto
(2026-09-18) un set pilota ristretto invece dell'intero cast: se il feel non
cambia davvero, si è buttato poco e l'impianto resta neutro.

Lo scopo del pilota è dimostrare in mano che l'escursione fra armi è
percepibile, restando dentro l'invariante di PS-196 (ogni arma emette
`Projectile`, quindi tutte le Specialità di Barb restano valide).

## Il set pilota

Quattro armi, approvate dal proprietario il 2026-09-18:

| Personaggio | Nome | Concept | Assi che lo distinguono |
|---|---|---|---|
| Magno | **Carbonella** | un carbone ardente singolo, lento e massiccio, portata corta | ritmo lento; corpo grande; portata corta |
| Bea | **Spiedo** | due spiedi sottili alternati destra/sinistra, cadenza alta, portata lunga | ritmo rapido alternato; geometria alternata; corpo sottile e veloce |
| Alea | **Cavatappi** | colpo singolo perfettamente preciso che **si sdoppia subito dopo la volata** in due proiettili divergenti | traiettoria che diverge in volo; emissione singola che diventa doppia; ritmo medio |
| Migi | **Graticola** | frammenti di graticola che **orbitano** attorno al personaggio | traiettoria orbitale; emissione tutt'intorno senza mira frontale; portata fissa |

Tutti i nomi stanno nel registro utensile/brace imposto da PS-196 e non usano
parole della carne, riservate alle Specialità.

**Nota di leggibilità su Migi**: la sua passiva Guscio Tartarughina è già fatta
di *placche* che annullano i colpi
([docs/characters.md:136](../../characters.md)). Le placche della passiva sono
aderenti al personaggio, i frammenti della Graticola orbitano a distanza: la
distinzione visiva fra i due va tenuta netta, altrimenti il giocatore non
capisce quale dei due sistemi sta guardando.

## Comportamento atteso

Giocando due personaggi del set pilota di seguito, la differenza di attacco
base è immediatamente percepibile senza leggere numeri, e ogni Specialità di
Barb continua a produrre un effetto sensato su entrambi.

## Criteri di accettazione

- [x] Ogni arma pilota differisce da ciascuna delle altre su **almeno tre**
      dei cinque assi dichiarati in PS-196.
- [x] Ogni arma pilota è dichiarata interamente come dati
      (`WeaponDefinition` + parametri) più un `effect_id` gestito dal
      `WeaponEffectRegistry`: nessuna logica nei `.tres`.
- [x] Tutte e cinque le Specialità legate al proiettile (Arrosticini,
      Tagliata, Fiorentina, Salsiccia, Alette) producono un effetto
      osservabile su **ogni** arma pilota; per Alette su un'arma priva di
      direzione di mira, la reinterpretazione della dispersione è quella
      dichiarata in PS-196 e non un'omissione silenziosa.
- [x] Le armi pilota restano comparabili fra loro: il tetto aritmetico di
      `WeaponController.calculate_full_build_kill_rate_per_second()` è
      calcolato per ciascuna e lo scarto fra la più forte e la più debole
      resta entro un margine dichiarato in `Decisioni`.
- [x] I personaggi non toccati dal pilota continuano a usare l'arma di
      default, senza alcuna differenza rispetto a oggi.
- [x] Sparo automatico e manuale (PS-085) funzionano su ogni arma pilota.

## Ambito

- `data/weapons/`: una `WeaponDefinition` per arma pilota.
- `data/friends/*.tres`: assegnazione dell'arma ai soli personaggi del pilota.
- `scripts/combat/`: nuovi `effect_id` di emissione nel `WeaponEffectRegistry`
  e, se serve, un campo di traiettoria su `Projectile` (dritta/curva/orbitale)
  — mai una sottoclasse per personaggio.
- Non toccare:
  - `UpgradeEffectRegistry` e i setter delle Specialità;
  - l'arma di default e i personaggi fuori dal pilota;
  - i moltiplicatori di `FriendDefinition` (il ribilanciamento degli scarti
    base è materia separata, vedi Note);
  - icone e nomi a schermo: sono card `art` e di integrazione UI separate
    (PS-090), da aprire quando i nomi sono approvati.

## Verifica

- Smoke: `tests/unit/test_ps198_pilot_weapons.gd` → marker
  `PS198_PILOT_WEAPONS_SMOKE_OK` — per ogni arma pilota verifica emissione
  attesa, applicazione delle cinque Specialità legate al proiettile, e lo
  scarto di kill-rate entro il margine dichiarato.
- Profilo minimo prima della chiusura: `Full`.

## Gate manuali

- [x] Runtime Windows — `windows-export` e `windows-runtime` PASS
- [x] Validazione statica APK — `android-static` PASS (l'export e' uscito
      sul marker `[ DONE ] export` con l'APK gia' completo, caso noto Windows)
- [ ] Runtime fisico Pixel 9 — **aperto**: nessun device collegato
      (`adb devices` vuoto, `android_runtime=OPEN_ADB_SERVER_NOT_RUNNING`)
- [ ] Controllo percettivo richiesto: sì — è l'unico vero criterio del
      pilota: giocare due personaggi del set di seguito e sentire che
      l'attacco base è un'altra cosa

## Decisioni

- **2026-09-18 — Set pilota invece dell'intero cast**, scelto dal
  proprietario: valida l'idea prima di impegnare otto armi, e mantiene
  l'impianto di PS-197 reversibile se il feel non convince.
- **2026-09-18 — Personaggi e nomi approvati**: Magno/Carbonella,
  Bea/Spiedo, Alea/Cavatappi, Migi/Graticola.
- **2026-09-18 — L'orbitale è passato da Alea a Migi**, su scelta del
  proprietario: su Alea si sarebbe sovrapposto alla sua attiva Gran Piroetta,
  già un melee rotante attorno al personaggio, rendendola meno riconoscibile.
  Su Migi è invece coerente col suo ruolo di controllo dello spazio
  circostante.
- **2026-09-18 — Scartata per Alea la "traiettoria ubriaca"** (oscillazione
  irregolare del colpo), su osservazione del proprietario: replicava la
  dispersione di mira di Alette (`beer_signature`, ±24°) e sommata a essa
  avrebbe reso il personaggio soltanto impreciso. Sostituita dal Cavatappi,
  che parte perfettamente preciso e si sdoppia a metà corsa — "l'ubriaco non
  ha la mira che trema, vede doppio". Il caso ha prodotto la regola generale
  di non sovrapposizione ora in PS-196.
- **2026-09-18 — Il pilota è salito da tre a quattro armi** come conseguenza
  dello spostamento dell'orbitale su Migi (Alea resta nel set con un concept
  proprio). Se il proprietario preferisce restare a tre, il candidato allo
  stralcio è il Cavatappi: è il più sottile dei quattro, mentre
  Carbonella/Spiedo/Graticola coprono già l'escursione massima
  (lento e pesante / rapido e sottile / orbitale).
- **2026-09-21 — Margine ammesso sul tetto di kill-rate: 10%**, misurato su una
  build di riferimento dichiarata (Alette `×1,25` di cadenza, danno `×1,5`,
  Tagliata a rango 2, Arrosticini a rango 3 con decadimento `0,7`, nemico da
  100 HP). Le quattro armi sono state calibrate *a partire* da quel tetto
  invece che a sensazione: il prodotto `cadenza × danno × emissioni per colpo ×
  somma del decadimento di perforazione` è tenuto costante, ed è stato fissato
  sul valore della Scintilla condivisa (≈5,70 kill/s) perché nessun personaggio
  del pilota risultasse indebolito dall'avere un'arma propria. Lo scarto
  effettivo fra la più forte e la più debole è dello **0,5%**; il margine al 10%
  è lo spazio lasciato al ritocco futuro, non la tolleranza consumata.
- **2026-09-21 — Il Cavatappi emette due proiettili sovrapposti**, non uno che
  si duplica a metà corsa. Motivazione: duplicare a runtime avrebbe richiesto
  al proiettile di conoscere la propria scena e il proprio contenitore per
  istanziarne altri; due colpi identici che condividono posizione e direzione
  fino al ritardo dichiarato sono indistinguibili da un colpo solo, e il tetto
  di kill-rate li conta entrambi senza casi speciali. A bruciapelo colpiscono
  tutti e due, ed è voluto: il danno per proiettile è già dimezzato di
  conseguenza.
- **2026-09-21 — La perforazione ora si somma invece di prendere il massimo**
  (`WeaponController.get_effective_pierce_count()`). Con `maxi()`, la Graticola
  — che di suo attraversa 3 nemici — avrebbe reso invisibili i primi due
  ranghi di Arrosticini, violando il criterio di osservabilità di questa card.
  Per ogni arma con perforazione base 1, cioè tutte le altre, il risultato è
  identico a prima.
- **2026-09-21 — `RunContractValidator` confronta la forma d'attacco iniziale
  con la forma base dell'arma**, non più con il singolo proiettile. Il controllo
  non è allentato: continua a fallire se una Specialità ha già modificato la
  forma a inizio run, ma smette di leggere come errore una perforazione che
  appartiene all'arma.
- **2026-09-21 — Due regressioni sono state aggiornate, non aggirate.**
  `test_b41_weapon_shapes.gd` misurava le forme d'attacco su Magno, che ora
  impugna la Carbonella: il suo colpo singolo (35,7 danno contro un bersaglio
  da 10 HP) uccide il bersaglio di riferimento e rende invisibile la
  perforazione da provare. La fixture ora equipaggia Zat, che usa ancora la
  Scintilla, dichiarando così l'intenzione che il test aveva implicita.
  `test_ps160_speed_upgrade_value.gd` asseriva l'identità con
  `default_weapon_profile.tres` "non una variante per personaggio": ora
  asserisce che l'arma sotto misura sia quella dichiarata dal personaggio
  equipaggiato, che è lo stesso controllo dopo che le varianti esistono.

- **2026-09-22 — Cavatappi ritarato dopo la prova sul Pixel 9: lo sdoppiamento
  non avveniva quasi mai.** Il proprietario ha segnalato di non capire l'arma di
  Alea. Diagnosi, non gusto: con `stretch/aspect="expand"` su base 1280×720, il
  Pixel 9 (2424×1080) mostra un'area di **1616×720 unità mondo**, cioè 808 px
  fino al bordo laterale e **360 px fino al bordo alto/basso**. Lo sdoppiamento
  cadeva a `0,8 s × 820 px/s` = **656 px**: sparando in verticale il colpo usciva
  dallo schermo a 360 px e si apriva 296 px fuori campo, e sparando di lato si
  apriva nell'estrema periferia. Soprattutto, la mira automatica prende il nemico
  *più vicino* e i nemici camminano addosso al Player: a 820 px/s il colpo copre
  400 px in 0,49 s, quindi colpiva e moriva **prima** degli 0,8 s. Il tratto
  caratterizzante dell'arma non era mai entrato in scena.
  Nuovi valori: `split_delay_seconds` 0,8 → **0,22** (≈180 px, ben dentro la
  mezza altezza di 360 px) e `divergence_degrees` 17° → **10°**. Gli stessi
  valori erano cablati come default nel `WeaponEffectRegistry` e sono stati
  allineati: il default codificava il difetto.
- **2026-09-22 — Accettata la dispersione come identità, non come difetto.**
  Scelta del proprietario fra tre uscite. Il vincolo è strutturale e va
  registrato perché non si elimina tarando: uno sdoppiamento visibile presto
  implica due metà che si allargano dopo. A 10°, su un nemico a 400 px le due
  metà arrivano separate di ~77 px, cioè gli passano ai lati. Il Cavatappi
  diventa quindi un'arma di copertura più che di precisione sul bersaglio
  singolo — coerente col profilo glass cannon e caotico di Alea. Le alternative
  scartate erano una divergenza sottile a 5° (che tiene la precisione ma rende
  discreto l'effetto) e lo stralcio dell'arma.
- **2026-09-22 — Il tetto di kill-rate non si muove.** Le emissioni per colpo
  restano due e il danno per proiettile è invariato: la ritaratura tocca solo
  *quando* e *quanto* le due metà divergono, non quanta potenza portano. Il
  margine dichiarato sopra resta valido senza ricalibrare le altre armi.

## Documenti sincronizzati

- [x] `docs/characters.md` — l'arma entra nell'identità dei personaggi del
      pilota.

## Note

Comandi di verifica e marker usati come evidenza:

```powershell
.	ools
un-milestone-checks.ps1 -Milestone PS-198 -Profile Focused `
  -FocusedSmoke tests/unit/test_ps198_pilot_weapons.gd -RefreshEditor
.	ools
un-milestone-checks.ps1 -Milestone PS-198 -Profile Full
.	ools
un-milestone-checks.ps1 -Milestone PS-198 -Profile Release
```

`Full` → `status=PASS focused=4/4 regression=161/161 toolchain=1/1`, marker
`PS198_PILOT_WEAPONS_SMOKE_OK` e `PS197_WEAPON_DEFINITION_WIRING_SMOKE_OK`,
zero occorrenze di `SCRIPT ERROR` o `FATAL EXCEPTION`.

`Release` → `windows=2/2` (export e runtime), `android_static=True`,
`android_runtime=OPEN_ADB_SERVER_NOT_RUNNING`. I tre esiti restano distinti:
Windows runtime è chiuso, la validazione statica dell'APK è chiusa, il
runtime fisico su Pixel 9 è **aperto** e non è stato surrogato da nulla.

Gate ancora aperti, entrambi di competenza del proprietario:

1. **Runtime fisico Pixel 9** — richiede il device collegato.
2. **Controllo percettivo** — è l'unico vero criterio del pilota: giocare due
   personaggi del set di seguito e sentire che l'attacco base è un'altra cosa.
   Nessun test automatico lo sostituisce.

PS-093 e PS-157 hanno chiuso il proprio controllo percettivo quando tutto il
roster condivideva un'arma sola: quel presupposto qui cade, e i due giudizi
andranno rifatti.


Il ribilanciamento degli scarti base per personaggio resta fuori da questa
card ma andrà rivisitato dopo: le verifiche percettive ancora aperte di
[PS-093](../5_completed/PS-093-nuovi-assi-scarto-base-personaggi.md) e
[PS-157](../5_completed/PS-157-ricalibra-difficolta-primi-cinque-minuti.md)
assumono che tutti i personaggi condividano la stessa arma, quindi vanno
riverificate una volta che le armi divergono.

Le card `art` per le icone delle armi e la card di integrazione UI (nome e
icona nel selettore personaggi e nel pannello build in pausa di
[PS-164](../5_completed/PS-164-mostra-build-corrente-in-pausa.md)) si aprono
quando i nomi sono approvati, non prima.
