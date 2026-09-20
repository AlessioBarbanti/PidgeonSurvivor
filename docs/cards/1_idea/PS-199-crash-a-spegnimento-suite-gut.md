---
id: PS-199
titolo: Crash a spegnimento della suite GUT completa, con report verde
tipo: bug
area: tooling
stato: DA DEFINIRE
priorita: media
dipende_da: []
origine: osservato durante la verifica di PS-189, 2026-09-20
creato: 2026-09-20
aggiornato: 2026-09-20
---

# PS-199 — Crash a spegnimento della suite GUT completa, con report verde

## Contesto

Durante la verifica di [PS-189](../4_to_test/PS-189-lag-residuo-marghe-orda-clone.md)
un tentativo `Release` (`20260920-234650-PS-189`) è uscito con
`-1073741819` (`0xC0000005`, access violation su Windows) **dopo** che GUT
aveva scritto un report completamente verde: 161 script, 507 casi, 26 767
assert, zero fallimenti. Il runner lo classifica correttamente come
fallimento — "Uscita -1073741819 con report GUT verde: il processo e' morto
fuori dai test" — e non lo nasconde dietro l'exit code.

Non riprodotto nei tre `Full`/`Release` successivi sullo stesso albero
(`20260920-235041`, `20260920-235459`, `20260920-235832`), quindi
**intermittente**. In quell'esecuzione i consueti messaggi di oggetti ancora
vivi a fine processo non compaiono: il crash sembra precedere la fase in cui
vengono stampati.

Il processo GUT termina già normalmente con oggetti vivi: PS-178 ha
registrato come preesistenti 11/26/8 RID, 232 istanze ObjectDB, 68 risorse e
pagine `PagedAllocator` ancora in uso. Un processo che esce in quello stato è
un candidato plausibile a un crash occasionale a spegnimento, ma resta
un'ipotesi non verificata.

## Domanda per il proprietario

Vale la pena investirci adesso? Non sporca nessun risultato di gioco: i test
sono verdi e le diagnosi restano valide. Costa però un `Release` rosso ogni
tanto, e soprattutto costa fiducia, perché è esattamente la forma di
fallimento che il contratto di verifica chiede di non ignorare.

## Comportamento atteso

La suite completa esce con codice 0 quando il report GUT è verde, in modo
ripetibile. In alternativa, se la causa è un contratto di spegnimento
dell'engine fuori dal nostro controllo, il runner la distingue da un crash
vero invece di trattarla come fallimento generico.

## Criteri di accettazione

- [ ] Stimata la frequenza reale su un numero dichiarato di esecuzioni della
      stessa suite, sullo stesso albero, senza altri carichi.
- [ ] Attribuita la causa a un componente specifico, oppure dichiarato che
      non è attribuibile con gli strumenti disponibili.
- [ ] Nessuna modifica che nasconda l'uscita anomala: se il runner cambia
      comportamento, distingue il caso riconosciuto da un crash sconosciuto.

## Ambito

- `tools/lib/gut-batch-status.ps1` e `tools/run-milestone-checks.ps1`.
- Statiche che trattengono nodi oltre la fine di una fixture, se la
  diagnosi le indica.
- Non rientra qui il costo per frame della separazione: è PS-189.

## Verifica

- Ripetere `-Profile Full -NoCache` un numero dichiarato di volte e contare
  le uscite anomale, prima e dopo qualunque ipotesi di correzione.
- Confrontare con la stessa suite su un commit precedente a PS-189, per
  capire se la frequenza è cambiata.

## Note

Aperta da PS-189 per non allargare quella card. Nessuna implementazione
avviata.
