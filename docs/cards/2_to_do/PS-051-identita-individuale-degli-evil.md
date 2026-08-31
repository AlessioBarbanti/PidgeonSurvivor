---
id: PS-051
titolo: Dare identità individuale agli Evil nella Boss intro
tipo: ux
area: ui
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-08-31
aggiornato: 2026-08-31
---

# PS-051 — Dare identità individuale agli Evil nella Boss intro

## Contesto

La nuova
[06_boss_intro.png](../../../exports/ui-screenshots/pixel9-20x9/06_boss_intro.png)
mostra il `PICCIONE MALVAGIO` baseline, non un Evil. Non è quindi una prova
visiva dell'aspetto attuale delle intro Evil. Dimostra però che il layout
generico mostra soltanto titolo, citazione e CTA; anche
`BossUI.show_intro()` non presenta alcun ritratto o Signature.

I dati sono già distinti: `BossDefinition.get_safe_portrait()` risolve il
ritratto del Piccione Malvagio o l'`evil_portrait` dell'amico, mentre ogni
Signature possiede un `accent_color`. I ritratti Evil sono ancora placeholder
CC0 e `BossSignatureDefinition` non espone un'icona.

## Comportamento atteso

Quando il Boss è un Evil, la intro mostra busto, icona della Signature e tinta
personale. Il Piccione Malvagio continua a usare il suo ritratto esistente e
non mostra uno slot Signature vuoto. La CTA conserva il trattamento attuale e
non cambia colore in base al Boss.

## Criteri di accettazione

- [ ] Una intro Evil mostra il ritratto risolto dal relativo
      `FriendDefinition`.
- [ ] Una intro Evil mostra l'icona della Signature attiva.
- [ ] Nome e almeno un dettaglio della cornice riprendono l'`accent_color`
      della Signature senza compromettere contrasto e leggibilità.
- [ ] Il Piccione Malvagio mostra il ritratto già dichiarato in
      `data/bosses/first_boss.tres` e non presenta un'icona Signature o uno
      spazio vuoto dedicato.
- [ ] La CTA mantiene stile e colore attuali in entrambe le varianti; la tinta
      personale non ne cambia la semantica.
- [ ] Con ritratto, icona o Signature mancanti la intro ricompone gli elementi
      restanti senza buchi, errori di script o texture nulle visibili.
- [ ] `BossSignatureDefinition` espone un campo icona tipizzato e ogni `.tres`
      sotto `data/bosses/signatures/` lo valorizza.
- [ ] Gli otto `evil_portrait` e le otto icone puntano ai segnaposto
      `fake_*.png` elencati in Ambito; i fallback esistenti restano invariati.
- [ ] Titolo e citazione continuano a provenire dai dati del Boss.
- [ ] `RunController` resta l'unica autorità su `BOSS_INTRO`: la UI osserva e
      invia soltanto l'intenzione `AFFRONTA`.
- [ ] Il pannello resta nella safe area su 16:9, 20:9 e 4:3.

## Ambito

- `scripts/ui/boss_ui.gd`, `scenes/ui/boss_ui.tscn`.
- `scripts/bosses/boss_signature_definition.gd`, per il campo icona.
- `data/bosses/signatures/*.tres`, per valorizzare l'icona.
- `data/friends/*.tres`, solo per il campo `evil_portrait`.
- Segnaposto da creare in questa card:
  - `assets/art/characters/evil/generated/fake_evil_<id>.png` per gli otto
    personaggi;
  - `assets/art/icons/signatures/generated/fake_signature_<signature_id>.png`
    per le otto Signature.

Non toccare:

- logica, effetto, telegraph, danno e raggio delle Signature;
- `BossSignatureRegistry` e registry degli effetti;
- soglie e ricorrenza Boss gestite da `GameDirector`;
- HUD vita Boss, oggetto di PS-033;
- asset definitivo, oggetto di PS-052.

## Verifica

- Smoke: `tests/unit/test_ps051_boss_intro_identity.gd` → marker
  `BOSS_INTRO_IDENTITY_SMOKE_OK` — verifica variante baseline senza Signature,
  variante Evil con ritratto/icona/accento, CTA invariata e fallback con dati
  mancanti.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: intro Piccione Malvagio e intro di almeno un Evil
- [ ] Controllo percettivo richiesto: sì, solo dopo che PS-052 ha sostituito i
      segnaposto con gli asset definitivi

## Decisioni

- **2026-08-31 — La cattura mostra il baseline.** Non viene più usata come
  prova che un Evil sia generico; la mancanza del layout identitario è
  confermata dal codice corrente.
- **2026-08-31 — I fake restano il contratto di passaggio.** PS-051 valida UI,
  fallback e ingombri; PS-052 sostituisce i sedici file.
- **2026-08-31 — Nessun colore CTA prescritto.** La nuova cattura mostra il
  trattamento viola corrente; la card lo preserva invece di imporre l'arancio
  dedotto dagli screenshot obsoleti.

## Documenti sincronizzati

- [ ] `docs/enemies-bosses.md`: anatomia delle due varianti di Boss intro.
- [ ] `docs/visual-audio-identity.md`: stato dei ritratti Evil.

## Note

I fake sono dichiaratamente temporanei e non vengono registrati come asset
finali; PS-052 completa manifest e provenienza.
