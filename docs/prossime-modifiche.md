# Prossime modifiche gameplay

Tracker del ciclo successivo a B18B. Ogni blocco diventa un backlog item
separato quando dipendenze, valori di bilanciamento e asset obbligatori sono
definiti.

Stati usati:

- `DA DEFINIRE`: mancano decisioni o asset che cambiano l'implementazione;
- `PRONTO`: requisiti sufficienti per iniziare;
- `IN CORSO`: implementazione aperta nel worktree;
- `IN VERIFICA`: codice e test automatici completati, gate manuali ancora aperti;
- `COMPLETATO`: gate chiusi e modifica registrata in un commit dedicato.

## Quadro operativo

| ID | Blocco | Stato | Dipendenze o gate aperti |
|---|---|---|---|
| B18C | Player animato e direzione persistente | IN VERIFICA | Conferma visiva finale e Android reale |
| B18D | Powerslide di Bea | IN VERIFICA | Runtime Android reale |
| B18E | Fulmini di Zat | DA DEFINIRE | Cooldown definitivo e intensità/riduzione flash Android |
| B18F | Abilità inseguitrice di Alea | PRONTO | B17A |
| B18G | Rank delle abilità principali | DA DEFINIRE | Progressione dichiarativa specifica per tutte le otto abilità |
| B18H | Nemici piccione | DA DEFINIRE | Asset base e variante speciale approvati |
| B18I | XP confinato nell'arena | PRONTO | B07 e `ArenaLayout` |
| B18J | Grigliata estiva | DA DEFINIRE | Valore HP per rank e cap |
| B18K | Pulsante abilità con icona e cooldown circolare | PRONTO | Icone abilità disponibili; gate HUD/aspect ratio |
| B18L | Joystick dinamico | PRONTO | Gate lifecycle e multitouch fisico obbligatorio |
| B18M | Migliorie grafiche delle abilità | DA DEFINIRE | Ricerca asset/licenze e prompt per gli asset mancanti |

## B18C — Player animato e direzione persistente

Stato: `IN VERIFICA`.

- [x] Rimuovere il cannoncino visibile dal personaggio.
- [x] Rimuovere il vecchio fondo circolare azzurro.
- [x] Animare il personaggio durante il movimento.
- [x] Mostrare una posa ferma quando il personaggio non si muove.
- [x] Determinare destra/sinistra dall'ultimo movimento orizzontale non nullo.
- [x] Conservare la direzione quando il movimento torna neutro o resta verticale.
- [x] Esporre la direzione alle abilità tramite `Player.get_facing_direction()`.
- [x] Coprire Lollo, Migi e Marghe con un gait procedurale perché il foglio CC0
  contiene per loro una sola posa laterale valida.
- [x] Smoke dedicato e suite completa `22/22` senza errori runtime.
- [x] Export e smoke Windows.
- [ ] Conferma visiva finale Windows dopo le correzioni a cannoncino/background.
- [ ] Test Android reale su Pixel 9.

Dettagli ed evidenze: [`b18c-verification.md`](./b18c-verification.md).

## B18D — Powerslide di Bea

Stato: `IN VERIFICA`.

- [x] Rinominare l'attiva da **Scia di Fuoco Z** a **Powerslide**.
- [x] Teletrasportare il Player in linea retta nell'ultimo vettore restituito
  da `Player.get_last_movement_direction()`.
- [x] Non leggere la posizione del joystick dopo l'attivazione; origine e
  destinazione vengono fotografate all'avvio.
- [x] Aumentare la durata dell'effetto a terra da `2 s` a `4 s`.
- [x] Distanza (`dash_distance`) e danno (`damage`) sono già dati configurabili.
- [x] Lasciare una scia rettilinea dietro al teletrasporto, senza zig-zag.
- [x] Verificare che teletrasporto, scia e cooldown avanzino solo in
  `RunController.RUNNING` e vengano ripuliti al restart.
- [x] Sostituire l'icona con il pattino inline Pinhead CC0 e
  registrarne URL, autore e licenza.
- [x] Aggiungere smoke dedicato per direzione persistente, pausa e due run.
- [x] Suite completa `23/23` e project smoke senza errori runtime.
- [x] Export Windows e smoke dell'eseguibile con `B18D_CONTRACT_OK`.
- [x] Export statico APK ARM64; non equivale a una verifica runtime Android.
- [x] Verifica manuale Windows approvata il 24 agosto 2026: teletrasporto
  rettilineo nell'ultimo vettore di movimento e scia persistente.
- [ ] Test Android reale: joystick con un dito, Powerslide con il secondo.

Dettagli ed evidenze: [`b18d-verification.md`](./b18d-verification.md).

## B18E — Fulmini di Zat

Stato: `DA DEFINIRE`.

Sequenza richiesta:

1. attivazione;
2. breve preavviso visivo;
3. flash bianco tipo tuono su tutto il viewport logico;
4. applicazione ritardata del danno a tutti i nemici validi;
5. rimozione del flash e chiusura dell'effetto.

Decisioni già confermate:

- [x] Colpisce anche i nemici entrati nell'arena dopo l'attivazione ma prima
  dell'impatto.
- [x] Danno pari al `50%` della vita massima dei nemici e al `20%` per i Boss.
- [x] Flash esteso all'intero viewport logico.

Decisioni ancora aperte:

- [ ] cooldown definitivo; valore candidato: `60 s`;
- [ ] intensità del flash su Android;
- [ ] opzione di accessibilità per ridurre il flash.

## B18F — Abilità inseguitrice di Alea

Stato: `PRONTO`.

- [ ] Centrare l'effetto sul personaggio per tutta la durata.
- [ ] Aggiornare la posizione dalla posizione corrente del Player, senza
  lasciarla ancorata al punto di lancio.
- [ ] Verificare pausa, cambio di direzione, termine, restart e cambio profilo.

## B18G — Rank delle abilità principali

Stato: `DA DEFINIRE`.

- [ ] Aggiungere rank incrementali fino al livello massimo `5`.
- [ ] Collegare i rank al level-up delle carte senza duplicati nella stessa
  offerta.
- [x] Il rank resta solo nella run; nessuna meta-progressione è prevista.
- [x] Ogni abilità avrà una progressione specifica, anche mista: danno, area,
  durata, cooldown, numero colpi o altri effetti.
- [ ] Dichiarare nei dati i valori di tutti e cinque i rank per ciascuna delle
  otto abilità prima di implementare il registry runtime.

## B18H — Nemici piccione

Stato: `DA DEFINIRE`.

- [ ] Sostituire le sfere rosse con piccioni.
- [x] Comportamento, collisioni, danno e spawn restano invariati salvo nuova
  decisione esplicita.
- [ ] Reperire e approvare almeno una variante base e una speciale.

## B18I — XP confinato nell'arena

Stato: `PRONTO`.

- [ ] Se una morte avviene fuori arena, correggere la posizione del relativo XP
  tramite il playfield di `ArenaLayout`.
- [ ] Garantire una posizione valida e raggiungibile, includendo il raggio del
  pickup.
- [ ] Verificare tutti i bordi, gli aspect ratio e il restart.

## B18J — Potenziamento Grigliata estiva

Stato: `DA DEFINIRE`.

- [ ] Aumentare gli HP massimi e curare immediatamente la differenza ottenuta.
- [ ] Dichiarare l'aumento nei dati del potenziamento.
- [ ] Fissare valore per rank e cap.
- [ ] Rispettare pausa, stacking e reset della run.

## B18K — Pulsante abilità con cooldown circolare

Stato: `PRONTO`.

- [ ] Usare l'icona dell'abilità selezionata come superficie di attivazione.
- [ ] Mostrare un riempimento circolare durante il cooldown.
- [ ] Mostrare il tempo residuo al centro.
- [ ] Quando pronta, rimuovere il timer e rendere chiaramente attivabile l'icona.
- [ ] Conservare un target touch di almeno `44–48` unità logiche.

## B18L — Joystick dinamico

Stato: `PRONTO`.

- [ ] Il primo dito che tocca l'area di gioco determina origine e comparsa del
  joystick.
- [ ] Calcolare il movimento rispetto all'origine e mantenere l'ownership dello
  stesso dito.
- [ ] Nascondere il joystick al rilascio e ricrearlo al tocco successivo.
- [ ] Ignorare i tocchi iniziati sopra HUD, pulsante abilità o overlay.
- [ ] Conservare l'attivazione dell'abilità con un secondo dito.
- [ ] Verificare neutral-to-rearm, pausa, focus, Home, lock, Back e restart.

## B18M — Migliorie grafiche delle abilità

Stato: `DA DEFINIRE`.

- [ ] Cercare effetti animati con licenza compatibile per le otto abilità.
- [ ] Sostituire le icone provvisorie con sprite coerenti.
- [ ] Registrare fonte, autore, licenza e modifiche di ogni asset importato.
- [ ] Creare un breve file di prompt per generare gli asset che non hanno una
  fonte adatta.

## Gate comuni

- Smoke dedicati per direzione/animazione, Bea, Zat, Alea e rank.
- Nessun `SCRIPT ERROR` o `FATAL EXCEPTION`, anche con exit code `0`.
- Verifica Windows e Android.
- Android reale: joystick con un dito e abilità con il secondo.
- Pausa, ripresa esplicita, focus, Home/lock, Back e restart per ogni effetto
  temporizzato o inseguitore.
- Verifica a 16:9, 20:9 e 4:3 per UI, posizioni, direzioni, aree e flash.
