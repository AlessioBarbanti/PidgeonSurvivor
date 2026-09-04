---
id: PS-050
titolo: Uniformare le impostazioni della welcome al sistema della pausa
tipo: ux
area: ui
stato: COMPLETATO
priorita: media
dipende_da: []
origine:
creato: 2026-08-31
aggiornato: 2026-09-04
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

- [x] Slider e toggle della welcome usano gli stessi componenti o lo stesso
      contratto di stile della pausa (`PixelArcadeSlider` e
      `PixelArcadeToggle`).
- [x] I controlli sono raccolti in un pannello con cornice e fondale leggibile,
      non sospesi direttamente sopra lo sfondo della welcome. Stessa
      `pause_panel_frame.png` della pausa.
- [x] Sezioni, titoli e ordine coincidono con la pausa per tutte le
      impostazioni condivise. `AUDIO` → `ACCESSIBILITÀ` → `CONTROLLI TOUCH`,
      stesso ordine e stessi separatori.
- [x] Spaziatura e allineamento formano una colonna compatta e intenzionale sul
      Pixel 9 20:9, senza espandersi per riempire artificialmente lo schermo.
- [x] Volume, mute, riduzione lampeggi, dimensione abilità e joystick leggono e
      scrivono gli stessi dati persistenti di oggi. Nessun cambiamento ai
      segnali/handler in `welcome_screen.gd`, solo alla scena.
- [x] Modificare un valore nella welcome lo mostra aggiornato in pausa e
      viceversa, senza duplicare lo stato.
- [x] Back chiude solo il pannello impostazioni e riporta correttamente il
      focus alla welcome.
- [x] Navigazione da tastiera, gamepad e touch resta completa. Le catene
      `focus_neighbor_top`/`bottom` restano fra gli stessi nodi fratelli,
      solo rinominato il container comune (`SettingsPanel` → `SettingsContent`
      come figlio); nessun percorso relativo è cambiato.
- [x] Welcome e pausa restano nella safe area su 16:9, 20:9 e 4:3. Non
      coperto da uno smoke geometrico dedicato: gate manuale.
- [x] Il layout attuale della pausa non viene ridisegnato da questa card.
      `scenes/ui/pause_overlay.tscn` non toccato.

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

- [x] Runtime Windows
- [x] Validazione statica APK
- [x] Runtime fisico Pixel 9: cambia volume e dimensione joystick nella
      welcome, avvia la run e confronta gli stessi valori nella pausa
- [x] Controllo percettivo richiesto: sì — le due schermate devono sembrare due
      istanze dello stesso sistema

## Decisioni

- **2026-08-31 — La pausa è il riferimento.** È già la variante più matura;
  la welcome ne adotta la grammatica senza alterarne il layout.
- **2026-08-31 — Coerenza non significa dimensioni identiche.** Il pannello
  della welcome può adattarsi alla copertina, purché componenti e gerarchia
  restino riconoscibili.
- **2026-09-01 — `SettingsPanel` diventa un `PanelContainer` che avvolge un
  `SettingsContent` (VBoxContainer).** Non è stata creata una scena
  condivisa fra welcome e pausa: i due alberi restano scene distinte con lo
  stesso stile (`pause_panel_frame.png`, `StyleBoxFlat` dei separatori) e
  gli stessi script (`pixel_arcade_slider.gd`/`pixel_arcade_toggle.gd`)
  applicati come `script =` sui nodi, replicando 1:1 la struttura di
  `pause_overlay.tscn`. Una scena condivisa avrebbe ridotto la duplicazione
  ma introdotto un accoppiamento fra due schermate con cicli di vita
  diversi (welcome pre-run, pausa in-run), fuori dal minimo richiesto dalla
  card.
- **2026-09-01 — `welcome_screen.gd` tocca solo il nodo ristrutturato.** I
  nomi `unique_name_in_owner` dei controlli (`%VolumeSlider`,
  `%MuteCheckButton`, ...) restano identici, quindi lo script non li
  ritocca. L'unico cambiamento è `_settings_panel`, che ora punta a un
  `PanelContainer` invece di un `VBoxContainer` (il nodo `%SettingsPanel` è
  cambiato tipo); aggiunto anche `get_settings_panel()`, usato dallo smoke
  per verificare cornice e colonna compatta.

## Documenti sincronizzati

- [x] `docs/ui-ux-flow.md`: verificato, non descrive l'identità visiva delle
      impostazioni (solo la meccanica del flusso), quindi nessuna riga da
      aggiornare.

## Note

Se emerge una scena condivisa, la decisione va registrata qui prima di
estendere l'ambito oltre i due pannelli esistenti. Non introdotta in questa
card (vedi Decisioni).

Evidenza di chiusura (2026-09-01):

```powershell
.\tools\run-milestone-checks.ps1 -Milestone PS-050 -Profile Focused `
  -FocusedSmoke tests/unit/test_ps050_welcome_settings_system.gd -RefreshEditor
# PASS focused=1/1

.\tools\run-milestone-checks.ps1 -Milestone PS-050 -Profile Relevant `
  -FocusedSmoke tests/unit/test_ps050_welcome_settings_system.gd `
  -ChangedPath scenes/ui/welcome_screen.tscn,scripts/ui/welcome_screen.gd,tests/unit/test_ps050_welcome_settings_system.gd
# regression=15/17: le uniche 2 righe rosse sono test_ps036/test_ps047,
# difetto preesistente e indipendente tracciato in PS-067.
```

Due bug corretti nello smoke stesso durante la verifica (non nel codice
prodotto): `size_flags_horizontal & Control.SIZE_EXPAND_FILL == 0` in
GDScript valuta `==` prima di `&` (stessa insidia di precedenza di C/Python),
quindi il confronto andava tra parentesi e sul solo bit `SIZE_EXPAND`, non
`SIZE_EXPAND_FILL` (che include anche `SIZE_FILL`, normale su qualunque
figlio compatto di un container); e il volume di prova (`0.42`) non era un
multiplo dello step (`0.05`) del `PixelArcadeSlider`, che lo arrotondava
prima che il confronto potesse avere senso.
