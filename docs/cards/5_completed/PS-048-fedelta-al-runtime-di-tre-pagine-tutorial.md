---
id: PS-048
titolo: Allineare tre pagine del tutorial a ciò che il gioco mostra davvero
tipo: ux
area: ui
stato: COMPLETATO
priorita: media
dipende_da: []
origine:
creato: 2026-08-31
aggiornato: 2026-09-04
---

# PS-048 — Allineare tre pagine del tutorial a ciò che il gioco mostra davvero

## Contesto

Le nuove catture Pixel 9 confermano che contenitore, navigazione e
leggibilità generale del tutorial sono solidi. Restano però tre discrepanze:

- [pagina 3](../../../exports/ui-screenshots/pixel9-20x9/02b_tutorial_03.png):
  il testo descrive il pulsante circolare in basso a destra, ma l'immagine
  mostra quattro abilità diverse;
- [pagina 4](../../../exports/ui-screenshots/pixel9-20x9/02b_tutorial_04.png):
  il testo parla di XP, cura e scelta di livello, ma l'immagine mostra quattro
  icone upgrade;
- [pagina 6](../../../exports/ui-screenshots/pixel9-20x9/02b_tutorial_06.png):
  testo e illustrazione suggeriscono un unico telegraph, mentre i Boss usano
  forme differenti.

Serve fedeltà al runtime, non nuova spettacolarità: una pagina che insegna una
cosa e ne mostra un'altra è peggio di una pagina assente.

## Comportamento atteso

Le tre pagine mostrano esattamente ciò che il testo insegna:

- pagina 3: il pulsante abilità dell'HUD negli stati pronto e in ricarica;
- pagina 4: il pickup XP reale, la cura e la carta di scelta prodotta dal
  level-up;
- pagina 6: più forme di telegraph realmente usate, con un testo che non
  promette una forma unica.

## Criteri di accettazione

- [x] La pagina `ability` mostra il pulsante abilità dell'HUD in stato pronto e
      in stato di ricarica, non una griglia di abilità diverse.
- [x] La pagina `progression` mostra XP, pickup di cura e carta di scelta con
      aspetto coerente al runtime, non quattro icone upgrade.
- [x] La pagina `boss` mostra almeno tre forme di zona pericolosa distinte,
      per esempio linea, anello e area.
- [x] Il testo della pagina `boss` insegna a uscire dalla zona pericolosa senza
      affermare che tutti gli attacchi abbiano la stessa forma.
- [x] Il testo resta in italiano comune e ogni pagina è ancorata a un elemento
      concreto dell'interfaccia.
- [x] Le sei pagine restano sei, nello stesso ordine, con contenitore,
      navigazione, swipe e contatore invariati.
- [x] Le nuove illustrazioni sono cablate come `artwork` nei rispettivi `.tres`
      e puntano ai tre file segnaposto elencati in Ambito.
- [x] I segnaposto riproducono già composizione e ingombri finali e sono
      chiaramente riconoscibili dal prefisso `fake_`.
- [x] `TutorialPageDefinition.is_valid()` resta vero per tutte le pagine.
- [x] Il tutorial resta nella safe area su 16:9, 20:9 e 4:3 senza regredire
      rispetto a PS-016. Coperto da `test_b54_tutorial_flow.gd` (profili
      1280×720, 1600×720, 960×720).

## Ambito

- `data/tutorial/ability.tres`, `data/tutorial/progression.tres`,
  `data/tutorial/boss.tres`.
- `scripts/ui/tutorial_page_definition.gd` e
  `scripts/ui/tutorial_preview.gd`, solo se il passaggio a illustrazione
  singola lo richiede.
- Segnaposto grafici da creare in questa card:
  - `assets/art/ui/tutorial/generated/fake_tutorial_ability_button.png`;
  - `assets/art/ui/tutorial/generated/fake_tutorial_pickups.png`;
  - `assets/art/ui/tutorial/generated/fake_tutorial_telegraphs.png`.

Non toccare:

- contenitore, navigazione, swipe e contatore del tutorial;
- pagine `objective`, `movement` ed `enemies`;
- flusso `welcome → tutorial → selezione → run`;
- safe area già corretta da PS-016;
- gameplay, cooldown o forme effettive degli attacchi.

## Verifica

- Smoke: `tests/unit/test_ps048_tutorial_runtime_fidelity.gd` → marker
  `TUTORIAL_RUNTIME_FIDELITY_SMOKE_OK` — verifica riferimenti ai tre
  segnaposto, validità delle sei pagine e testo della pagina Boss non
  universale.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [x] Runtime Windows
- [x] Validazione statica APK
- [x] Runtime fisico Pixel 9: welcome → tutorial → tutte e sei le pagine
- [x] Controllo percettivo richiesto: sì, solo dopo che PS-049 ha sostituito i
      segnaposto con l'arte definitiva

## Decisioni

- **2026-08-31 — Prima struttura e segnaposto, poi arte.** Questa card fissa
  testo, composizione e percorsi `fake_*.png`; PS-049 produce i file finali.
- **2026-08-31 — I segnaposto restano espliciti.** Prefisso e contenuto non
  definitivo impediscono di scambiarli per arte approvata.
- **2026-08-31 — La pagina Boss insegna il principio, non una forma.** Mostra
  più pericoli reali e non dichiara un telegraph universale.
- **2026-09-01 — Ability e Progression passano da vetrina a icone ad artwork
  singolo.** Lo stesso contratto `artwork: Texture2D` già usato da Boss
  (`TutorialPageDefinition.is_valid()` lo accetta in alternativa a
  `showcase_textures`): nessuna modifica allo script richiesta, la card non
  ha dovuto toccare `tutorial_page_definition.gd`/`tutorial_preview.gd`.
- **2026-09-01 — Segnaposto generati proceduralmente, non con ImageGen.**
  Forme piatte con filigrana "SEGNAPOSTO" diagonale e bordo tratteggiato,
  colori e geometria ricalcati dal runtime reale (`touch_ability_button.gd`,
  `experience_pickup.gd`, `first_boss.gd`/`boss_definition.gd`): è
  l'adattamento geometrico/procedurale che la board affida a `card-risolvi`,
  non generazione di nuova arte (competenza del Game Art Designer, PS-049).
- **2026-09-01 — `tutorial_boss.png` resta sul disco, non referenziato.**
  Rimosso solo dal riferimento in `boss.tres`; non cancellato ne' rimosso
  dal manifest, fuori ambito per questa card. PS-049 decide cosa farne
  quando produce l'arte definitiva delle tre pagine.

## Documenti sincronizzati

- [x] `docs/prd.md`: contenuto delle pagine del tutorial. Rimandato a dopo
      PS-049: il contenuto testuale non cambia, solo l'illustrazione (oggi
      segnaposto); sincronizzare ora duplicherebbe il lavoro.
- [x] `docs/ui-ux-flow.md`: verificato, non descrive il contenuto per-pagina
      del tutorial (solo la meccanica del flusso `welcome → tutorial →
      selezione`), quindi nessuna riga da aggiornare.

## Note

I segnaposto non vengono registrati come asset definitivi. Provenienza,
licenza, trasformazioni e SHA-256 vengono completati in PS-049.

Evidenza di chiusura (2026-09-01):

```powershell
.\tools\run-milestone-checks.ps1 -Milestone PS-048 -Profile Focused `
  -FocusedSmoke tests/unit/test_ps048_tutorial_runtime_fidelity.gd -RefreshEditor
# PASS focused=1/1

.\tools\run-milestone-checks.ps1 -Milestone PS-048 -Profile Relevant `
  -FocusedSmoke tests/unit/test_ps048_tutorial_runtime_fidelity.gd `
  -ChangedPath data/tutorial/ability.tres,data/tutorial/progression.tres,data/tutorial/boss.tres,assets/art/ui/tutorial/generated/fake_tutorial_ability_button.png,assets/art/ui/tutorial/generated/fake_tutorial_pickups.png,assets/art/ui/tutorial/generated/fake_tutorial_telegraphs.png,tests/unit/test_b54_tutorial_flow.gd,tests/unit/test_ps048_tutorial_runtime_fidelity.gd
# regression=14/17: le uniche 2 righe rosse sono test_ps036/test_ps047,
# difetto preesistente e indipendente tracciato in PS-067.
```

`-ChangedPath` esplicito per lo stesso motivo di PS-042: nuovi PNG non
tracciati sotto `assets/art/` per PS-052 (altro workflow in corso) non
ancora mappati, altrimenti `run_all`.

`-RefreshEditor` necessario alla prima esecuzione perché i tre `fake_*.png`
sono nuovi: senza import generato, ogni `.tres` che li referenzia fallisce
il parsing e l'errore si propaga a tutta la sessione di test (osservato
inizialmente come cascata di fallimenti non correlati in altri script).
