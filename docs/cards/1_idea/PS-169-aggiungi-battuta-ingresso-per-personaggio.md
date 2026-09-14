---
id: PS-169
titolo: Aggiungi una battuta di ingresso per ogni personaggio
tipo: feat
area: ui
stato: POSTICIPATA
priorita: bassa
dipende_da: [PS-101]
origine: playtest esterno 2026-09-11 — feedback Lollo/Magno
creato: 2026-09-11
aggiornato: 2026-09-14
---

# PS-169 — Aggiungi una battuta di ingresso per ogni personaggio

## Contesto

Il playtest chiede di far emergere maggiormente l'identità del personaggio nei messaggi della run. Warning Boss, telegraph degli eventi e copy HUD hanno però una funzione di sistema e devono restare uniformi; PS-101 ha inoltre stabilito che la citazione della Boss Intro è unica e condivisa fra Piccione Malvagio ed Evil.

Il perimetro viene quindi ristretto a un solo momento sicuro e riconoscibile: l'ingresso nella run. Ogni personaggio pronuncia una breve battuta subito dopo l'avvio, senza introdurre messaggi ripetuti durante il combattimento.

## Comportamento atteso

- Quando `RunController` entra in `RUNNING`, la HUD mostra una battuta associata al `FriendDefinition` equipaggiato.
- La battuta compare in una corsia dedicata, non modale, sotto la fascia superiore della HUD, resta leggibile per `2,5 s` di tempo logico e poi sfuma.
- Boss warning ed eventi d'ondata hanno sempre precedenza: se uno dei due diventa visibile, la battuta sparisce subito, non viene accodata e non ricompare nella stessa run.
- Restart e nuova run mostrano di nuovo la battuta del personaggio equipaggiato; il cambio personaggio non conserva testo o timer del profilo precedente.
- Il timer avanza soltanto in `RUNNING`, coerentemente con gli altri elementi temporizzati della run.

## Catalogo copy

| Personaggio | Battuta di ingresso |
|---|---|
| Magno | «Facciamo tremare l'arena.» |
| Bea | «Prendetemi, se ci riuscite.» |
| Zat | «Resisti: il dolore passa.» |
| Alea | «Due dita e parto!» |
| Aleo | «Portiamo tutto alla giusta temperatura.» |
| Lollo | «Vediamo chi divento oggi.» |
| Migi | «Calma. Respira. Rallenta.» |
| Marghe | «Reggaeton time!» |

I testi sono battute del personaggio, non sostituzioni del copy di sistema. Prima della chiusura il proprietario può correggere il tono senza cambiare il contratto runtime della card.

## Criteri di accettazione

- [ ] Tutti gli otto `FriendDefinition` espongono la propria battuta e un fallback condiviso non vuoto; la UI non contiene uno `match` sugli ID del roster.
- [ ] Ogni personaggio mostra esattamente la battuta del catalogo all'avvio della run, una sola volta per run.
- [ ] La battuta non copre né sostituisce Boss warning, countdown, telegraph d'ondata, errori, impostazioni o input hint.
- [ ] Un warning Boss o un evento d'ondata già visibile o sopraggiunto sopprime la battuta senza riproporla in seguito.
- [ ] Pausa, level-up, Boss Intro e ricompensa Barb non consumano il timer; restart e cambio personaggio azzerano presentazione e contenuto residui.
- [ ] Il testo resta dentro la safe area ed è leggibile senza intercettare input su Windows e sul profilo Pixel 9.
- [ ] La citazione condivisa della Boss Intro stabilita da PS-101 resta invariata.

## Ambito

- `scripts/content/friend_definition.gd` e `data/friends/*.tres` per copy approvato e fallback.
- `scripts/ui/hud.gd` e `scenes/ui/hud.tscn` per la corsia non modale e la priorità sugli avvisi.
- `scripts/game/movement_slice.gd` soltanto per il wiring scene-local necessario.
- Non aggiungere battute per uso abilità, level-up, Boss, ricompense o fine run; eventuali estensioni richiedono una card separata e un nuovo catalogo copy.

## Verifica

- GUT: `tests/unit/test_ps169_character_entry_line.gd` → marker `PS169_CHARACTER_ENTRY_LINE_SMOKE_OK`, coprendo gli otto testi, il fallback, la singola emissione e la precedenza degli avvisi.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: avvio, restart e cambio personaggio; verifica safe area e soppressione da avviso)
- [ ] Controllo percettivo richiesto: sì, per tono delle otto battute e leggibilità a scala finale

## Decisioni

- **2026-09-11 — Un solo evento a bassa frequenza.** La personalizzazione riguarda l'ingresso nella run; non crea rumore testuale durante il combattimento.
- **2026-09-11 — Gli avvisi urgenti restano condivisi e prioritari.** La nuova corsia non riusa gli slot Boss/evento e non modifica la citazione condivisa di PS-101.
- **2026-09-11 — Copy nei dati del personaggio.** La HUD osserva lo stato e presenta testo già risolto; non possiede identità o contenuti del roster.
- **2026-09-14 — POSTICIPATA.** Contratto già completo e verificabile, nessuna decisione mancante: il proprietario ha spostato il focus su altri filoni (difficoltà/Boss) e la riprende quando torna prioritaria.

## Documenti sincronizzati

- [ ] `docs/characters.md` con il catalogo delle battute approvato.
- [ ] `docs/ui-ux-flow.md` con posizione, durata e precedenza della corsia di ingresso.

## Note

Feedback originario raccolto il 2026-09-11 da trascrizioni audio di playtest esterno. La prima stesura generica è stata sostituita da un contratto verificabile che non interferisce con le informazioni di pericolo.
