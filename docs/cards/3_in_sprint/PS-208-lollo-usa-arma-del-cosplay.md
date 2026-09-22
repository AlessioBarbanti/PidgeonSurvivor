---
id: PS-208
titolo: Fai usare a Lollo l'arma del personaggio che sta copiando
tipo: feat
area: gameplay
stato: IN CORSO
priorita: media
dipende_da: [PS-200, PS-202]
origine:
creato: 2026-09-22
aggiornato: 2026-09-22
---

# PS-208 — Fai usare a Lollo l'arma del personaggio che sta copiando

## Contesto

L'arma di Lollo, l'Attizzatoio (PS-200), non ha una particolarità che si
capisca in partita; PS-207 aveva provato a dargliela facendola arroventare.
Il proprietario ha proposto un'idea più forte e più legata al personaggio:
Cosplay Casuale mostra già sul pulsante l'abilità di un altro personaggio che
Lollo sta per usare. Il travestimento può essere completo: Lollo usa anche
l'**arma** di quel personaggio.

## Comportamento atteso

L'arma di Lollo è sempre quella del personaggio la cui abilità è sul pulsante
di Cosplay Casuale, sia mentre l'abilità si ricarica sia quando è pronta.
Quando Lollo lancia l'abilità e Cosplay ne estrae un'altra, l'arma cambia
insieme all'icona del pulsante. Vale per tutte e sette le armi degli altri
personaggi, compreso il Coperchio di Magno, che è in mischia. Il cambio si
riconosce dal colpo stesso: niente indicazioni nuove nell'HUD. L'Attizzatoio
resta nei dati solo come ripiego, se Cosplay non ha nessun candidato.

## Criteri di accettazione

- [ ] Con Lollo equipaggiato, l'arma è quella del personaggio che possiede
      l'abilità sul pulsante di Cosplay, già prima del primo colpo.
- [ ] Dopo ogni lancio di Cosplay, quando l'abilità sul pulsante cambia,
      cambia anche l'arma nello stesso momento.
- [ ] Nel corso di più estrazioni compaiono tutte e sette le armi degli altri
      personaggi, Coperchio compreso.
- [ ] Il cambio d'arma conserva i moltiplicatori di Lollo (scarti e passiva)
      e i potenziamenti presi nella run, comprese le Specialità di Barb.
- [ ] Restart e cambio personaggio riallineano l'arma: gli altri sette
      personaggi usano sempre la propria arma, e Lollo quella del nuovo
      costume anche quando l'estrazione ripete quella di prima.
- [ ] Il `RunContractValidator` accetta l'arma del costume per Lollo e
      continua a pretendere l'arma dichiarata per tutti gli altri.
- [ ] Senza candidati per Cosplay, Lollo usa l'Attizzatoio.

## Ambito

- `scripts/content/friend_registry.gd`: da personaggio e abilità estratta
  all'arma da usare.
- `scripts/game/movement_slice.gd`: allinea l'arma all'equipaggiamento e al
  segnale `pending_cosplay_changed`.
- `scripts/app/run_contract_validator.gd`: arma attesa per Lollo.
- `docs/characters.md`: sezione Lollo, arma.
- Non toccare: `AbilityEffectRegistry` (estrazione del Cosplay),
  `WeaponController` (`set_weapon_definition()` è già il punto unico del
  cambio d'arma), `UpgradeEffectRegistry`, i dati delle armi, `RunController`.

## Verifica

- Test: `tests/unit/test_ps208_lollo_cosplay_weapon.gd` → marker
  `PS208_LOLLO_COSPLAY_WEAPON_OK`.
- Regressioni: B17a, B44, PS-197/PS-200 (armi), validatore della run;
  aggiornare `tools/milestone-test-map.json`.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows (Lollo: più lanci di Cosplay, armi diverse, Coperchio)
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: stessa partita con Lollo)
- [ ] Controllo percettivo richiesto: sì, sensazione di gioco confermata dal
      proprietario (si capisce che l'arma è cambiata?)

## Decisioni

- **2026-09-22 — Sempre l'arma del costume.** Scelta del proprietario fra
  "Attizzatoio mentre l'abilità si ricarica, costume completo quando è
  pronta" e "sempre l'arma del costume". L'Attizzatoio resta solo come
  ripiego nei dati.
- **2026-09-22 — Tutte e sette le armi, mischia compresa.** Con Magno Lollo
  diventa un personaggio da mischia: più caos, in linea col ruolo.
- **2026-09-22 — Nessun segnale nuovo nell'HUD.** Il colpo diverso e l'icona
  sul pulsante bastano.
- **Sostituisce:** PS-207 (Attizzatoio che si arroventa), ritirata perché
  Lollo non usa più l'Attizzatoio in partita.

## Documenti sincronizzati

- [ ] `docs/characters.md` — sezione Lollo, arma.
- [ ] `tools/milestone-test-map.json` — regressioni del nuovo test.

## Note

- Bilanciamento: tutte le armi stanno entro il 10% di kill-rate fra loro
  (PS-200), quindi il cambio non rende Lollo più forte o più debole in media.
  Resta da osservare la continuità: un colpo molto lento (Paletta, 1 colpo/s)
  seguito da uno rapido (Spiedo) cambia molto il ritmo da un'estrazione
  all'altra.
