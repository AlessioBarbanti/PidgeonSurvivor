---
id: PS-198
titolo: Progetta e implementa il primo set di armi pilota
tipo: feat
area: gameplay
stato: BLOCCATO
priorita: alta
dipende_da: [PS-197]
origine:
creato: 2026-09-18
aggiornato: 2026-09-18
---

# PS-198 — Progetta e implementa il primo set di armi pilota

## Contesto

Con il contratto di [PS-196](./PS-196-contratto-armi-per-personaggio.md)
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
| Alea | **Cavatappi** | colpo singolo perfettamente preciso che **a metà corsa si sdoppia** in due proiettili divergenti | traiettoria che diverge in volo; emissione singola che diventa doppia; ritmo medio |
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

- [ ] Ogni arma pilota differisce da ciascuna delle altre su **almeno tre**
      dei cinque assi dichiarati in PS-196.
- [ ] Ogni arma pilota è dichiarata interamente come dati
      (`WeaponDefinition` + parametri) più un `effect_id` gestito dal
      `WeaponEffectRegistry`: nessuna logica nei `.tres`.
- [ ] Tutte e cinque le Specialità legate al proiettile (Arrosticini,
      Tagliata, Fiorentina, Salsiccia, Alette) producono un effetto
      osservabile su **ogni** arma pilota; per Alette su un'arma priva di
      direzione di mira, la reinterpretazione della dispersione è quella
      dichiarata in PS-196 e non un'omissione silenziosa.
- [ ] Le armi pilota restano comparabili fra loro: il tetto aritmetico di
      `WeaponController.calculate_full_build_kill_rate_per_second()` è
      calcolato per ciascuna e lo scarto fra la più forte e la più debole
      resta entro un margine dichiarato in `Decisioni`.
- [ ] I personaggi non toccati dal pilota continuano a usare l'arma di
      default, senza alcuna differenza rispetto a oggi.
- [ ] Sparo automatico e manuale (PS-085) funzionano su ogni arma pilota.

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

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9
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
- **Aperta** — margine ammesso fra l'arma pilota più forte e la più debole sul
  tetto di kill-rate: da fissare in implementazione e dichiarare qui.

## Documenti sincronizzati

- [ ] `docs/characters.md` — l'arma entra nell'identità dei personaggi del
      pilota.

## Note

Il ribilanciamento degli scarti base per personaggio resta fuori da questa
card ma andrà rivisitato dopo: le verifiche percettive ancora aperte di
[PS-093](../4_to_test/PS-093-nuovi-assi-scarto-base-personaggi.md) e
[PS-157](../4_to_test/PS-157-ricalibra-difficolta-primi-cinque-minuti.md)
assumono che tutti i personaggi condividano la stessa arma, quindi vanno
riverificate una volta che le armi divergono.

Le card `art` per le icone delle armi e la card di integrazione UI (nome e
icona nel selettore personaggi e nel pannello build in pausa di
[PS-164](../4_to_test/PS-164-mostra-build-corrente-in-pausa.md)) si aprono
quando i nomi sono approvati, non prima.
