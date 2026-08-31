---
id: PS-029
titolo: Rendi più visibili i tell di stato dei personaggi
tipo: ux
area: gameplay
stato: PRONTO
priorita: alta
dipende_da: []
origine: B44
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-029 — Rendi più visibili i tell di stato dei personaggi

## Contesto

Alcuni personaggi comunicano stati temporanei o modalità della passiva tramite outline, tinta o altri tell visuali, ma durante il combattimento questi segnali risultano troppo deboli.

Il problema è particolarmente evidente con Iperfocus ADHD di Lollo e va verificato anche sugli altri personaggi che utilizzano tell di stato equivalenti.

## Comportamento atteso

Gli stati gameplay che richiedono un tell visuale devono essere riconoscibili sul personaggio durante una normale run, anche con orde dense, proiettili e VFX contemporaneamente a schermo.

Il passaggio da uno stato all'altro deve essere percepibile senza dover contare secondi o osservare statistiche indirette.

La revisione deve partire da Lollo e includere un controllo degli altri tell di stato già presenti nel roster, aumentando contrasto, spessore, intensità o separazione visiva dove necessario.

Il tell deve restare presentazionale e non modificare durata, valori o logica dello stato.

## Criteri di accettazione

- [ ] Iperfocus e Distrazione di Lollo sono distinguibili immediatamente durante il gameplay.
- [ ] Il tell di Lollo resta visibile sopra lo sfondo arena e durante orde dense.
- [ ] Il tell non viene annullato visivamente dal normale sprite del Player.
- [ ] Gli altri personaggi con stati o fasi visualmente dichiarate vengono verificati nello stesso pass.
- [ ] Lo stato caldo e freddo di Aleo resta chiaramente distinguibile durante il combattimento.
- [ ] Gli eventuali tell attivi di Alea restano leggibili durante la loro finestra.
- [ ] Ogni tell continua a rispettare la priorità del feedback di danno e degli altri segnali critici.
- [ ] Il cambio di stato produce un cambiamento visivo percepibile senza modificare il gameplay.
- [ ] La leggibilità non dipende esclusivamente da una differenza cromatica minima.
- [ ] I tell non coprono hitbox percepite, telegraph ostili o proiettili importanti.
- [ ] Restart e cambio personaggio eliminano correttamente ogni tell residuo.
- [ ] Pausa e stati non `RUNNING` conservano il comportamento temporale corrente.

## Ambito

- Sistema visuale dei passive/state tell del Player.
- Outline, tint, aura o altri indicatori già usati per gli stati del roster.
- Priorità visuale rispetto a hit flash e VFX.
- Verifica specifica di Lollo e revisione trasversale dei personaggi con tell già implementati.

Non modificare:

- durata di Iperfocus o Distrazione;
- bonus/malus di Lollo;
- soglia termica o modificatori di Aleo;
- probabilità o logica degli stati di Alea;
- statistiche, cooldown, passive o abilità;
- collisioni e hitbox.

## Verifica

- Smoke: `tests/integration/_character_state_tells_smoke.gd` → marker `CHARACTER_STATE_TELLS_SMOKE_OK`
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: Lollo → osserva almeno un ciclo Iperfocus/Distrazione; Aleo → attraversa la soglia HP; verifica gli altri profili con tell attivo)
- [ ] Controllo percettivo richiesto: sì

## Decisioni

- **2026-08-30 — I tell di stato devono essere leggibili in combattimento reale.** L'esistenza tecnica di outline o tint non è sufficiente se il cambio di stato non viene percepito dal giocatore.
- **Sostituisce:** intensità/leggibilità corrente dei tell visuali quando insufficiente.

## Documenti sincronizzati

- [ ] `prd.md` o `CLAUDE.md`, solo se viene formalizzata una nuova regola trasversale di presentazione.
- [ ] `characters.md` e `content-approvals.md`, se cambia la descrizione pubblica o un asset approvato dei tell.
- [ ] Nota `*-verification.md`, se sono state prodotte nuove evidenze.

## Note

Non uniformare necessariamente tutti i personaggi allo stesso effetto grafico. L'obiettivo è rendere ogni stato leggibile mantenendo l'identità visuale del relativo personaggio.

Lollo è il riferimento minimo da correggere; la card include un audit degli altri tell già esistenti per evitare che lo stesso problema rimanga altrove.
