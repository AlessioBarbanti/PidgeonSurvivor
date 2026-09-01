---
id: PS-050
titolo: Uniformare le impostazioni della welcome al sistema della pausa
tipo: ux
area: ui
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-08-31
aggiornato: 2026-08-31
---

# PS-050 — Uniformare le impostazioni della welcome al sistema della pausa

## Contesto

La nuova
[02_welcome_settings.png](../../../exports/ui-screenshots/pixel9-20x9/02_welcome_settings.png)
conferma il divario: le impostazioni della welcome sono un piccolo gruppo di
controlli sospeso al centro di un'area molto ampia, senza un pannello che lo
leghi alla copertina. Slider e toggle appaiono inoltre più nativi e tecnici.

La
[07_pause_overlay.png](../../../exports/ui-screenshots/pixel9-20x9/07_pause_overlay.png)
offre già il riferimento corretto: pannello incorniciato, sezioni, gerarchia e
controlli pixel arcade. Funzione e valori sono gli stessi; deve esserlo anche
il linguaggio visivo.

## Comportamento atteso

Aprendo le impostazioni dalla welcome il giocatore riconosce lo stesso sistema
della pausa: pannello, sezioni, slider, toggle e ritmo verticale coerenti, ma
composti nello spazio della welcome senza copiarne ciecamente le dimensioni.

## Criteri di accettazione

- [ ] Slider e toggle della welcome usano gli stessi componenti o lo stesso
      contratto di stile della pausa (`PixelArcadeSlider` e
      `PixelArcadeToggle`).
- [ ] I controlli sono raccolti in un pannello con cornice e fondale leggibile,
      non sospesi direttamente sopra lo sfondo della welcome.
- [ ] Sezioni, titoli e ordine coincidono con la pausa per tutte le
      impostazioni condivise.
- [ ] Spaziatura e allineamento formano una colonna compatta e intenzionale sul
      Pixel 9 20:9, senza espandersi per riempire artificialmente lo schermo.
- [ ] Volume, mute, riduzione lampeggi, dimensione abilità e joystick leggono e
      scrivono gli stessi dati persistenti di oggi.
- [ ] Modificare un valore nella welcome lo mostra aggiornato in pausa e
      viceversa, senza duplicare lo stato.
- [ ] Back chiude solo il pannello impostazioni e riporta correttamente il
      focus alla welcome.
- [ ] Navigazione da tastiera, gamepad e touch resta completa.
- [ ] Welcome e pausa restano nella safe area su 16:9, 20:9 e 4:3.
- [ ] Il layout attuale della pausa non viene ridisegnato da questa card.

## Ambito

- `scenes/ui/welcome_screen.tscn`, sottoalbero `SettingsPanel`.
- `scripts/ui/welcome_screen.gd`, solo per riferimenti ai nodi ristrutturati.
- Eventuale scena condivisa dei controlli, se elimina duplicazione senza
  cambiare il comportamento della pausa.

Non toccare:

- flusso `welcome → tutorial → selezione → run → pausa`;
- `RunController` e arbitraggio dei modali;
- formato e percorso della persistenza;
- layout della pausa, che resta il riferimento.

## Verifica

- Smoke: `tests/unit/test_ps050_welcome_settings_system.gd` → marker
  `WELCOME_SETTINGS_SYSTEM_SMOKE_OK` — verifica componenti condivisi,
  corrispondenza delle sezioni, sincronizzazione dei valori e comportamento di
  Back.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: cambia volume e dimensione joystick nella
      welcome, avvia la run e confronta gli stessi valori nella pausa
- [ ] Controllo percettivo richiesto: sì — le due schermate devono sembrare due
      istanze dello stesso sistema

## Decisioni

- **2026-08-31 — La pausa è il riferimento.** È già la variante più matura;
  la welcome ne adotta la grammatica senza alterarne il layout.
- **2026-08-31 — Coerenza non significa dimensioni identiche.** Il pannello
  della welcome può adattarsi alla copertina, purché componenti e gerarchia
  restino riconoscibili.

## Documenti sincronizzati

- [ ] `docs/ui-ux-flow.md`: identità condivisa delle impostazioni.

## Note

Se emerge una scena condivisa, la decisione va registrata qui prima di
estendere l'ambito oltre i due pannelli esistenti.
