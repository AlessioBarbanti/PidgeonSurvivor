---
id: PS-019
titolo: Riallinea l'hash del manifest VFX per instinctive_dodge_accent
tipo: chore
area: arte
stato: COMPLETATO
priorita: bassa
dipende_da: []
origine:
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-019 — Riallinea l'hash del manifest VFX per instinctive_dodge_accent

## Contesto

`assets/art/vfx/ASSET-MANIFEST.md` dichiara per
`scripts/abilities/instinctive_dodge_accent.gd` uno SHA-256 che non
corrisponde più al contenuto attuale del file. Scoperto durante la
migrazione dei test da smoke legacy a GUT; sia il vecchio smoke sia il test
GUT falliscono correttamente su questa discrepanza (non è un buco del
gate). È probabile che la causa sia una modifica in corso, non ancora
committata al momento della scoperta, su quello script (lavoro dell'utente
in area proiettili/VFX, non tracciato da questa card).

## Comportamento atteso

L'hash SHA-256 registrato in `assets/art/vfx/ASSET-MANIFEST.md` per
`scripts/abilities/instinctive_dodge_accent.gd` corrisponde esattamente al
contenuto del file al momento della chiusura di questa card.

## Criteri di accettazione

- [x] L'hash SHA-256 nel manifest corrisponde all'hash effettivo del file
      (`Get-FileHash -Algorithm SHA256`).
- [x] Il controllo automatico che verifica questa corrispondenza passa in
      isolamento.

## Ambito

- `assets/art/vfx/ASSET-MANIFEST.md`, solo la riga relativa a
  `instinctive_dodge_accent.gd`.

Non modificare:

- il contenuto di `scripts/abilities/instinctive_dodge_accent.gd` stesso:
  questa card sincronizza il manifest al file, non il contrario, salvo che
  il proprietario non chieda esplicitamente il contrario.

## Verifica

- Test: `tests/unit/test_b18m_ability_visuals.gd` — fallisce oggi sul
  controllo di corrispondenza hash.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [x] Runtime Windows: non richiesto, la card modifica solo un documento e
      non tocca nulla che finisca nel binario.
- [x] Validazione statica APK: non richiesta, stesso motivo.
- [x] Runtime fisico Pixel 9: non richiesto
- [x] Controllo percettivo richiesto: no

## Decisioni

- **2026-08-30 — Scoperto durante la migrazione GUT, non introdotto da
  essa.** Sia lo smoke legacy sia il test GUT falliscono correttamente:
  nessun gap del gate, solo un manifest da riallineare.
- **2026-08-30 — Il file era stabile, quindi si è potuto ricalcolare.** La
  nota della card chiedeva di verificare prima che lo script non fosse ancora
  in lavorazione: l'ultima modifica è il commit `3d048e4` («Refactor Bea's
  abilities: Rename "Scarto Istintivo" to "Sesto Senso Equino"»), già
  committato, e `git status` era pulito.
- **2026-08-30 — Aggiornata solo la tabella «Integrazione corrente».** Il
  file compare in due tabelle del manifest. La seconda («Sorgenti procedurali
  runtime») è un registro storico di provenienza: per *tutti* gli altri
  script i due hash già divergono, e il test chiede solo che l'hash corrente
  compaia da qualche parte nel documento. Toccare anche la riga storica
  avrebbe riscritto un record di registrazione, non riallineato un contratto.

## Documenti sincronizzati

- [x] `assets/art/vfx/ASSET-MANIFEST.md` (è l'oggetto stesso della card).

## Note

Se al momento di riprendere questa card lo script risulta ancora in
lavorazione attiva da parte del proprietario, verificare prima con lui se
il file è da considerarsi stabile: ricalcolare l'hash contro una versione
ancora in corso di modifica sposterebbe solo il problema.

Evidenze (2026-08-30):

```
57d9f40966aa37c523f4d67f4a235d3ff5671d4b746097d0aca7a29c073847b6  (manifest, prima)
6A07AE5B742A3BC92D5A79A4288C075D6E73005A7E00A803E46185DC331C8AA7  (Get-FileHash, file attuale)
```

Riga aggiornata: `assets/art/vfx/ASSET-MANIFEST.md:99`.

```powershell
.	oolsun-milestone-checks.ps1 -Milestone PS-019 -Profile Focused `
  -FocusedSmoke tests/unit/test_b18m_ability_visuals.gd -OutputMode Detailed -NoCache
```

→ `status=PASS`, log `20260830-135555-PS-019`. Lo stesso test è verde anche
dentro la suite completa del profilo `Relevant` (log `20260830-133544-PS-013`,
`test_b18m_ability_visuals.gd` 2/2 verdi).
