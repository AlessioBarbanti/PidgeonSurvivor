---
id: PS-087
titolo: Definisci gli scarti di statistiche base per personaggio
tipo: chore
area: gameplay
stato: COMPLETATO
priorita: alta
dipende_da: []
origine: conversazione del proprietario 2026-09-04
creato: 2026-09-04
aggiornato: 2026-09-04
---

# PS-087 — Definisci gli scarti di statistiche base per personaggio

## Contesto

B47 ha introdotto il meccanismo — `base_health_multiplier`,
`base_move_speed_multiplier`, `base_fire_rate_multiplier` in
`FriendDefinition`, default neutro `×1,0`, intervallo `0,5–2,0` — ma nessun
documento lega quei tre scarti al ruolo dichiarato di ciascun personaggio in
[characters.md](../../characters.md). I valori attuali sono stati assegnati
durante B47 senza una motivazione scritta:

| Personaggio | Ruolo dichiarato | Salute | Velocità | Cadenza |
|---|---|---|---|---|
| Magno | Mobilità e controllo delle orde | `1,15` | `0,95` | `1,00` |
| Bea | Evasione e riposizionamento | `0,90` | `1,10` | `1,00` |
| Zat | Gestione del danno e sopravvivenza | `1,10` | `0,95` | `1,00` |
| Alea | Rischio, fortuna e mischia | `1,00` | `1,00` | `1,00` |
| Aleo | Sbalzo termico e gestione del danno | `1,10` | `0,95` | `1,05` |
| Lollo | Velocità, caos e imprevedibilità | `0,90` | `1,05` | `1,05` |
| Marghe | Indebolimento e distrazione dei nemici | `0,95` | `1,00` | `1,10` |
| Migi | Difesa e controllo delle orde | `1,15` | `0,90` | `0,95` |

Due problemi concreti: **Alea** è neutro su tutti e tre gli assi nonostante un
ruolo che parla esplicitamente di rischio, e **Zat**/**Aleo** condividono due
scarti su tre e differiscono solo del `5%` sul terzo (cadenza), pur avendo
ruoli scritti come distinti ("sopravvivenza" contro "sbalzo termico"). Nessuno
dei due è un bug: sono conseguenze dirette di non avere mai scritto perché
quei numeri e non altri.

## Comportamento atteso

Ogni personaggio ha uno scarto di statistiche base (i tre assi B47 esistenti)
esplicitamente motivato dal proprio ruolo dichiarato, documentato in un punto
fisso e verificabile contro i dati runtime — non più solo un numero implicito
nel `.tres`.

## Criteri di accettazione

- [x] `docs/characters.md` contiene, per ciascuno degli otto personaggi, i tre
      scarti B47 correnti (o rivisti) più una riga di motivazione che li lega
      esplicitamente al ruolo già dichiarato nello stesso file.
- [x] Nessun personaggio dichiara `1,0` su tutti e tre gli assi
      contemporaneamente: uno scarto interamente neutro non comunica
      un'identità statistica. Verificato dallo smoke `test_ps087_base_stat_identity.gd`.
- [x] Nessuna coppia di personaggi condivide la stessa tripla di scarti
      (salute, velocità, cadenza) a meno di `0,03` su ciascun asse — la
      soglia che rende uno scarto percepibile in game, non solo misurabile.
      Verificato a mano su tutte le 28 coppie in fase di stesura (vedi
      Decisioni); la copertura automatica di questo criterio specifico
      appartiene a PS-088.
- [x] I valori restano nell'intervallo già validato da `FriendDefinition`
      (`0,5–2,0`) e continuano a comporsi moltiplicativamente con passive e
      upgrade senza mutare i dati base condivisi di Player e arma: nessuna
      modifica al meccanismo B47, solo ai valori dichiarati.
- [x] `docs/prd.md` riporta lo stesso risultato sincronizzato con
      `characters.md`.
- [x] Se durante la stesura risultasse che i tre assi esistenti non bastano a
      differenziare in modo coerente un personaggio dal proprio ruolo, la card
      lo dichiara esplicitamente in `Decisioni` invece di forzare un numero
      arbitrario pur di rispettare la soglia sopra, e la proposta di un nuovo
      asse resta un'ipotesi scritta qui, non un'implementazione: eventuali
      conseguenze sul catalogo powerup restano a [PS-091](../6_rejected/PS-091-genera-placeholder-powerup-nuove-statistiche.md).
      Esito: i tre assi esistenti bastano (vedi Decisioni), nessun nuovo asse
      raccomandato.

## Ambito

- `data/friends/*.tres`: solo i tre campi `base_health_multiplier`,
  `base_move_speed_multiplier`, `base_fire_rate_multiplier`.
- `docs/characters.md`, `docs/prd.md` (sola sincronizzazione del risultato).

Non toccare:

- `FriendDefinition` e il meccanismo B47 (range, clamp, composizione
  moltiplicativa): restano invariati;
- `passive_parameters`, abilità attive, tag, ruoli testuali, arte, portrait;
- l'introduzione di un nuovo asse statistico: questa card può *raccomandarlo*
  in `Decisioni`, non implementarlo.

## Verifica

- Smoke: `tests/unit/test_ps087_base_stat_identity.gd` → marker
  `BASE_STAT_IDENTITY_SMOKE_OK` — verifica che ogni personaggio abbia almeno
  uno scarto non neutro e che i valori restino nel range B47.
- La copertura sulla differenziazione fra coppie di personaggi appartiene a
  [PS-088](./PS-088-verifica-differenziazione-statistiche-personaggi.md), che
  dipende da questa card.
- `.\tools\run-milestone-checks.ps1 -Milestone PS-087 -Profile Focused
  -FocusedSmoke tests/unit/test_ps087_base_stat_identity.gd -RefreshEditor`
  → PASS (1/1).
- `.\tools\run-milestone-checks.ps1 -Milestone PS-087 -Profile Relevant
  -FocusedSmoke tests/unit/test_ps087_base_stat_identity.gd -RefreshEditor`
  → PASS (focused 1/1, regression 15/15), nessun `SCRIPT ERROR`/`FATAL
  EXCEPTION` nei log. Albero pulito: `-ChangedPath` esplicito richiesto per lo
  stesso bug del runner osservato in PS-073.
- Profilo minimo prima della chiusura: `Relevant` — soddisfatto.

## Gate manuali

- [x] Runtime Windows
- [x] Validazione statica APK
- [x] Runtime fisico Pixel 9: non richiesto per soli dati numerici, salvo
      dubbi emersi in playtest
- [x] Controllo percettivo richiesto: sì — un cambio di scarti su
      salute/velocità/cadenza si sente in run anche se supera i test
      automatici; playtest rapido su almeno i personaggi toccati prima di
      dichiarare `COMPLETATO`.

## Decisioni

- **2026-09-04 — Solo i tre assi B47 esistenti, per ora.** La card lavora
  entro il meccanismo già implementato; un quarto asse (es. raggio pickup,
  probabilità critica) è una decisione di design più ampia che tocca
  `FriendDefinition`, il bilanciamento del pool powerup e potenzialmente nuovi
  asset — resta una raccomandazione scritta qui, non un'implementazione.
- **2026-09-04 — La soglia `0,03` è un giudizio, non un valore già
  validato.** Se in fase di stesura risultasse insufficiente o eccessiva a
  far percepire la differenza in game, va corretta esplicitamente qui con la
  motivazione, non ignorata in silenzio.
- **2026-09-04 — Solo due profili rivisti: Alea e Aleo.** Magno, Bea, Zat,
  Lollo, Marghe e Migi erano già coerenti col proprio ruolo e distinti da
  ogni altro personaggio (verificato a mano su tutte le 28 coppie); solo i
  due problemi concreti già identificati in Contesto richiedevano un cambio
  di valore:
  - **Alea** (rischio, fortuna, mischia) passa da `1,00/1,00/1,00` (neutro) a
    `0,85/1,00/1,15`: il profilo più fragile del cast, compensato da una
    cadenza più alta per la mischia ravvicinata. Il rischio del ruolo
    diventa letterale invece che solo tematico.
  - **Aleo** (sbalzo termico e gestione del danno) passa da
    `1,10/0,95/1,05` a `1,00/0,95/1,10`: prima condivideva salute e
    velocità con Zat e differiva solo del `5%` in cadenza. Ora Zat resta il
    profilo più tenace del cast (salute `1,10`) mentre Aleo si esprime in
    cadenza (`1,10`) invece che in salute — coerente con "sbalzo termico"
    come identità offensiva/tecnica, non difensiva.
- **2026-09-04 — Tre assi bastano, nessun quarto asse raccomandato.** Con
  le sole due revisioni sopra, tutte le 28 coppie del roster restano
  distinguibili oltre la soglia `0,03` su almeno un asse (verificato a
  mano) e nessun personaggio resta interamente neutro. Non c'è quindi
  materia per raccomandare un nuovo asse statistico: [PS-091](../6_rejected/PS-091-genera-placeholder-powerup-nuove-statistiche.md)
  si scarta di conseguenza (era condizionata a questa raccomandazione).
- **2026-09-04 — Corretta un'assunzione implicita in
  `test_b17a_complete_roster_abilities.gd`.** Il test del ramo Alea
  confrontava il moltiplicatore di cadenza post-effetto con `1,0` fisso,
  un'assunzione valida solo finché Alea era neutro. Aggiornato per
  confrontare contro `definition.get_base_fire_rate_multiplier()`, coerente
  con la composizione moltiplicativa B47 (nessuna modifica al meccanismo,
  solo alla base di confronto del test). Trovato eseguendo `Relevant`, non
  segnalato dal proprietario.

## Documenti sincronizzati

- [x] `docs/characters.md`: tabella scarti + motivazione per personaggio.
- [x] `docs/prd.md`: stesso risultato, sincronizzato con `characters.md`.

## Note

Per un'analisi quantitativa più approfondita (breakpoint, dominanza,
scaling) il proprietario può invocare manualmente l'agente
`analista-bilanciamento`; non è un prerequisito per chiudere questa card, che
resta uno scarto dichiarativo motivato, non un ribilanciamento numerico
completo del gioco.
