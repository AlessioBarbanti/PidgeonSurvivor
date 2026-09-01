---
id: PS-062
titolo: Script di setup Godot nel sandbox remoto per validare prima di commit/push
tipo: chore
area: tooling
stato: COMPLETATO
priorita: media
dipende_da: []
origine:
creato: 2026-09-01
aggiornato: 2026-09-01
---

# PS-062 — Script di setup Godot nel sandbox remoto per validare prima di commit/push

## Contesto

Nelle card PS-059/060/061 ogni verifica reale (smoke GUT, export APK,
cattura UI) è passata da un ciclo commit → push → GitHub Actions → leggere i
log — anche per errori banali (un bug di case-sensitivity in un grep, una
cache d'importazione vuota) che un'esecuzione locale nel sandbox avrebbe
mostrato subito. Il proprietario ha chiesto esplicitamente uno strumento
lanciabile **prima** di commit/push, dentro il sandbox di questa sessione,
per validare le modifiche in autonomia invece di scoprirle solo dal CI.

Il sandbox remoto non ha Godot né Xvfb preinstallati, ma ha rete in uscita e
`sudo`/`apt` funzionanti (verificato in questa sessione).

## Comportamento atteso

Da una sessione remota senza toolchain, uno script installa Godot 4.7.1
headless e — se mancante — Xvfb/Mesa, così lo stesso sandbox può eseguire
localmente il warm-up della cache d'importazione, gli smoke GUT rilevanti e
`tools/_capture_ui_screenshots.gd`, prima di qualunque commit o push.

## Criteri di accettazione

- [x] Lo script è idempotente: se Godot o Xvfb sono già presenti, li rileva e
      salta la reinstallazione invece di ripeterla.
      *Verificato: la seconda invocazione nella stessa sessione ha stampato
      "Godot già presente"/"Xvfb già presente" e non ha ripetuto il download.*
- [x] Dopo lo script, `godot --headless --editor --path . --quit` (warm-up
      cache) e `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=...
      -gexit` (GUT) girano nello stesso sandbox senza installazioni
      aggiuntive.
      *Eseguiti entrambi in questa sessione: warm-up pulito (0 `ERROR` alla
      seconda esecuzione), GUT su
      `test_ps059_upgrade_modal_contrast.gd`/`test_ps046_level_up_modal_isolation.gd`/
      `test_ps047_upgrade_card_hierarchy.gd` → `3/3`, `2/2`, `2/2 passed`,
      nessun `SCRIPT ERROR`/`FATAL EXCEPTION`.*
- [x] Dopo lo script, `xvfb-run godot --path . --script
      tools/_capture_ui_screenshots.gd` produce PNG reali e ispezionabili
      (non vuoti, non segnaposto) nello stesso sandbox.
      *Eseguito in questa sessione: `CAPTURE_DONE`, 26 scatti per profilo,
      file non vuoti (centinaia di KB ciascuno); `05_upgrade_overlay.png`,
      `05b_barb_speciality.png`, `05c_barb_bonus.png` ispezionati a occhio
      con il tool `Read` — vedi PS-059.*
- [x] Non richiede Android SDK/NDK/JDK: resta uno strumento leggero per
      GDScript/scene/test, non un sostituto del percorso APK di PS-060.
      *Lo script installa solo Godot e Xvfb/Mesa; nessun riferimento ad
      Android SDK.*
- [x] Il file è eseguibile e documenta nel proprio header i comandi di
      validazione successivi (warm-up, GUT, cattura), cosi' non serve
      ricostruirli da un'altra card ogni volta.
      *`chmod +x` applicato; header dello script elenca i tre comandi.*

## Ambito

- Nuovo file `tools/setup-remote-sandbox.sh`.

Non toccare:

- `.github/workflows/android-debug-release.yml` (PS-060) e
  `.github/workflows/ui-screenshots.yml` (PS-061): restano i percorsi CI,
  distinti da questo script locale;
- `tools/*.ps1`: restano il percorso Windows, non toccati né duplicati;
- `docs/setup.md`: quello resta il contratto della toolchain Windows; questo
  script è per sessioni remote senza toolchain, non una terza baseline
  ufficiale.

## Verifica

- Non esiste (e non serve) uno smoke GUT per questo script: è tooling di
  bootstrap del sandbox, non comportamento del gioco. La verifica è l'uso
  reale che ne è stato fatto in questa sessione (vedi Criteri sopra).

## Gate manuali

- [x] Runtime Windows: non pertinente, lo script è per sandbox Linux remoti.
- [x] Validazione statica APK: non pertinente.
- [x] Runtime fisico Pixel 9: non pertinente.
- [x] Controllo percettivo richiesto: no per lo script in sé; abilita il
      controllo percettivo locale usato da PS-059/061.

## Decisioni

- **2026-09-01 — Solo Godot + Xvfb, non Android SDK/NDK.** La richiesta del
  proprietario era di validare "quello che ho fatto" prima di push: la
  stragrande maggioranza delle modifiche di questa sessione sono
  GDScript/scene, verificabili con GUT e le catture UI. L'export APK resta
  un percorso pesante (SDK+NDK, build Gradle) già coperto da PS-060 in CI;
  aggiungerlo qui è fuori scopo salvo richiesta esplicita futura.
- **2026-09-01 — Script committato in `tools/`, non solo eseguito ad-hoc.**
  Cosi' resta disponibile per sessioni future (questa o altre) invece di
  essere ridigitato ogni volta; il container del sandbox è comunque effimero,
  quindi va rilanciato a ogni nuova sessione.
- **2026-09-01 — Nessuna terza "baseline" toolchain in `docs/setup.md`.**
  Quel documento resta il contratto Windows; questo script è dichiaratamente
  un ripiego per sessioni remote, non un secondo percorso ufficiale da
  mantenere allineato in versione con lo stesso rigore.

## Documenti sincronizzati

- [ ] Nessuno: `docs/setup.md` resta il contratto della toolchain Windows,
      non va esteso con un percorso sandbox che non è quello ufficiale del
      progetto.

## Note

Nato durante la stessa sessione di PS-059/060/061, dopo che il proprietario
ha fatto notare che il ciclo push→CI→log per ogni errore locale era
inefficiente. Lo script è già stato usato per validare retroattivamente
PS-059 (smoke + cattura UI reali, non solo scritti) prima di chiudere questa
card.
