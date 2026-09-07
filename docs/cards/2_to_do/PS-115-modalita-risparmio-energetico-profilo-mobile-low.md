---
id: PS-115
titolo: Aggiungi una Modalità risparmio energetico con profilo mobile_low
tipo: feat
area: piattaforma
stato: BLOCCATO
priorita: media
dipende_da: [PS-113, PS-117]
origine:
creato: 2026-09-07
aggiornato: 2026-09-07
---

# PS-115 — Aggiungi una Modalità risparmio energetico con profilo mobile_low

## Contesto

Esiste un solo profilo `mobile` ([data/performance/mobile_performance_profile.tres](../../../data/performance/mobile_performance_profile.tres)),
selezionato in `movement_slice._resolve_performance_profile()` in base al
solo tipo di piattaforma (`OS.get_name() == "Android"`), non alla capacità
reale del device. Un telefono di fascia bassa eredita lo stesso `target_fps`,
`render_scale` e le stesse soglie di stress di un device più performante,
mentre il proprietario ha osservato scatti, surriscaldamento e consumo
batteria rapido testando su hardware più debole.

## Comportamento atteso

In Impostazioni (welcome screen e overlay di pausa, stesso punto d'accesso
delle altre impostazioni come controlli touch, modalità di fuoco e
accessibilità visiva) compare un toggle "Modalità risparmio energetico".
Lo stato persiste fra sessioni con lo stesso pattern di `ConfigFile` usato da
[scripts/app/touch_control_settings.gd](../../../scripts/app/touch_control_settings.gd).
Quando attivo su Android, `_resolve_performance_profile()` restituisce un
nuovo profilo dati `mobile_low_performance_profile.tres` al posto di
`mobile_performance_profile.tres`, con `target_fps` e `render_scale` più
bassi e soglie di stress ridotte rispetto al profilo mobile standard. Su
Windows il toggle resta visibile per coerenza con le altre impostazioni ma
non cambia profilo: il problema riportato riguarda solo device Android di
fascia bassa. Il toggle è disattivo di default: chi non lo tocca non vede
alcun cambiamento.

## Criteri di accettazione

- [ ] Esiste un nuovo file dati `mobile_low_performance_profile.tres` con
      `target_fps` e/o `render_scale` inferiori a
      `mobile_performance_profile.tres`, valido (`is_valid() == true`).
- [ ] Un toggle "Modalità risparmio energetico" è raggiungibile da welcome e
      da pausa, con lo stesso stile delle altre voci di impostazioni
      esistenti.
- [ ] Lo stato del toggle persiste fra riavvii del gioco.
- [ ] Con il toggle attivo su Android, `_resolve_performance_profile()`
      restituisce `mobile_low_performance_profile` invece di
      `mobile_performance_profile`; con il toggle disattivato, o su Windows,
      il comportamento resta quello attuale indipendentemente dal toggle.
- [ ] Un test GUT copre entrambi gli stati del toggle e la persistenza fra
      ricariche.

## Ambito

- File: [scripts/game/movement_slice.gd](../../../scripts/game/movement_slice.gd)
  (`_resolve_performance_profile`), nuovo script di impostazioni sul modello
  di `touch_control_settings.gd`, nuova voce UI in welcome e pausa, nuovo
  `data/performance/mobile_low_performance_profile.tres`.
- Non toccare: `mobile_performance_profile.tres` e
  `windows_performance_profile.tres` esistenti (restano i default invariati),
  `RunController`, il bilanciamento di gameplay — le soglie di stress
  influenzano solo VFX/soglie di presentazione (`max_transient_feedback`),
  mai la densità nemica reale governata da `GameDirector`.

## Verifica

- Smoke: `tests/unit/test_ps115_low_power_toggle.gd` → marker `PS115_LOW_POWER_TOGGLE_OK`
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows (il toggle non deve rompere nulla anche se su Windows
      non cambia profilo)
- [ ] Validazione statica APK
- [ ] Runtime fisico su device Android di fascia bassa: **gate primario di
      questa card**. Attivare il toggle sul device reale e confermare
      percettivamente meno scatti/calore rispetto al profilo standard. Se il
      device di fascia bassa non è disponibile in sessione, il gate resta
      aperto e va dichiarato esplicitamente, non assunto.
- [ ] Controllo percettivo richiesto: sì

## Decisioni

- **2026-09-07 — Toggle manuale, non rilevamento automatico.** Il
  proprietario ha scelto un'opzione esplicita in Impostazioni invece di
  un'euristica automatica sul device: comportamento prevedibile e testabile,
  a costo di richiedere un'azione esplicita da chi gioca.
- **Dipendenze:** questa card dipende da [PS-113](../4_to_test/PS-113-cabla-cap-fps-performance-profile.md)
  (`IN VERIFICA`, prerequisito soddisfatto) e da
  [PS-117](../2_to_do/PS-117-subviewport-mondo-di-gioco-per-render-scale.md)
  perché senza quei due meccanismi il profilo `mobile_low` avrebbe come unica
  leva reale le soglie di stress (`max_transient_feedback`), insufficiente da
  sola per un effetto percepibile su calore e batteria.
- **2026-09-07 — Dipendenza aggiornata da PS-114 a PS-117.** PS-114
  (cablaggio diretto di `render_scale`) si è rivelata insufficiente ed è
  stata sostituita da PS-117 (mondo di gioco in `SubViewport` dedicato), che
  ne eredita lo scopo.

## Documenti sincronizzati

- [ ] [docs/ui-ux-flow.md](../../../docs/ui-ux-flow.md): nuova voce in
      Impostazioni.
- [ ] [docs/visual-audio-identity.md](../../../docs/visual-audio-identity.md):
      terzo profilo dati `PerformanceProfile`.

## Note

Il nome definitivo del toggle ("Modalità risparmio energetico" è un
placeholder di lavoro) va confermato in fase di risoluzione se il
proprietario ne preferisce uno diverso in italiano corrente (vedi
`avoid-jargon-in-player-facing-text` nelle convenzioni di testo).
