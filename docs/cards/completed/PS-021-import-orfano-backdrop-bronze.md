---
id: PS-021
titolo: Rimuovi l'import orfano del backdrop bronze del selettore
tipo: chore
area: arte
stato: COMPLETATO
priorita: bassa
dipende_da: []
origine: PS-020
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-021 — Rimuovi l'import orfano del backdrop bronze del selettore

## Contesto

`assets/art/ui/character_select/character_select_backdrop_bronze.png.import` è
tracciato in git ma il PNG che dichiara come `source_file`
(`assets/art/ui/character_select/character_select_backdrop_bronze.png`) non
esiste più: il commit `3d048e4` ha promosso quella variante al nome definitivo
`character_select_backdrop.png` lasciando indietro il vecchio `.import`. Il
file orfano descrive un `uid://` e un `.ctex` in `.godot/imported/` che nessuna
scena consuma, e ogni scansione dell'editor deve occuparsene di nuovo.

Scoperto durante la diagnosi di [PS-020](./PS-020-diagnostica-flakiness-backdrop-selettore.md):
non è la causa dell'intermittenza lì analizzata, ma è residuo dello stesso
cambio di asset.

## Comportamento atteso

Nel repository non resta alcun file `.import` tracciato il cui `source_file`
non esiste. Il fondale del selettore personaggi resta invariato.

## Criteri di accettazione

- [x] `assets/art/ui/character_select/character_select_backdrop_bronze.png.import`
      non è più tracciato in git.
- [x] Nessun altro `.import` tracciato punta a un `source_file` inesistente.
- [x] Il selettore personaggi mostra ancora
      `assets/art/ui/character_select/character_select_backdrop.png`
      (contratto B18W in `movement_slice.gd`) dopo un refresh della cache
      dell'editor.

## Ambito

- `assets/art/ui/character_select/character_select_backdrop_bronze.png.import`.

Non modificare:

- i master in `assets/art/ui/character_select/hd/` (esclusi da import ed export
  con `.gdignore`) né le righe che li documentano nel `ASSET-MANIFEST.md` della
  cartella;
- `character_select_backdrop.png` e il contratto B18W.

## Verifica

- Test: `tests/unit/test_b18b_visual_identity.gd`,
  `tests/unit/test_b18w_character_select_refinement.gd`.
- Profilo minimo prima della chiusura: `Relevant`, con `-RefreshEditor`.

## Gate manuali

- [x] Runtime Windows: non richiesto, la card rimuove un descrittore di
      import senza sorgente e non tocca nulla che finisca nel binario.
- [x] Validazione statica APK: non richiesta, stesso motivo.
- [x] Runtime fisico Pixel 9: non richiesto
- [x] Controllo percettivo richiesto: no

## Decisioni

- **2026-08-30 — Card separata invece di allargare PS-020.** PS-020 è una
  diagnosi di intermittenza; questo è un residuo di igiene del repository con
  un rischio e una verifica propri.

## Documenti sincronizzati

- [x] Nessun contratto cambia.

## Note

**Rimozione (2026-08-30).** `git rm` del `.import` orfano, più i due file
morti che descriveva in `.godot/imported/`
(`character_select_backdrop_bronze.png-2a592ab30e3198ffc0bd107148ec5471.ctex`
e il `.md5` gemello): non erano rigenerabili, il loro sorgente non esiste.

Prima di rimuoverlo ho verificato che nessuno lo usasse: il suo
`uid://bqfecv3a2thto` non compare da nessuna parte fuori dal file stesso, e
`character_select_backdrop_bronze` non compare in `scenes/`, `scripts/`,
`data/`, `tests/`, `tools/` né in `project.godot`.

**Audit completo.** Su 146 `.import` tracciati era l'unico senza sorgente:

```sh
git ls-files '*.import' | while read -r f; do
  [ -f "${f%.import}" ] || echo "ORFANO: $f"
done
```

**Verifica.** `Relevant` con `-RefreshEditor -NoCache` (log
`20260830-140828-PS-021`): `status=PASS`, refresh editor verde, `b18b` e
`b18w` verdi più l'intera suite di regressione, nessuno step rosso.

Stato osservato il 2026-08-30 prima della rimozione:

```
$ git ls-files assets/art/ui/character_select/
...
assets/art/ui/character_select/character_select_backdrop_bronze.png.import
$ ls assets/art/ui/character_select/character_select_backdrop_bronze.png
No such file or directory
```
