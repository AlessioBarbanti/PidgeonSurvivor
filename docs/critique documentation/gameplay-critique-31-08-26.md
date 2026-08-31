# Valutazione generale

Pidgeon Survivor ha già una personalità riconoscibile e un sistema di contenuti sorprendentemente maturo. Il problema principale non è la mancanza di idee o asset: è la distanza qualitativa fra la “promessa” della welcome e ciò che il giocatore vede durante la run.

La [welcome](../../exports/ui-screenshots/01_welcome.png) sembra la copertina di un gioco finito; il [gameplay](../../exports/ui-screenshots/04_gameplay_hud.png) sembra ancora una vertical slice. La priorità artistica dovrebbe quindi essere coesione, composizione e leggibilità, non produrre altri asset isolati.

## Cosa funziona molto bene

- Identità “grigliatori contro piccioni” immediata, buffa e commerciabile.
- Welcome eccellente: logo, cast, CTA e atmosfera raccontano il gioco senza testo.
- Cornici, pulsanti e palette crema/oro/blu funzionano bene in tutorial, pausa e terminali.
- Icone di abilità e upgrade colorate, leggibili e con silhouette generalmente distinte.
- Gli otto personaggi hanno ruoli, passive, attive e controparti Evil coerenti: il sistema descritto in [characters.md](../characters.md) è uno dei punti più forti del progetto.
- La curva non si limita ad aumentare i numeri: archetipi, settori, eventi e tiratori introducono decisioni diverse, come dichiarato in [systems-difficulty.md](../systems-difficulty.md).

## Priorità che consiglierei

| Priorità | Area | Problema | Intervento |
|---|---|---|---|
| P0 | Gameplay | Arena piatta, ripetitiva e molto più povera della welcome | Pass compositivo dell’arena e gerarchia visiva del combattimento |
| P0 | Level-up | Titolo `LIVELLO` e timer si sovrappongono; le carte sembrano pannelli tecnici | Isolare realmente il modal e ridisegnare la gerarchia delle carte |
| P1 | Tutorial | Alcune immagini non insegnano ciò che dice il testo | Allineare visual e meccanica reale |
| P1 | Settings | Controlli flottanti e quasi nativi, incoerenti con la pausa | Riutilizzare pannello, slider e toggle della pausa |
| P1 | Boss | Intro gradevole ma Boss senza identità individuale | Ritratto Evil, icona Signature e colore personale |
| P2 | End screen | Offre solo tempo e restart | Sommario della build e record della run |
| P2 | Character select | Funzionale ma più freddo e tecnico della welcome | Snellire il testo e dare più presenza al personaggio |

### 1. Rifare la composizione della run, non necessariamente gli asset

Nel gameplay il pavimento marrone occupa quasi tutto lo spettro visivo; quattro grandi panche ripetute fanno percepire l’arena come una test room. Personaggio, piccioni, proiettili e pickup finiscono per avere pesi simili.

Adotterei una gerarchia rigorosa:

1. Terreno desaturato e a bassa frequenza.
2. Attori con bordo scuro e piccola ombra di contatto.
3. Minacce in rosso/magenta con forma e pulsazione.
4. XP ciano, cure verdi/crema, attacchi alleati ambra.
5. Ostacoli raggruppati in piccole “isole sceniche”, usando anche camino, tavolo, stendino e lavatoio già presenti negli asset.

Non aggiungerei decorazioni casuali: costruirei una zona centrale leggibile e bordi progressivamente più sporchi, come una vera piazza da grigliata invasa.

### 2. Rendere il level-up una vera scelta

Nel [level-up](../../exports/ui-screenshots/05_upgrade_overlay.png) il titolo collide con il cronometro e le tre carte sono quasi interamente testo. È il momento decisionale più frequente del gioco, quindi merita più cura della Boss intro.

Suggerisco:

- nascondere o oscurare completamente HUD e timer dietro il modal;
- mostrare una sola riga descrittiva;
- trasformare i numeri in chip visuali, per esempio `DANNO +15%`, `VITA -20%`;
- evidenziare beneficio e costo con due grammatiche distinte;
- rendere il bordo selezionato molto evidente senza ingrandire tutta la carta;
- per i rank successivi mostrare `valore attuale → nuovo valore`.

Questo migliorerebbe la qualità delle decisioni senza cambiare il bilanciamento.

### 3. Correggere tre pagine tutorial

Il contenitore del tutorial è molto riuscito, ma alcune pagine promettono informazioni diverse da quelle mostrate:

- Pagina 3 parla del “cerchio” dell’abilità, ma mostra quattro icone. Dovrebbe mostrare il vero pulsante HUD in stato pronto e in cooldown.
- Pagina 4 parla di cristalli XP e cura, ma mostra soprattutto illustrazioni di carne e utensili. Mostrerei il pickup XP reale, la coscia curativa e la trasformazione in una carta.
- Pagina 6 insegna un telegraph universale a cono, mentre gli Evil possiedono Signature molto diverse. Meglio scrivere “alcuni attacchi disegnano la zona pericolosa” oppure mostrare tre forme reali: linea, anello e area.

Il contratto tutorial è descritto in [prd.md](../prd.md); qui serve maggiore fedeltà al runtime, non nuova spettacolarità.

### 4. Consolidare l’identità UI

La [pausa](../../exports/ui-screenshots/07_pause_overlay.png) è una buona base di sistema. La [schermata impostazioni della welcome](../../exports/ui-screenshots/02_welcome_settings.png), invece, sembra appartenere a un’altra versione del gioco.

Riutilizzerei dalla pausa:

- pannello scuro e cornice;
- titoli di sezione;
- slider arancio;
- checkbox quadrate;
- spaziatura verticale.

La palette è già formalizzata in [prd.md](../prd.md): il problema è applicarla uniformemente.

### 5. Dare un volto agli Evil

La [Boss intro](../../exports/ui-screenshots/06_boss_intro.png) è ordinata, ma comunica “Boss generico”. I documenti confermano che i ritratti Boss usano ancora lo stesso placeholder nonostante il resto del cast abbia asset bespoke, in [visual-audio-identity.md](../visual-audio-identity.md).

Inserirei:

- ritratto o busto Evil;
- piccola icona della Signature;
- una tinta personale applicata al nome e a un dettaglio della cornice;
- CTA ancora arancio, per non perdere la semantica dell’azione primaria.

È probabilmente l’intervento con il miglior rapporto tra costo e percezione di contenuto.

## Suggerimenti di game design

- Non aggiungerei altri sistemi di pressione prima dei playtest reali di PS-007 e PS-008. La struttura già comprende archetipi, eventi, Boss ricorrenti e Specialità di Barb: ora va verificato il ritmo, non aumentata la quantità.
- Aggiungerei un vero riepilogo finale: personaggio, livello, Boss sconfitti, tempo, tre upgrade dominanti e record. Rafforza il desiderio di “un’altra run” senza introdurre subito meta-progressione permanente.
- Deciderei esplicitamente la filosofia della vittoria. Attualmente la modalità Survival è realmente endless e `VICTORY` è dormiente, come documentato in [ui-ux-flow.md](../ui-ux-flow.md). Terrei Survival come caccia al record e riserverei eventualmente una vittoria formale a Difesa Grigliata.
- Aggiungerei variazioni audio leggere durante warning, Boss e ricompensa Barb: ducking della musica, stinger e ripresa, senza richiedere nuove tracce complete.

## Problemi nella documentazione e nelle catture

Ho trovato tre card attive `PRONTO` non presenti nella board: [PS-025](../cards/2_to_do/PS-025-aumenta-dimensioni-avvertimento-boss.md), [PS-028](../cards/2_to_do/PS-028-rendi-piroetta-alea-circolare.md) e [PS-029](../cards/2_to_do/PS-029-rendi-tell-stato-personaggi-piu-visibili.md). Sono 41 file-card ma solo 38 righe nella [board](../cards/README.md). Questo va corretto prima di stabilire le prossime priorità.

Inoltre:

- `07b_pause_change_confirmation.png` mostra la conferma pausa sopra un level-up, composizione che il contratto degli stati dichiara impossibile;
- l’end screen mostra `00:05` nella HUD e `03:07` nel risultato;
- la card PS-036 cita due catture `ps036/` non più presenti, mentre la cattura Barb canonica mostra ancora il layout precedente;
- tutto il pacchetto corrente è `1280×720`: non dimostra la resa 20:9 del Pixel 9.

Quindi userei queste immagini per valutare l’estetica, ma non come proof pack finale.

La mia sequenza ideale sarebbe: correggere board e catture → gameplay readability → level-up/settings → tutorial fidelity → identità Evil → riepilogo finale. Non toccherei ancora Difesa Grigliata: prima renderei la modalità Survival coerente con l’eccellente promessa della welcome.
