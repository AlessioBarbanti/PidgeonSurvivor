---
id: PS-070
titolo: Aggiorna l'aspettativa 32x32 su evil_portrait in test_b17_friend_content
tipo: fix
area: tooling
stato: PRONTO
priorita: bassa
dipende_da: []
origine: B17
creato: 2026-09-02
aggiornato: 2026-09-02
---

# PS-070 — Aggiorna l'aspettativa 32x32 su evil_portrait in test_b17_friend_content

## Contesto

`tests/unit/test_b17_friend_content.gd:72-78` verifica ancora che sia
`get_public_portrait()` sia `get_public_evil_portrait()` restituiscano un
ritaglio `32x32` dallo spritesheet CC0 condiviso
(`RPGCharacterSprites32x32-transparent.png`). Questo era vero quando la card
è stata scritta (B17, placeholder condivisi per entrambi i ritratti), ma
[PS-051](../5_completed/PS-051-identita-individuale-degli-evil.md) ha
sostituito `evil_portrait` con arte dedicata per personaggio (attualmente
`256x256`, prima come segnaposto `fake_evil_portrait.png`, ora come asset
definitivo prodotto da
[PS-052](../5_completed/PS-052-genera-ritratti-evil-e-icone-signature.md)).

L'asserzione fallisce per tutti e otto i friend
("I due ritratti placeholder di %s devono essere ritagli 32x32.") da quando
PS-051 è stato mergiato. Riprodotto anche su `HEAD` prima di qualunque
modifica di PS-052, quindi non è una regressione introdotta da quella card:
nessun profilo di verifica precedente aveva mai eseguito questo smoke insieme
a un cambiamento sotto `data/bosses/*`, che è il pattern che lo aggancia in
`tools/milestone-test-map.json`.

## Comportamento atteso

`test_b17_friend_content.gd` verifica il contratto attuale: `portrait`
resta un ritaglio placeholder `32x32` dallo spritesheet CC0 (finché
`portraits_are_placeholders` lo dichiara tale), mentre `evil_portrait` è
arte dedicata per personaggio e non deve più essere vincolata a `32x32`.

**Nota di scadenza esplicita.** Questa correzione vale solo finché `portrait`
resta un placeholder. [PS-068](../4_to_test/PS-068-genera-ritratti-busto-cast-giocabile.md)
sostituirà `portrait`/`portrait_placeholder` con un busto definitivo non
`32x32`: quando accadrà, la stessa asserzione tornerà a fallire dal lato
`portrait`, con lo stesso pattern di errore risolto qui per `evil_portrait`.
PS-068 possiede esplicitamente l'aggiornamento di questa riga di test per il
lato `portrait` (vedi la sua sezione Verifica); questa card non deve
anticiparlo né renderlo incondizionato.

## Criteri di accettazione

- [ ] `test_catalog_and_approvals` non assume più che `evil_portrait` sia
      `32x32`; l'asserzione su `portrait` (ritaglio placeholder) resta
      invariata.
- [ ] Il test verifica comunque che `get_public_evil_portrait()` non sia
      nullo per tutti e otto i friend.
- [ ] Nessuna modifica a `scripts/content/friend_definition.gd`, a
      `data/friends/*.tres` o a qualunque valore di gameplay: la card
      corregge solo l'aspettativa del test.
- [ ] `tests/unit/test_b17_friend_content.gd` passa senza fallimenti residui
      sui restanti criteri della stessa funzione.

## Ambito

- `tests/unit/test_b17_friend_content.gd`: solo l'asserzione sulle
  dimensioni dei ritratti (righe indicative 72-78) e, se necessario, il
  messaggio d'errore associato.

Non toccare:

- `scripts/content/friend_definition.gd` e il contratto
  `portrait`/`evil_portrait`/`*_placeholder` che espone;
- `data/friends/*.tres`;
- qualunque criterio di PS-051 o PS-052 relativo ai ritratti Evil stessi.

## Verifica

- Smoke: `tests/unit/test_b17_friend_content.gd` → marker atteso
  (nessun marker `print` dedicato oggi; verificare l'esito `X/X passed`
  del file).
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows: non richiesto, è una correzione di un'asserzione di
      test.
- [ ] Validazione statica APK: non richiesta.
- [ ] Runtime fisico Pixel 9: non richiesto.
- [ ] Controllo percettivo richiesto: no.

## Decisioni

- **2026-09-02 — Card separata invece di allargare PS-052.** Il fallimento è
  emerso mentre si verificava l'integrazione degli asset Evil di PS-052
  (che tocca `data/bosses/signatures/*.tres`, pattern che aggancia questo
  smoke in `tools/milestone-test-map.json`), ma la causa è indipendente e
  precedente: risale a PS-051.
- **2026-09-02 — Non anticipare il lato `portrait`.** PS-068 romperà di
  nuovo questa stessa asserzione, dal lato opposto, quando sostituirà
  `portrait` con un busto definitivo. Il proprietario ha scelto che sia
  PS-068 ad aggiornare quella parte quando arriva, non questa card in
  anticipo su un asset che non esiste ancora.

## Documenti sincronizzati

- [ ] Nessuno atteso: è una correzione di un'aspettativa di test verso un
      contratto già approvato da PS-051.

## Note

Riprodotto con:

```
godot --headless --path . -s addons/gut/gut_cmdln.gd \
  -gtest=tests/unit/test_b17_friend_content.gd -gexit
```

Fallimento attuale (identico su `HEAD` senza modifiche PS-052):

```
[Failed]: I due ritratti placeholder di <friend> devono essere ritagli 32x32.
    at line 72
```
per tutti e otto i friend (`magno, bea, zat, alea, aleo, lollo, migi, marghe`).
