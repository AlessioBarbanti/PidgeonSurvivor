---
id: PS-019
titolo: Riallinea l'hash del manifest VFX per instinctive_dodge_accent
tipo: chore
area: arte
stato: PRONTO
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

- [ ] L'hash SHA-256 nel manifest corrisponde all'hash effettivo del file
      (`Get-FileHash -Algorithm SHA256`).
- [ ] Il controllo automatico che verifica questa corrispondenza passa in
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

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: non richiesto
- [ ] Controllo percettivo richiesto: no

## Decisioni

- **2026-08-30 — Scoperto durante la migrazione GUT, non introdotto da
  essa.** Sia lo smoke legacy sia il test GUT falliscono correttamente:
  nessun gap del gate, solo un manifest da riallineare.

## Documenti sincronizzati

- [ ] `assets/art/vfx/ASSET-MANIFEST.md` (è l'oggetto stesso della card).

## Note

Se al momento di riprendere questa card lo script risulta ancora in
lavorazione attiva da parte del proprietario, verificare prima con lui se
il file è da considerarsi stabile: ricalcolare l'hash contro una versione
ancora in corso di modifica sposterebbe solo il problema.
