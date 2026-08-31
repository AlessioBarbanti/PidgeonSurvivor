---
id: PS-054
titolo: Adattare il selettore personaggi al 20:9
tipo: ux
area: ui
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-08-31
aggiornato: 2026-08-31
---

# PS-054 — Adattare il selettore personaggi al 20:9

## Contesto

Le otto nuove catture, da
[03_character_select.png](../../../exports/ui-screenshots/pixel9-20x9/03_character_select.png)
a
[03b_character_08_marghe.png](../../../exports/ui-screenshots/pixel9-20x9/03b_character_08_marghe.png),
mostrano che descrizioni, ruoli e abilità sono già leggibili e non vengono
troncati. Ridurli a una riga, come previsto dalla prima versione della card,
eliminerebbe informazioni utili senza risolvere il problema reale.

Sul Pixel 9 è l'intera composizione a essere sottodimensionata: il selettore
occupa una porzione centrale ridotta, lascia molto spazio laterale e rende le
anteprime adiacenti troppo piccole. Il personaggio selezionato è leggibile, ma
non ha ancora la presenza promessa dalla welcome.

## Comportamento atteso

Il selettore sfrutta meglio la larghezza 20:9: ritratto centrale, anteprime
laterali e pannelli informativi crescono come un unico sistema, mantenendo le
descrizioni complete e senza trasformare la schermata in una scheda tecnica a
tutta larghezza.

## Criteri di accettazione

- [ ] Sul Pixel 9 20:9 la composizione usa una porzione sensibilmente maggiore
      della safe area orizzontale rispetto alla cattura attuale, restando
      centrata e bilanciata.
- [ ] Il ritratto selezionato e la relativa cornice hanno maggiore presenza
      senza deformare o ricampionare male l'asset.
- [ ] Le anteprime laterali restano chiaramente visibili e suggeriscono la
      direzione del carosello; non diventano miniature decorative quasi
      indistinguibili.
- [ ] Nome, ruolo, passiva e abilità attiva mantengono titoli e descrizioni
      complete già approvate.
- [ ] Icone, titoli e testi dei due pannelli informativi restano associati
      correttamente e costruiscono una gerarchia leggibile.
- [ ] Nessuno degli otto personaggi produce troncamenti, sovrapposizioni o
      riduzioni di font illeggibili; il gate usa tutte le otto catture.
- [ ] Numero di card visibili, card centrale, navigazione avanti/indietro e
      comportamento circolare del carosello restano invariati.
- [ ] Focus, conferma, touch e Back restano quelli attuali; Back torna alla
      welcome senza alterare la run.
- [ ] In 16:9 e 4:3 il layout si ricompone nella safe area senza tagli e senza
      assumere la larghezza 20:9.
- [ ] Palette, cornici e backdrop stabilizzati da PS-015 e PS-020 vengono
      preservati.
- [ ] Nessun nuovo asset grafico o campo `safe_*` di copia breve viene
      introdotto da questa card.

## Ambito

- `scenes/ui/character_select_overlay.tscn`, sottoalberi del pannello
  informativo e del carosello.
- `scripts/ui/character_select_overlay.gd`, solo per adattamento responsivo e
  riferimenti ai nodi ristrutturati.
- Costanti di layout e scala del selettore.

Non toccare:

- flusso `welcome → tutorial → selezione → run`;
- `RunController` e avvio della run;
- testi e dati di gameplay dei personaggi;
- asset, backdrop e geometria funzionale del carosello.

## Verifica

- Smoke: `tests/unit/test_ps054_character_select_presence.gd` → marker
  `CHARACTER_SELECT_PRESENCE_SMOKE_OK` — verifica contenimento, dimensioni
  relative, presenza delle anteprime, testo completo e stabilità su 16:9,
  20:9 e 4:3 per tutti gli otto profili.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: scorri gli otto personaggi, confronta anteprime e
      pannelli, torna indietro e conferma una scelta
- [ ] Controllo percettivo richiesto: sì — presenza del cast e uso equilibrato
      della larghezza senza sacrificare le informazioni

## Decisioni

- **2026-08-31 — Il testo non è il problema rilevato.** Le nuove catture
  dimostrano che le descrizioni complete entrano; non vengono abbreviate.
- **2026-08-31 — Si adatta l'intero sistema.** Ingrandire solo il ritratto
  lascerebbe anteprime e pannelli ancora più deboli.
- **2026-08-31 — Priorità portata a media.** Il Pixel 9 è il riferimento fisico
  del progetto e il sottoutilizzo del 20:9 è presente in tutte le otto viste.

## Documenti sincronizzati

- [ ] `docs/ui-ux-flow.md`: comportamento responsivo del selettore.

## Note

Il gate non si chiude con una sola cattura: servono tutti gli otto personaggi,
perché silhouette e lunghezza dei testi cambiano sensibilmente.
