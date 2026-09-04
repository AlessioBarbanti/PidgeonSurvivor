# Report: tempo dei test GUT eseguiti singolarmente

Diagnostica una tantum per capire perché la suite `tests/unit/` (99 test)
impiega così a lungo. Non è un documento di stato del progetto: è la
fotografia di un'unica esecuzione, eseguita il 2026-09-04.

## Metodo

Ogni `test_*.gd` è stato lanciato in un **processo Godot separato** (uno alla
volta, in sequenza), invece che nel singolo processo batch usato da
`tools/run-milestone-checks.ps1`:

```powershell
godot_console --headless --path . --resolution 1280x720 `
  -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/<file>.gd -gexit `
  -gjunit_xml_file=<log>
```

Un test che avesse superato **5 minuti** sarebbe stato segnato `5min+` e
interrotto (`taskkill /T /F` sull'intero albero di processo). Nessun test ha
raggiunto la soglia in questa esecuzione.

## Riepilogo

| Metrica | Valore |
|---|---|
| Test eseguiti | 99 |
| Tempo totale (somma dei singoli processi) | 2813,7 s (~46,9 min) |
| Media per test | 28,4 s |
| Minimo osservato | 7,1 s |
| Massimo osservato | 233,5 s (`test_ps006_evil_signature_abilities`) |
| Test oltre i 5 min | 0 |
| Test falliti (`FAIL`) | 5 |

Il minimo osservato (~7,1 s, sui test più semplici come
`test_ability_selection_icon_scale` o `test_ps068_friend_portrait_assets`) è
il pavimento di avvio/spegnimento di un processo Godot vuoto: con 99 processi
separati, solo quel pavimento vale circa 99 × 7,1 s ≈ 703 s (~11,7 min) sui
2813,7 s totali. Il resto (~35 min) è tempo speso dentro i test stessi o in
overhead che il pavimento minimo non cattura (caricamento scene, viewport
1280×720, editor cache).

Cinque test durano da soli oltre 100 s ciascuno
(`test_ps006_evil_signature_abilities`, `test_ps008_wave_events`,
`test_ps003_zat_delayed_healing`, `test_ps004_zat_thunder_charge`) o vicino
(`test_ps079_state_tell_particles`, 67,7 s): insieme pesano ~705 s, un quarto
del totale.

I 5 `FAIL` (`test_b13_signature_upgrades`, `test_b18b_visual_identity`,
`test_b18r_visual_timing`, `test_b27_upgrade_icon_refresh`,
`test_b54_tutorial_flow`) sono un sottoprodotto di questa esecuzione, non
l'oggetto della misurazione: sono fallimenti di asserzione (`exit 1`), non
timeout, e vanno verificati a parte — non è detto siano legati alla causa
della lentezza.

## Tabella completa (ordinata per durata decrescente)

| Test | Secondi | Esito |
|---|---:|---|
| `test_ps006_evil_signature_abilities` | 233.5 | PASS |
| `test_ps008_wave_events` | 150.4 | PASS |
| `test_ps003_zat_delayed_healing` | 127.0 | PASS |
| `test_ps004_zat_thunder_charge` | 126.9 | PASS |
| `test_ps079_state_tell_particles` | 67.7 | PASS |
| `test_b53_boss_horde_pause` | 55.7 | PASS |
| `test_b44_state_tells` | 55.4 | PASS |
| `test_b45_role_identity` | 55.3 | PASS |
| `test_b26_damage_upgrade` | 50.6 | PASS |
| `test_ps053_run_summary` | 45.7 | PASS |
| `test_ps051_boss_intro_identity` | 44.9 | PASS |
| `test_ps046_level_up_modal_isolation` | 44.5 | PASS |
| `test_ps073_boss_dedicated_music` | 44.0 | PASS |
| `test_b18i_xp_arena_confinement` | 43.6 | PASS |
| `test_ps072_bea_dodge_audio` | 43.5 | PASS |
| `test_ps040_bea_powerslide_landing_iframe` | 43.4 | PASS |
| `test_ps005_boss_warning` | 32.0 | PASS |
| `test_b22_evil_boss_variants` | 31.9 | PASS |
| `test_b42_measurable_passives` | 31.7 | PASS |
| `test_ps029_state_tell_visibility` | 31.7 | PASS |
| `test_ps024_magno_shockwave_balance` | 31.6 | PASS |
| `test_b30_boss_no_circular_aura` | 31.4 | PASS |
| `test_b12_upgrade_effects` | 27.1 | PASS |
| `test_b54_tutorial_flow` | 26.0 | FAIL (exit 1) |
| `test_b13_signature_upgrades` | 25.0 | FAIL (exit 1) |
| `test_b38_arena_world` | 24.9 | PASS |
| `test_ps069_character_select_bust_portrait` | 24.8 | PASS |
| `test_b18p_touch_control_settings` | 24.5 | PASS |
| `test_b17a_complete_roster_abilities` | 24.2 | PASS |
| `test_b18t_character_carousel` | 24.1 | PASS |
| `test_b11_upgrade_overlay` | 24.0 | PASS |
| `test_b18o_welcome_flow` | 22.4 | PASS |
| `test_b18w_character_select_refinement` | 22.1 | PASS |
| `test_b18q_arena_hud_minimal` | 22.0 | PASS |
| `test_b18b_visual_identity` | 21.9 | FAIL (exit 1) |
| `test_b41_weapon_shapes` | 21.7 | PASS |
| `test_ps012_barb_specialities` | 21.7 | PASS |
| `test_b18j_summer_grill` | 21.7 | PASS |
| `test_ps044_ui_capture_states` | 21.4 | PASS |
| `test_b18r_visual_timing` | 21.4 | FAIL (exit 1) |
| `test_b10_upgrade_service` | 21.1 | PASS |
| `test_b18v_hardening_performance` | 21.1 | PASS |
| `test_b05_combat_slice` | 21.1 | PASS |
| `test_b04_enemy_spawner` | 21.1 | PASS |
| `test_menu_music` | 21.0 | PASS |
| `test_b17_friend_content` | 20.8 | PASS |
| `test_powerup_first_wave` | 20.7 | PASS |
| `test_b33_recurring_boss` | 20.4 | PASS |
| `test_ps045_arena_visual_hierarchy` | 20.3 | PASS |
| `test_b18l_dynamic_joystick` | 20.3 | PASS |
| `test_b18n_pause_change_character` | 20.3 | PASS |
| `test_b24_player_visual_scale` | 20.2 | PASS |
| `test_b06_player_survival` | 20.2 | PASS |
| `test_b47_base_stats` | 20.1 | PASS |
| `test_ps050_welcome_settings_system` | 20.1 | PASS |
| `test_b09_hud` | 20.1 | PASS |
| `test_b06a_platform_lifecycle` | 20.1 | PASS |
| `test_ps025_boss_warning_size` | 20.1 | PASS |
| `test_b07_experience_pickup` | 20.0 | PASS |
| `test_b08_level_progression` | 20.0 | PASS |
| `test_b03_movement_slice` | 20.0 | PASS |
| `test_b18u_cast_sprites` | 20.0 | PASS |
| `test_b39_health_pickup` | 20.0 | PASS |
| `test_b14_game_director` | 20.0 | PASS |
| `test_b15_boss_encounter` | 19.9 | PASS |
| `test_ps027_bea_powerslide_visual_cleanup` | 19.9 | PASS |
| `test_ps026_boss_baseline_display_name` | 19.9 | PASS |
| `test_b09a_active_ability` | 19.9 | PASS |
| `test_b18m_ability_visuals` | 19.8 | PASS |
| `test_b18s_arena_background` | 19.8 | PASS |
| `test_b18_audiovisual_feedback` | 19.8 | PASS |
| `test_ps041_magno_trail_reset_redraw` | 19.8 | PASS |
| `test_b28_horde_density` | 19.8 | PASS |
| `test_b18f_alea_following_spin` | 19.7 | PASS |
| `test_b18g_ability_ranks` | 19.6 | PASS |
| `test_b16_complete_run` | 19.6 | PASS |
| `test_b18c_player_direction_animation` | 19.6 | PASS |
| `test_b18d_bea_powerslide` | 19.6 | PASS |
| `test_b18k_ability_button_cooldown` | 19.5 | PASS |
| `test_b29_background_music` | 19.5 | PASS |
| `test_b27_upgrade_icon_refresh` | 14.8 | FAIL (exit 1) |
| `test_b40_enemy_archetypes` | 9.7 | PASS |
| `test_ps076_enemy_density_rebalance` | 9.4 | PASS |
| `test_ps036_barb_reward_visual_identity` | 9.4 | PASS |
| `test_ps047_upgrade_card_hierarchy` | 9.1 | PASS |
| `test_b37_density_direction` | 8.9 | PASS |
| `test_ps059_upgrade_modal_contrast` | 8.7 | PASS |
| `test_ps007_late_run_pressure` | 8.7 | PASS |
| `test_ps048_tutorial_runtime_fidelity` | 8.7 | PASS |
| `test_ps057_splitter_spawn_physics` | 8.4 | PASS |
| `test_input_subsystem` | 8.2 | PASS |
| `test_upgrade_definition` | 8.1 | PASS |
| `test_app_icon` | 8.1 | PASS |
| `test_b18h_pigeon_enemies` | 8.1 | PASS |
| `test_ps042_bea_powerslide_spark_subordination` | 7.9 | PASS |
| `test_ability_definition` | 7.8 | PASS |
| `test_typography` | 7.4 | PASS |
| `test_ps068_friend_portrait_assets` | 7.1 | PASS |
| `test_ability_selection_icon_scale` | 7.1 | PASS |

## Esito finale: la causa era lo strumento di misura (2026-09-04)

**Le due sezioni precedenti misurano un artefatto, non i test.** La causa vera
della lentezza era `Invoke-CapturedProcess` in
[tools/lib/process-capture.ps1](../tools/lib/process-capture.ps1): drenava
stdout del processo figlio riga per riga da PowerShell, e Godot restava
bloccato in scrittura fra un giro di lettura e l'altro. Stesso file GUT,
stessa macchina, stesso Godot:

| Come si lancia il test | Tempo |
|---|---:|
| Output rediretto su file | **3,7 s** |
| Attraverso la cattura del runner | **55,9 s** |

Correzione: la cattura passa da file temporanei letti in modo incrementale,
mantenendo marker di completamento, timeout, terminazione dell'albero e riga
di avanzamento (contratto verificato da
`tests/tooling/_process_capture_contract.ps1`).

| File | Prima | Dopo |
|---|---:|---:|
| `test_ps006_evil_signature_abilities` | 233,5 s | **6,3 s** |
| `test_ps008_wave_events` | 150,4 s | **5,0 s** |
| `test_b53_boss_horde_pause` | 55,7 s | **3,8 s** |
| `test_b26_damage_upgrade` | 50,6 s | **3,5 s** |

Suite `Full` completa (99 file): da **timeout a 30 minuti senza finire** a
**70,5 s** in un solo processo e **27,0 s** con `-ParallelJobs 6`, con
**100 PASS e 0 FAIL**.

Scala del parallelismo misurata dopo aver tolto anche l'overhead dei job
PowerShell (~1,5 s per shard, pagati in sequenza prima di ogni test):

| `-ParallelJobs` | 1 | 4 | 6 | 8 | 10 | 12 |
|---|---:|---:|---:|---:|---:|---:|
| Tempo | 68,7 s | 36,0 s | **28,1 s** | 33,6 s | 28,7 s | 29,3 s |

Stesso esito in tutte (95 PASS, 5 FAIL). Il guadagno si esaurisce ai core
fisici; il residuo a 6 job è ~10 s di toolchain/project smoke e ~14 s dello
shard più lento, quindi spingere oltre non serve.

Ipotesi scartate lungo la strada, con la misura che le ha chiuse:

- «istanziare la scena di gioco costa ~12 s»: costa **77-140 ms** (sonda con
  timestamp fra i passi);
- «i nodi si accumulano fra i test»: 12 istanze consecutive costano 56-60 ms
  l'una, zero nodi orfani, conteggio albero costante;
- «l'avvio di Godot domina»: **16-20 s per processo**, contro ~2000 s di
  tempo attribuito ai test dal report JUnit;
- «serve `--fixed-fps`»: porta il frame da 14 ms a 0,5 ms ma non cambia il
  tempo della suite (il blocco era in scrittura, non nei frame) e rompe un
  test. Rimosso.

### I cinque test rossi: nessun bug del gioco, cinque test rimasti indietro

Erano rossi da prima di questo lavoro, e con la suite che non finiva in
mezz'ora non c'era modo di accorgersene. Tre cause, tutte «il prodotto è
cambiato apposta, il test no»:

| Test | Causa |
|---|---|
| `test_b13_signature_upgrades`, `test_b18b_visual_identity`, `test_b18r_visual_timing` | PS-076 ha abbassato gli HP dei nemici (uno swarmer ne ha 9): il colpo «non letale» da 10 danni scritto nei test ora uccide, quindi il colpo successivo veniva rifiutato e la vita azzerata faceva misurare il clamp invece del danno. Le fixture ora danno ai nemici di prova una vita propria, slegata dal bilanciamento. |
| `test_b27_upgrade_icon_refresh` | PS-047 ha compattato le carte upgrade e l'icona è passata da 192 a 106 px; il test difendeva ancora il numero vecchio. Ora verifica l'invariante vera: icona quadrata e identica su ogni viewport. |
| `test_b54_tutorial_flow` | PS-049 ha sostituito i placeholder `fake_tutorial_*.png` con le illustrazioni definitive; il test era fermo a PS-048 e cercava i percorsi vecchi. |

### Due test passavano per il motivo sbagliato

La velocità ha smascherato due difetti reali, entrambi corretti:

- `test_b18w_character_select_refinement` misurava il layout **a metà del
  tween** di entrata delle card. Con i frame bloccati a ~3 s l'animazione
  finiva dentro i 2 frame attesi e la misura risultava giusta per caso. Ora
  attende la fine delle transizioni con `wait_for_transitions()`, aggiunto a
  `GutGameplayTest`.
- `test_b18w` e `test_ps069_character_select_bust_portrait` **ereditavano la
  viewport** lasciata dal file eseguito prima nello stesso processo, quindi
  passavano o fallivano a seconda dell'ordine (cambiando il numero di shard
  cambiava l'esito). Ora la fissano esplicitamente.

## Cronaca: parallelizzazione (2026-09-04)

La diagnosi sopra misura il costo per file, non il tempo reale della suite:
il vero collo di bottiglia, confermato facendo girare per davvero il profilo
`Full` (99 file in un solo processo Godot, come fa
`tools/run-milestone-checks.ps1`), è che quasi ogni funzione di test — non
solo file — chiama `instantiate_movement_slice()`, cioè istanzia l'intera
scena di gioco di produzione da zero. Quel costo non si ammortizza tra un
test e l'altro nello stesso processo: il batch sequenziale è andato in
**timeout dopo 30 minuti avendo completato solo 77/99 file** (media ~23s a
file anche condividendo un solo processo). Sommando la durata dei singoli
shard della corsa parallela sotto, il lavoro Godot totale reale è ~36 minuti:
la cifra di 46,9 minuti misurata sopra (99 processi separati) non era quindi
lontana dal vero, l'overhead di avvio non era la causa dominante.

Intervento: `tools/run-milestone-checks.ps1` ha ora un flag `-ParallelJobs
<N>` che divide i file GUT di un batch fra N processi Godot concorrenti
(`Start-Job`, isolamento di `user://` per shard via `APPDATA` — questa build
di Godot non ha `--user-data-dir`). Nessun test è stato tagliato, riscritto o
reso più leggero: stessa scena reale, stesse asserzioni, solo eseguite in
parallelo invece che in coda.

| Metrica | Sequenziale (1 processo) | Parallelo (`-ParallelJobs 6`) |
|---|---|---|
| Esito | TIMEOUT a 30 min, 77/99 file | Completo, 94 PASS / 5 FAIL |
| Tempo totale | non completato (proiezione ~36-40 min) | **~7 min 52s** (shard più lento) |
| File falliti | — (non arrivato a coprirli tutti) | `test_b13_signature_upgrades`, `test_b18b_visual_identity`, `test_b18r_visual_timing`, `test_b27_upgrade_icon_refresh`, `test_b54_tutorial_flow` |

I 5 `FAIL` sono identici a quelli già notati nella prima diagnosi (stesso
sottoprodotto, non l'oggetto di questa misura): la parallelizzazione non ha
introdotto né nascosto fallimenti, li ha solo fatti emergere ~5 volte più in
fretta.

Distribuzione per shard (round-robin, non pesata sul costo noto dei file —
margine di miglioramento futuro se servisse spremere oltre):

| Shard | Durata |
|---|---:|
| 4 | 7m 52s |
| 2 | 7m 03s |
| 0 | 6m 51s |
| 5 | 5m 21s |
| 3 | 5m 04s |
| 1 | 3m 49s |

Uso: `docs/verification-workflow.md`, sezione "Esecuzione parallela".

## Dove sono i log grezzi

Output completo per script (stdout/stderr Godot) e report JUnit per test in
`test-timing-logs/` sotto lo scratchpad di sessione — non nel repository,
locali e rigenerabili rilanciando la stessa misurazione.
