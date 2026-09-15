---
id: PS-182
titolo: Il primo Boss (minuto 2) ha troppa vita
tipo: fix
area: gameplay
stato: PRONTO
priorita: alta
dipende_da: []
origine: test reale su Pixel 9 della v0.3.0, 2026-09-15
creato: 2026-09-15
aggiornato: 2026-09-15
---

# PS-182 — Il primo Boss (minuto 2) ha troppa vita

## Contesto

Il proprietario segnala che "il primo boss ha troppa vita", testando la
build reale v0.3.0. La soglia del primo Boss è a `t=120s`
(`GameDirectorProfile.boss_thresholds_seconds`,
[scripts/game/game_director_profile.gd:8](../../../scripts/game/game_director_profile.gd)),
e l'incontro garantito a quel punto è il Piccione Malvagio baseline
(`health_max = 2400.0`, [data/bosses/first_boss.tres:19](../../../data/bosses/first_boss.tres)),
salvo l'estrazione rara di un Evil (~10%, PS-127). A quel punto della run il
personaggio ha avuto poco tempo per accumulare upgrade offensivi, quindi
2400 HP può risultare uno scontro percepito come troppo lungo/spugnoso.

Non è chiaro dal feedback se "il primo boss" significhi sempre il Piccione
Malvagio baseline o genericamente il primo Boss incontrato in quella run
specifica (che potrebbe essere stato un Evil se l'estrazione rara di PS-127
è scattata): da chiarire con il proprietario prima di toccare i numeri.

## Comportamento atteso

Il primo scontro Boss della run (minuto 2) ha una durata percepita come
giusta, non eccessivamente lunga o spugnosa, mantenendo comunque la sua
identità di scontro "importante" della run.

## Criteri di accettazione

- [ ] Confermato con il proprietario quale Boss ha affrontato quando ha dato
      il feedback (baseline o Evil raro), per non ricalibrare il Boss
      sbagliato.
- [ ] `health_max` del Boss baseline (e/o degli Evil se il feedback riguarda
      loro) ricalibrato, con motivazione esplicita legata al DPS atteso del
      personaggio a `t=120s` (non un numero scelto a sensazione).
- [ ] Nessuna regressione sul contratto "Piccione Malvagio più difficile di
      ogni Evil" di [PS-127](../4_to_test/PS-127-piccione-malvagio-boss-raro-e-piu-difficile-degli-evil.md),
      se il baseline viene toccato.
- [ ] Verificato su almeno due personaggi diversi che il nuovo tempo di
      scontro si senta giusto in gioco reale.

## Ambito

- `data/bosses/first_boss.tres` (`health_max`).
- `data/friends/*.tres` solo se il feedback riguarda un Evil specifico, da
  confermare prima.
- Non toccare pattern, telegraph o Signature: questa card copre solo HP.

## Verifica

- Test GUT esistenti su HP/durata scontro Boss, aggiornati se il valore
  atteso cambia.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (gate primario: il sintomo è stato riportato
      lì)
- [ ] Controllo percettivo richiesto: sì — "la durata si sente giusta" è un
      giudizio di playtest reale, non un numero isolato

## Decisioni

- **2026-09-15 — Aperta come card separata da PS-127.** PS-127 ha reso il
  Piccione Malvagio deliberatamente più difficile degli Evil come scelta di
  design; questa card ricalibra solo se quel valore risulta eccessivo nel
  contesto del minuto 2, non mette in discussione la scelta di PS-127.

## Documenti sincronizzati

- [ ] `docs/enemies-bosses.md` se il valore di HP cambia in modo stabile.

## Note

Segnalato dal proprietario durante il test reale su Pixel 9 della v0.3.0,
insieme ad altri cinque problemi nella stessa sessione (PS-178..PS-181,
PS-183).
