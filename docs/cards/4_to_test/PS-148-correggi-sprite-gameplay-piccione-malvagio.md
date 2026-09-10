---
id: PS-148
titolo: Correggi lo sprite di gameplay del Piccione Malvagio che mostra il ritratto
tipo: fix
area: gameplay
stato: IN VERIFICA
priorita: alta
dipende_da: []
origine:
creato: 2026-09-10
aggiornato: 2026-09-10
---

# PS-148 — Correggi lo sprite di gameplay del Piccione Malvagio che mostra il ritratto

## Contesto

In game il Piccione Malvagio (Boss baseline, `data/bosses/first_boss.tres`)
mostra il busto 256×256 pensato per la Boss intro al posto del proprio sprite
di gameplay. Causa: `BossDefinition.get_visual_texture()`
([scripts/bosses/boss_definition.gd:107-110](../../../scripts/bosses/boss_definition.gd#L107-L110))
ritorna il campo `portrait` per qualunque Boss che non sia una variante Evil
(`visual_kind != EVIL_FRIEND`), e
[first_boss.gd:434](../../../scripts/bosses/first_boss.gd#L434) assegna quel
valore direttamente a `_boss_sprite.texture`.

Prima di [PS-129](../5_completed/PS-129-integra-ritratto-piccione-malvagio-boss-intro.md)
il comportamento era corretto per coincidenza: `portrait` era un
`AtlasTexture` che ritagliava un riquadro 48×48 da
`assets/art/enemies/pigeons/pigeon_special.png`, cioè lo sprite di gameplay
stesso. PS-129 ha sostituito quel campo con il nuovo busto definitivo per la
Boss intro dichiarando esplicitamente "non toccare lo sprite di gameplay", ma
nessuna card ha mai disaccoppiato le due funzioni: `get_visual_texture()`
continua a leggere lo stesso campo che ora contiene il busto, quindi lo sprite
in game è regredito senza che nessun criterio di accettazione lo coprisse.

Non serve rigenerare o recuperare arte da vecchi commit: lo sprite di
gameplay esiste già, intatto, in `pigeon_special.png`.

## Comportamento atteso

Durante una run, il Piccione Malvagio mostra sul campo lo stesso sprite
48×48 ritagliato da `pigeon_special.png` che mostrava prima di PS-129. La
Boss intro continua a mostrare il busto 256×256 definitivo introdotto da
PS-128/PS-129, invariato.

## Criteri di accettazione

- [x] `BossDefinition` espone un campo `Texture2D` dedicato allo sprite di
      gameplay, distinto da `portrait`.
- [x] `data/bosses/first_boss.tres` valorizza quel campo con l'`AtlasTexture`
      preesistente (`region = Rect2(0, 0, 48, 48)` su
      `assets/art/enemies/pigeons/pigeon_special.png`), la stessa in uso
      prima di PS-129.
- [x] `BossDefinition.get_visual_texture()` per un Boss con
      `visual_kind != EVIL_FRIEND` ritorna il nuovo campo, non `portrait`;
      il ramo Evil (`friend_profile.get_gameplay_idle_right()`) resta
      invariato — verificato da
      `test_ps148_boss_baseline_gameplay_sprite.gd`.
- [x] `BossDefinition.get_safe_portrait()` e la Boss intro continuano a
      risolvere `portrait` (il busto 256×256): nessuna regressione su
      `tests/unit/test_ps051_boss_intro_identity.gd` (profilo `Relevant`,
      14/14 regressioni verdi).
- [x] HP, danno, velocità, pattern, colori e ogni altro dato del Boss
      baseline restano invariati: nessun campo dati toccato in
      `first_boss.tres` oltre a `sprite`.

## Ambito

- `scripts/bosses/boss_definition.gd`: nuovo campo texture di gameplay,
  correzione di `get_visual_texture()`.
- `data/bosses/first_boss.tres`: valorizzazione del nuovo campo.
- Test dedicato e mappa regressioni se necessaria.

Non toccare:

- Il busto `assets/art/characters/piccione_malvagio/generated/portrait.png`
  e il wiring della Boss intro (PS-129);
- `pigeon_special.png` e lo sprite di gameplay in sé, solo referenziato di
  nuovo dal campo corretto;
- Dati o pattern di gameplay del Boss baseline (competenza di
  [PS-127](../4_to_test/PS-127-piccione-malvagio-boss-raro-e-piu-difficile-degli-evil.md)).

## Verifica

- Smoke: nuovo `tests/unit/test_ps148_boss_baseline_gameplay_sprite.gd` →
  marker `PS148_BASELINE_GAMEPLAY_SPRITE_SMOKE_OK`; verifica che
  `get_visual_texture()`/il nodo `BossSprite` del baseline risolvano
  `definition.sprite` e non `get_safe_portrait()`, e che il ramo Evil resti
  sullo sprite idle del friend. Registrato in
  `tools/milestone-test-map.json` sotto `scripts/bosses/*`/`data/bosses/*`.
- Focused: `1/1` file, 2 test, 0 failure, nessun `SCRIPT ERROR`/
  `FATAL EXCEPTION`.
- Relevant: `1/1` focused, `14/14` regressioni (incluso
  `test_ps051_boss_intro_identity.gd`), 15/15 step, nessun `SCRIPT ERROR`/
  `FATAL EXCEPTION`.
- Full: `1/1` focused, `136/136` regressioni (425 asserzioni, 0 fallite),
  toolchain PASS, 138/138 step, nessun `SCRIPT ERROR`/`FATAL EXCEPTION` nei
  log. `first_boss.tres` viene caricato ed esercitato da tutta la suite Boss
  senza errori di parsing o risoluzione risorse.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: incontrare il Piccione Malvagio in
      run e osservare lo sprite sul campo)
- [ ] Controllo percettivo richiesto: sì, confronto sprite in game
      pre/post fix

## Decisioni

- **2026-09-10 — Regressione di PS-129, non nuova produzione artistica.**
  Segnalato dal proprietario in game. Nessun nuovo asset richiesto: fix di
  wiring che ripristina un riferimento già esistente.
- **2026-09-10 — Automatici verdi, gate manuali lasciati aperti per
  onestà.** Il profilo `Full` (toolchain + 136/136 regressioni via GUT, che
  carica ed esercita `first_boss.tres` dentro il motore Godot reale) dà alta
  confidenza che il file `.tres` sia corretto e privo di errori di
  risoluzione risorse, ma non equivale a un export/avvio Windows reale né a
  un'ispezione statica dell'APK: quei gate, insieme al percorso fisico
  Pixel 9 e al confronto percettivo del proprietario, restano non eseguiti
  e quindi non spuntati.

## Documenti sincronizzati

- [ ] Nessuno a questo stadio: nessun contratto di prodotto o catalogo
      cambia, solo un bug di rendering.

## Note

—
