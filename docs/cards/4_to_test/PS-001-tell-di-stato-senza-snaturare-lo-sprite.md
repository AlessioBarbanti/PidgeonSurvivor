---
id: PS-001
titolo: Comunicare la fase della passiva senza ridipingere lo sprite
tipo: ux
area: arte
stato: IN VERIFICA
priorita: alta
dipende_da: []
origine: B44
creato: 2026-08-29
aggiornato: 2026-09-02
---

# PS-001 — Comunicare la fase della passiva senza ridipingere lo sprite

## Contesto

B44 ha introdotto il *tell* di stato delle passive: quando un personaggio entra
in una fase, il suo sprite viene tinto. La tinta è applicata come
`self_modulate` sull'intero `_character_sprite`
([player.gd:553](../../../scripts/actors/player.gd#L553)), quindi moltiplica ogni
pixel del personaggio invece di aggiungersi accanto a lui.

Il risultato è che il personaggio perde la propria identità cromatica. Con Alea
in fase positiva la tinta è `Color(0.72, 1.32, 0.82)` e il personaggio diventa
tutto verde. Lo stesso vale per le altre sette tinte in
[friend_passive_controller.gd:32-40](../../../scripts/content/friend_passive_controller.gd#L32-L40):
Aleo caldo/freddo, Lollo concentrato/distratto, Alea positivo/negativo, Migi
guscio pronto/scudo.

Questa osservazione ha originato un refinement distinto dalla baseline B44: il
proprietario ha visto che la tinta non regge come soluzione definitiva. B44 è
stato chiuso operativamente il 30 agosto 2026; questa card resta `IN VERIFICA`
finché i gate percettivi e di piattaforma del nuovo tell non sono completati.

## Comportamento atteso

La fase attiva della passiva resta riconoscibile a colpo d'occhio durante il
gioco, senza dover leggere l'HUD, ma lo sprite del personaggio conserva i propri
colori. Il segnale si aggiunge al personaggio, non lo sostituisce.

**Attenzione a non risolvere cancellando.** B44 esiste perché prima di quella
slice nulla sullo schermo comunicava la modalità corrente. Rimuovere il tint
senza rimpiazzarlo riapre quel problema invece di chiudere questo.

## Decisioni

- **2026-08-29 — Contorno colorato attorno alla sagoma.** Lo sprite interno
  resta intatto; il segnale deve aggiungersi all'identità cromatica.

- **Alternative scartate — decal a terra, accent separato e tinta attenuata.**
  Il contorno resta visibile anche quando il personaggio è parzialmente coperto
  dai nemici, cioè quando il tell serve di più.

- **2026-08-30 — Il colore resta memorizzato, la presentazione segue lo stato
  della run.** Il contorno è visibile solo in `RunController.RUNNING`; pausa,
  modali, terminali e `BOOT` lo nascondono senza perdere la fase da ripresentare
  alla ripresa. Il restart riporta la passiva alla propria fase iniziale.
- **2026-09-02 — Gate percettivo chiuso con esito negativo: il contorno è
  bocciato.** Il proprietario, giocando la run, ha bocciato `PassiveStateOutline`
  per tutti e quattro i personaggi che lo usano (Aleo, Lollo, Alea, Migi):
  rompe la leggibilità della silhouette pixel-art e non si integra
  esteticamente con lo stile del gioco. Non è un problema di spessore o
  colore (già ritoccati da PS-029): è il meccanismo stesso — un ricalco del
  profilo dello sprite — a non funzionare. I criteri percettivi ancora aperti
  sopra restano intenzionalmente non spuntati: non passeranno mai con questa
  implementazione. La responsabilità di trovare una soluzione sostitutiva
  passa a [PS-079](../2_to_do/PS-079-particellare-tell-stato-personaggi.md);
  questa card resta storica come primo tentativo (contorno invece di tinta
  piena) e come diagnosi valida del problema originale di B44, non come
  contratto ancora da chiudere con l'implementazione attuale.

## Criteri di accettazione

- [x] Nessun `self_modulate` di stato viene applicato a `_character_sprite`: in
      ogni fase lo sprite conserva i colori originali del personaggio.
      *Asserito dallo smoke: `get_character_self_modulate() == Color.WHITE`.*
- [ ] La fase attiva di Aleo, Lollo, Alea e Migi è distinguibile a colpo d'occhio
      con il Player fermo e in movimento. *Percettivo, non verificabile in
      headless.*
- [ ] Le due fasi opposte dello stesso personaggio sono distinguibili fra loro
      (caldo/freddo, concentrato/distratto, positivo/negativo, guscio/scudo).
      *Percettivo.*
- [x] Il flash da danno mantiene la precedenza sul tell di stato: è l'unica cosa
      che altera `self_modulate`, e il contorno segue la visibilità dello sprite
      durante il lampeggio.
- [x] Il tell resta puramente presentazionale: nessun cambiamento a collisioni,
      statistiche, timing o bilanciamento. Sono cambiati solo il canale di
      disegno e i valori dei colori.
- [x] Il tell avanza solo in `RunController.RUNNING`, sparisce in pausa e si
      azzera al restart. Lo smoke asserisce pausa, ripresa, `BOOT` e nuova run
      con ritorno di Aleo alla fase calda iniziale.
- [ ] Il tell resta leggibile a densità massima di nemici. *Percettivo: è il gate
      che B44 ha aperto e che questa card deve chiudere.*

## Ambito

Probabilmente toccati:

- [scripts/content/friend_passive_controller.gd](../../../scripts/content/friend_passive_controller.gd)
  — costanti `TINT_*` e `_refresh_passive_state_tint()`.
- [scripts/actors/player.gd](../../../scripts/actors/player.gd) —
  `set_passive_state_tint` / `clear_passive_state_tint` /
  `get_passive_state_tint` e `_update_character_feedback()`.
- [tests/integration/_b44_state_tells_smoke.gd](../../../tests/integration/_b44_state_tells_smoke.gd)
  — oggi asserisce l'uguaglianza fra `get_passive_state_tint()` e le costanti:
  cambiando il meccanismo va riscritto, non aggirato.
- Eventuale nuovo nodo accent, sullo schema dei tell già esistenti in
  `scripts/abilities/`.

Da **non** toccare:

- l'autorità di `RunController` su stato, tempo logico, pausa e restart;
- il flusso `welcome → (tutorial) → selezione → run → pausa`;
- i registry degli effetti e i valori di bilanciamento delle passive: qui si
  cambia solo come la fase viene comunicata, non che cosa fa;
- gli sprite approvati del cast, tracciati in
  [characters.md](../../characters.md).

## Verifica

- Smoke: `tests/integration/_b44_state_tells_smoke.gd` → marker
  `B44_STATE_TELLS_SMOKE_OK`, aggiornato al nuovo meccanismo.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: run con Aleo, Lollo, Alea e Migi fino al
      cambio di fase di ciascuno)
- [ ] Controllo percettivo richiesto: **sì** — leggibilità del tell a densità
      massima su Windows e Pixel 9, ed è il gate che B44 ha lasciato aperto

## Documenti sincronizzati

- [x] `docs/characters.md`: il tell di Lollo è descritto come contorno colorato,
      non più come tinta dello sprite.
- [x] Gli snapshot B44 restano storici e non vengono riscritti.

## Note

### Che cosa è cambiato

- Nuovo [`scripts/vfx/passive_state_outline.gd`](../../../scripts/vfx/passive_state_outline.gd)
  (`PassiveStateOutline`): `Node2D` figlio di `CharacterSprite` con
  `show_behind_parent`, disegna la texture dello sprite otto volte con piccoli
  scostamenti nel colore della fase. Otto direzioni e non quattro perché le sole
  ortogonali lasciano scoperti gli angoli sulle sagome oblique.
- Il nodo eredita posizione, rotazione e scala dallo sprite, quindi il contorno
  cresce con il personaggio. `flip_h`/`flip_v` non sono trasformazioni ma flag di
  disegno e non si propagano ai figli: vengono letti dallo sprite a ogni
  `_draw()`.
- Il nodo si risincronizza da sé in `_process` confrontando texture, flip e
  visibilità. Alternativa scartata: far avvisare il nodo dal `Player` a ogni
  cambio. Avrebbe richiesto di ricordarsene in ogni punto di chiamata, incluso
  l'avanzamento dei frame di camminata, ed è il tipo di accoppiamento che si
  rompe in silenzio.
- `Player`: `set_passive_state_tint` e famiglia diventano
  `set_passive_state_outline` / `clear_passive_state_outline` /
  `get_passive_state_outline_color` / `has_passive_state_outline`. Il nome
  vecchio avrebbe mentito. Aggiunto `get_character_self_modulate()` come
  osservabilità per lo smoke.
- `Player` osserva inoltre `RunController.state_changed` e presenta il contorno
  soltanto in `RUNNING`. `PassiveStateOutline` conserva separatamente colore e
  visibilità, così pausa e modali non fanno avanzare né perdere la fase.
- `FriendPassiveController`: le costanti `TINT_*` diventano `OUTLINE_*`. Non è
  solo un rinominare: i valori erano fuori gamma (`1.32`) perché pensati per
  schiarire in moltiplicazione, e come colori opachi sarebbero stati clippati.
  Ora sono colori saturi dentro gamma.

### Diagnosi

Il difetto non era la scelta dei colori ma il canale: `self_modulate` moltiplica
ogni pixel, quindi qualunque tinta satura ridipinge il personaggio. Ritoccare i
valori avrebbe attenuato il sintomo lasciando la causa.

### Verifica eseguita

- Baseline **prima** della modifica, per non attribuirmi rotture altrui:
  `_b44_state_tells_smoke` e `_b45_role_identity_smoke` entrambi verdi.
- Dopo la modifica: `.\tools\run-milestone-checks.ps1 -Milestone B44 -Profile Focused -RefreshEditor -NoCache`
  → `PASS`, marker `B44_STATE_TELLS_SMOKE_OK`, incluse le due asserzioni nuove.
- Registrata in `tools/milestone-test-map.json` la regola che lega
  `friend_passive_controller.gd` e `passive_state_outline.gd` agli smoke B44,
  B45, B42 e contenuti.
- Dopo il completamento del contratto pausa/restart:
  `run-milestone-checks.ps1 -Milestone PS-001 -Profile Focused -RefreshEditor
  -NoCache -FocusedSmoke tests/integration/_b44_state_tells_smoke.gd` → `PASS`,
  marker `B44_STATE_TELLS_SMOKE_OK`.
- Regressione mirata B45 rieseguita dopo il refactor → `PASS`, marker
  `B45_ROLE_IDENTITY_SMOKE_OK`.
- Il contratto tooling è stato avviato e ha segnalato un problema distinto da
  PS-001: il controllo `Full` conta solo gli smoke legacy in `tests/integration`,
  mentre il piano corrente include anche i test GUT della conversione in corso.

### Verifica NON eseguita

Il 30 agosto 2026 il proprietario ha chiesto di saltare i test. Il profilo
`Relevant`, già avviato, è stato interrotto prima del completamento e non sono
stati eseguiti altri test. Restano quindi aperti il minimo `Relevant`, il
contratto tooling e tutti i gate manuali Windows/APK/Pixel 9/percettivo.

### Worktree

Il refactor B52 in corso del proprietario (`player.gd`, `arena_world.gd`,
`hud.gd`, `movement_slice.gd`, `presentation_timings.gd`) è stato preservato: le
modifiche di questa card vivono in regioni disgiunte e non sono state toccate.
