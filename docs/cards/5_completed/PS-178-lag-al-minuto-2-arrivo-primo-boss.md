---
id: PS-178
titolo: Diagnostica e riduci il lag prima del minuto 2
tipo: perf
area: gameplay
stato: COMPLETATO
priorita: alta
dipende_da: []
origine: test reale su Pixel 9 della v0.3.0, 2026-09-15
creato: 2026-09-15
aggiornato: 2026-09-19
---

# PS-178 — Diagnostica e riduci il lag prima del minuto 2

## Contesto

Il proprietario segnala un rallentamento importante poco prima del minuto 2
su **Pixel 9 con Marghe**; abilita' e potenziamenti esatti non sono noti.
Il primo Boss compare a 120 s, ma la coincidenza non dimostra una causa.
Le misure CPU Windows mostrano un costo crescente della separazione dei
nemici gia' prima del Boss, anche senza attivare il clone.

## Comportamento atteso

Ridurre il costo della separazione conservando forza, limite di velocita',
spawn e bilanciamento. Verificare sul Pixel la fluidita' fino e oltre il
primo Boss prima di dichiarare risolto il sintomo originale.

## Criteri di accettazione

- [x] Misurata la finestra 90-126 s di una run reale sintetica con Marghe,
      con e senza abilita', distinguendo RUNNING da BOSS_INTRO.
- [x] Isolato un collo di bottiglia CPU riproducibile: la separazione usa
      celle troppo grandi e visita gran parte dell'orda per ogni nemico.
      Introdotta da PS-171; PS-174 ha corretto isolamento e ordine, senza
      cambiare l'ampiezza della ricerca. Questo attribuisce il costo al
      codice, non prova quale build abbia causato il sintomo sul Pixel.
- [x] Query confrontata con tutte le coppie, raggi fino a 190 px, confini
      negativi, movimento e knockback nello stesso tick, morti e controller
      diversi. Tolleranza 0,001; determinismo PS-175 preservato.
- [x] Confronto prima/dopo e regressioni finali registrati sotto.
- [ ] Verificato sul Pixel 9 il frame time e il giudizio percettivo durante
      la finestra critica. Budget di riferimento: 16,7 ms a 60 FPS;
      registrare anche p95, massimo, popolazione e possibili hitch GPU.

## Ambito

- `scripts/actors/base_enemy.gd`: ricerca spaziale per separazione.
- Sonda di run `tools/_diagnose_boss_lag_ps178.gd` e microbenchmark
  `tools/_profile_enemy_separation_ps178.gd`.
- Test GUT, mappa delle regressioni e contratto nemici.

## Verifica

Strumenti riproducibili, eseguire singolarmente senza altri benchmark:

```powershell
godot_console --headless --path . --script tools/_diagnose_boss_lag_ps178.gd -- --friend=marghe --run-seed=20260915 --mobile-profile --tag=marghe-clone
godot_console --headless --path . --script tools/_diagnose_boss_lag_ps178.gd -- --friend=marghe --run-seed=20260915 --mobile-profile --no-active-ability --tag=marghe-no-ability
godot_console --headless --path . --script tools/_profile_enemy_separation_ps178.gd
.\tools\run-milestone-checks.ps1 -Milestone PS-178 -Profile Focused -FocusedSmoke tests/unit/test_ps178_enemy_separation_query.gd,tests/unit/test_ps171_enemy_overlap_separation.gd -NoCache
```

La sonda mantiene vivo il Player, guida un'orbita, sceglie il primo upgrade
e chiude i modali. Usa una deadline reale indipendente dal tempo di run;
non riproduce la build ignota del proprietario. CSV e log locali in
`exports/diagnostics/`; nessun asset generato entra nel commit.

### Misure baseline, Windows headless

Godot 4.7.1, Windows headless, Intel Core i7-8700 a 3,20 GHz.
Runtime baseline dal commit `51862ed` (uguale a `fff4dcb`); strumenti
diagnostici della presente card. Una run per configurazione, senza altri
benchmark concorrenti. Seed 20260915, profilo mobile, Marghe; finestra 90-126 s:

| Percorso | p95 frame RUNNING | Massimo fisica | Nemici massimi | p95 BOSS_INTRO |
|---|---:|---:|---:|---:|
| Clone attivo | 263,077 ms | 70,830 ms | 182 | 16,719 ms |
| Senza abilita' | 236,781 ms | 81,130 ms | 174 | 16,688 ms |

File `ps178-marghe-clone.*`, `ps178-marghe-no-ability.*`.
La fisica e' il monitor Godot, mentre frame_ms misura il tempo reale fra
process_frame: non sono la stessa metrica. Headless non misura la GPU.

Microbenchmark a popolazione fissa, media di 20 query complete; un passo
fisico manuale di tutti gli attori a seguire:

| Nemici | Separazione prima | Separazione dopo | Passo attori prima | Passo attori dopo |
|---|---:|---:|---:|---:|
| 50 | 1,918 ms | 0,547 ms | 2,440 ms | 1,193 ms |
| 150 | 17,563 ms | 2,524 ms | 18,590 ms | 5,176 ms |
| 250 | 48,578 ms | 3,729 ms | 54,008 ms | 7,418 ms |

File `ps178-cpu-probe-baseline.log` e `ps178-cpu-probe-final.log`.
Le popolazioni sono identiche; le run complete possono divergere per
ordine di somma e tempi dell'engine e non costituiscono un replay bit a bit.

### Confronto della run e regressioni

- Primo tentativo (sole celle piu' piccole, `ps178-marghe-optimized.*`):
  p95 229,724 ms, 210 nemici massimi. Guadagno insufficiente: verificato
  il costo per candidato e rimossi i getter e le chiamate GDScript ripetute
  per ciascuna coppia. Dati propri e spareggio restano costanti nella query.
- Versione finale con clone (`ps178-marghe-final-clone.*`): p95 RUNNING
  **41,692 ms**, massimo 221,999 ms, fisica massima 60,730 ms, fino a
  234 nemici. BOSS_INTRO p95 29,879 ms. Il calo del p95 e' circa 84%,
  ma i picchi residui e il budget 60 FPS non raggiunto impediscono di
  dichiarare il sintomo risolto, anche sul solo PC headless.
- Versione finale senza abilita' (`ps178-marghe-final-no-ability.*`):
  p95 RUNNING **31,086 ms**, massimo 52,638 ms, fisica massima 37,150 ms,
  fino a 239 nemici. BOSS_INTRO p95 29,533 ms.
- **Residuo nella finestra critica:** restringendo il CSV a RUNNING
  110-120 s, p95 con clone **139,074 ms**, senza abilita' **31,295 ms**.
  Nella baseline erano rispettivamente **275,145 ms** e **271,307 ms**:
  circa -49% con clone e -88% senza abilita' in questa finestra specifica.
  Il p95 dell'intera finestra pesa meno i tratti lenti, che producono meno
  campioni. Il massimo con clone cade a 117,367 s, con 228 nemici e un
  effetto attivo. Non attribuire automaticamente il residuo al codice del
  clone: cambiano distribuzione, bersagli e percorso della popolazione.
  La prossima misura sul Pixel deve distinguere costo di separazione,
  movimento/collisioni dell'orda raccolta sull'esca e rendering. Nessun
  cambiamento speculativo al clone o allo spawn viene applicato qui.
- Focused `20260916-145159-PS-178`: 2 script / 8 casi verdi, inclusa la
  modifica del raggio nella stessa frame fisica. Mutazione temporanea che
  omette l'aggiornamento dei bucket (`20260916-145249-PS-178`): falliscono
  esattamente i 2 casi movimento/knockback su 5. Ripristinato il sorgente.
- Release `20260916-145813-PS-178`: **151 script / 474 casi verdi**, zero
  pending e zero marker SCRIPT ERROR/FATAL EXCEPTION/SMOKE_FAIL/CONTRACT_FAIL.
  Contratto PowerShell del runner, toolchain, export e smoke Windows verdi.
  Android: marker `[ DONE ] export` presente; il runner recupera l'esito
  dell'exporter tramite APK completo, stabile, firmato e staticamente valido
  (`recovered=1`), senza inventare un'uscita naturale riuscita.
  APK ARM64, package `com.ilgioco.pidgeonsurvivor`, API 31-36, 73.420.008 byte,
  SHA-256 `91F1A044B8C644D429A9FAE2CCC9F9352D5E79E20C8CC3155B60BC336FD6CC0A`.
  Rimangono i messaggi di shutdown gia' presenti nella baseline GUT:
  11/26/8 RID, 232 ObjectDB, 68 risorse e pagine Variant PagedAllocator;
  conteggi invariati, non problemi dichiarati risolti da questa card.
- Full finale senza cache `20260916-150244-PS-188`: **151 script / 474
  casi nello stesso processo GUT**, zero fallimenti/pending e zero marker
  di errore. Copre il determinismo PS-175 dopo tutte le fixture precedenti,
  oltre ai cinque Full gia' verdi prima dell'ottimizzazione PS-178.

## Gate manuali

- [ ] Windows con rendering e controllo percettivo.
- [x] Export/runtime Windows automatizzato.
- [x] Export e validazione statica APK.
- [ ] Installazione e runtime fisico Pixel 9: `adb devices -l` senza device.
- [ ] Giudizio del proprietario sul sintomo originale con Marghe.

## Decisioni

- **2026-09-15 — Diagnosi iniziale solo statica.** La precedente sessione
  remota non disponeva di Godot. Aveva osservato l'assenza di una soglia
  nello spawn a 120 s e ipotizzato un primo upload GPU del Boss. Nessuna
  delle due osservazioni escludeva un costo crescente della densita'.
  I criteri allora spuntati come assenza di regressioni erano troppo forti:
  vengono sostituiti dalle misure reali, senza dichiarare provata la GPU.
- **2026-09-16 — Misurare prima di cambiare il gameplay.** Il difetto della
  prima sonda era il timeout basato sul tempo logico, bloccato nei modali.
  Corretto prima della diagnosi; verificata anche l'uscita wall_timeout.
- **2026-09-16 — Celle da 64 px e ricerca adattiva.** Il massimo raggio
  presente delimita le celle da visitare. Il bucket segue il movimento
  nello stesso tick, compreso il knockback; ordine per cella e instance_id
  stabile. Un cambio del raggio invalida la cache del controller.
  Nessun nuovo manager, nessuna riduzione di nemici o danni.
  Il caso di tutti i nemici sovrapposti resta quadraticamente denso.
- **2026-09-16 — Limite delle conclusioni.** Separazione CPU confermata su
  Windows; costo persistente senza clone. Pixel/GPU non misurati e causa
  esclusiva del rallentamento originale ancora da confermare sul device.
- 2026-09-19: chiusa dal proprietario con il passaggio in blocco di tutte le card `IN VERIFICA` a `COMPLETATO`.

## Documenti sincronizzati

- [x] `docs/enemies-bosses.md`, board e mappa delle regressioni.
- Spawn, soglie e bilanciamento invariati: nessuna modifica a
  `docs/systems-difficulty.md` necessaria.

## Note

Branch di revisione `refactor/test-cleaning-2026-09-16`, senza merge/push.

Seguito operativo richiesto dal proprietario:
[PS-189 — lag residuo con Marghe](../2_to_do/PS-189-lag-residuo-marghe-orda-clone.md).
La nuova card isola il costo residuo nella finestra critica e confronta
popolazioni identiche; i gate fisici qui aperti restano da verificare.
