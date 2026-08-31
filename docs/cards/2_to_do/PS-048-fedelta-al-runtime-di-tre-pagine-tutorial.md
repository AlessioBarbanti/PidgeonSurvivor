---
id: PS-048
titolo: Allineare tre pagine del tutorial a ciò che il gioco mostra davvero
tipo: ux
area: ui
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-08-31
aggiornato: 2026-08-31
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

- [ ] La pagina `ability` mostra il pulsante abilità dell'HUD in stato pronto e
      in stato di ricarica, non una griglia di abilità diverse.
- [ ] La pagina `progression` mostra XP, pickup di cura e carta di scelta con
      aspetto coerente al runtime, non quattro icone upgrade.
- [ ] La pagina `boss` mostra almeno tre forme di zona pericolosa distinte,
      per esempio linea, anello e area.
- [ ] Il testo della pagina `boss` insegna a uscire dalla zona pericolosa senza
      affermare che tutti gli attacchi abbiano la stessa forma.
- [ ] Il testo resta in italiano comune e ogni pagina è ancorata a un elemento
      concreto dell'interfaccia.
- [ ] Le sei pagine restano sei, nello stesso ordine, con contenitore,
      navigazione, swipe e contatore invariati.
- [ ] Le nuove illustrazioni sono cablate come `artwork` nei rispettivi `.tres`
      e puntano ai tre file segnaposto elencati in Ambito.
- [ ] I segnaposto riproducono già composizione e ingombri finali e sono
      chiaramente riconoscibili dal prefisso `fake_`.
- [ ] `TutorialPageDefinition.is_valid()` resta vero per tutte le pagine.
- [ ] Il tutorial resta nella safe area su 16:9, 20:9 e 4:3 senza regredire
      rispetto a PS-016.

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

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: welcome → tutorial → tutte e sei le pagine
- [ ] Controllo percettivo richiesto: sì, solo dopo che PS-049 ha sostituito i
      segnaposto con l'arte definitiva

## Decisioni

- **2026-08-31 — Prima struttura e segnaposto, poi arte.** Questa card fissa
  testo, composizione e percorsi `fake_*.png`; PS-049 produce i file finali.
- **2026-08-31 — I segnaposto restano espliciti.** Prefisso e contenuto non
  definitivo impediscono di scambiarli per arte approvata.
- **2026-08-31 — La pagina Boss insegna il principio, non una forma.** Mostra
  più pericoli reali e non dichiara un telegraph universale.

## Documenti sincronizzati

- [ ] `docs/prd.md`: contenuto delle pagine del tutorial.
- [ ] `docs/ui-ux-flow.md`, se cambia la struttura di una pagina.

## Note

I segnaposto non vengono registrati come asset definitivi. Provenienza,
licenza, trasformazioni e SHA-256 vengono completati in PS-049.
