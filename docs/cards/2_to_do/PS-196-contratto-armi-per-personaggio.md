---
id: PS-196
titolo: Fissa il contratto delle armi per personaggio
tipo: chore
area: gameplay
stato: PRONTO
priorita: alta
dipende_da: []
origine:
creato: 2026-09-18
aggiornato: 2026-09-18
---

# PS-196 — Fissa il contratto delle armi per personaggio

## Contesto

Il proprietario segnala che un personaggio che spara sempre allo stesso modo è
noioso e vuole armi specifiche per personaggio, coerenti con l'ambientazione,
ben differenziate fra loro e **tutte compatibili con le Specialità di Barb**.

Oggi esiste un solo `WeaponController`
([scripts/combat/weapon_controller.gd](../../../scripts/combat/weapon_controller.gd))
con un solo `WeaponProfile`
([data/weapons/default_weapon_profile.tres](../../../data/weapons/default_weapon_profile.tres),
cablato come `ExtResource` fisso in
[scenes/actors/player.tscn:5,79-80](../../../scenes/actors/player.tscn)) e un
solo `Projectile`, condivisi da tutti e otto i personaggi.
`FriendDefinition` differenzia solo moltiplicatori di statistiche
(`base_fire_rate_multiplier`, `base_damage_multiplier`,
`base_critical_chance_bonus`), mai comportamento d'arma.

Il vincolo decisivo emerge dalle Specialità: **5 delle 8 attive presuppongono
un proiettile che viaggia** — Arrosticini (pierce,
[upgrade_effect_registry.gd:476-487](../../../scripts/progression/upgrade_effect_registry.gd)),
Tagliata (multishot, :488-503), Fiorentina (death burst, :504-515), Salsiccia
(catena, :456-471), Alette (cadenza + dispersione di mira, :443-455). Solo
Costine, Hamburger e Pancetta sono indipendenti dall'arma. Tutte e 5 passano
per l'unico canale `WeaponController.set_projectile_shape_modifiers()` /
`set_projectile_upgrade_modifiers()`.

Armi strutturalmente diverse (raggio continuo, aura, melee puro) romperebbero
quelle 5 Specialità per i personaggi che le ricevono, richiedendo di definire
8 armi × 5 Specialità = 40 caselle semantiche, più la generalizzazione di
`RunContractValidator`
([run_contract_validator.gd:604-637](../../../scripts/app/run_contract_validator.gd))
e della formula di tetto aritmetico
`WeaponController.calculate_full_build_kill_rate_per_second()` (righe
686-712), che assumono un singolo proiettile lineare con assi scalari.

Questa card non implementa: fissa il contratto che vincola tutte le card
successive della famiglia "armi".

## Comportamento atteso

I documenti durevoli dichiarano un contratto "arma per personaggio"
sufficiente a scrivere e verificare ogni card successiva senza riaprire le
stesse decisioni: che cosa può variare fra un'arma e l'altra, che cosa deve
restare invariante, in quale registro tematico vivono i nomi, e chi possiede
i valori base rispetto ai moltiplicatori di personaggio.

## Criteri di accettazione

- [ ] È dichiarato l'**invariante di compatibilità**: ogni arma del Player
      emette `Projectile`, così ogni Specialità di Barb resta valida per
      costruzione senza casi speciali per arma.
- [ ] Sono dichiarati i **cinque assi di differenziazione** ammessi
      (traiettoria; geometria d'emissione; ritmo; corpo del proiettile —
      raggio/velocità/portata; comportamento a fine vita) e la regola minima
      di quanti assi devono distinguere due armi qualsiasi.
- [ ] È dichiarato il **registro tematico**: le armi vivono nel registro
      utensile/brace/condimento e mai in quello della carne, riservato alle
      Specialità di Barb — coerente con
      [docs/powerup-catalog.md:8-29](../powerup-catalog.md),
      [docs/visual-audio-identity.md:14-18](../visual-audio-identity.md) e col
      test che lo impone
      (`tests/unit/test_ps089_ordinary_catalog_meat_audit.gd:19-23`,
      `FORBIDDEN_MEAT_WORDS`).
- [ ] È dichiarata la **proprietà dei valori**: l'arma possiede i valori base
      di cadenza/danno/forma, il personaggio continua a possedere solo i
      moltiplicatori di `FriendDefinition`, senza che lo stesso scarto venga
      contato due volte.
- [ ] È dichiarata la **reinterpretazione di Alette** (`beer_signature`) per
      armi prive di direzione di mira: la dispersione va reinterpretata su un
      parametro equivalente dell'arma, mai ignorata silenziosamente.
- [ ] È dichiarato che l'arma è **contenuto nominato e visibile** (nome +
      icona) e dove compare (selettore personaggi, pannello build in pausa di
      [PS-164](../4_to_test/PS-164-mostra-build-corrente-in-pausa.md)).
- [ ] È dichiarato che l'arma è **fissa per personaggio**, parte della sua
      identità: sbloccare o scegliere armi alternative è esplicitamente fuori
      contratto e resta materia di un'eventuale card futura.
- [ ] Nessuna modifica al runtime in questa card.

## Ambito

- `docs/prd.md`: contratto dell'attacco del Player e rapporto con le
  Specialità.
- `docs/characters.md`: l'arma entra nell'identità dichiarata del cast.
- `docs/powerup-catalog.md` e `docs/visual-audio-identity.md`: collocazione
  delle armi nel registro utensile/brace.
- Non toccare:
  - qualunque file sotto `scripts/`, `scenes/` o `data/` — card di soli
    contratti;
  - la separazione dei due registri di PS-089 (le armi si aggiungono al
    registro utensile, non lo ridefiniscono);
  - il contratto delle Specialità di Barb (PS-012): le armi si adattano a
    esso, non viceversa.

## Verifica

- Nessuno smoke: la card non cambia il runtime. La verifica è la coerenza fra
  i documenti sincronizzati e l'assenza di modifiche a `scripts/`/`data/`.

## Gate manuali

- [ ] Runtime Windows — non pertinente
- [ ] Validazione statica APK — non pertinente
- [ ] Runtime fisico Pixel 9 — non pertinente
- [ ] Controllo percettivo richiesto: no

## Decisioni

- **2026-09-18 — Scelta l'architettura "stesso atomo, emissione diversa"**
  invece di armi strutturalmente eterogenee. Motivazione: è l'unica che
  soddisfa per costruzione il requisito del proprietario ("tutte le armi si
  interfacciano alle Specialità di Barb"), mantiene valide le 5 Specialità
  legate al proiettile senza 40 casi speciali, e lascia intatti
  `RunContractValidator` e il tetto di kill-rate usati oggi dai test. È anche
  il modello del genere: nel riferimento Vampire Survivors la gran parte
  delle armi sono proiettili con emissione diversa, non motori separati.
- **2026-09-18 — Armi nominate e visibili** (nome + icona nel selettore e nel
  pannello build), confermato dal proprietario: la differenziazione deve
  essere leggibile prima di giocare, non solo scoperta in partita.
- **2026-09-18 — Arma fissa per personaggio**, non selezionabile: è identità,
  non equipaggiamento.
- **Precedente noto**: in
  [PS-085](../4_to_test/PS-085-introduci-sparo-manuale-con-secondo-joystick.md)
  il proprietario aveva scartato la scelta *per personaggio* della modalità di
  sparo, preferendo un'impostazione condivisa. Domanda diversa (lì la sorgente
  della mira, qui la forma del colpo), citata perché non venga riletta come
  contraddizione.

## Documenti sincronizzati

- [ ] `docs/prd.md`
- [ ] `docs/characters.md`
- [ ] `docs/powerup-catalog.md`
- [ ] `docs/visual-audio-identity.md`

## Note

Primo anello della famiglia "armi per personaggio": la seguono
[PS-197](./PS-197-impianto-arma-per-personaggio-neutro.md) (impianto neutro) e
[PS-198](../1_idea/PS-198-armi-pilota-primo-set.md) (armi pilota). Le card
`art` per le icone e la card di integrazione UI si aprono solo quando le armi
pilota hanno un nome approvato, per non fissare criteri su contenuto che non
esiste ancora.
