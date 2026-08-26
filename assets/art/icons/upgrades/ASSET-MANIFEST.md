# Manifest asset — Icone potenziamenti

## B26/B27 — Forchettone da Braciere e refresh carte

- Data integrazione: 2026-08-26.
- Origine: dieci master PNG RGBA forniti dal proprietario e già generati manualmente per il progetto. Il repository non inventa prompt, generatore, autore o licenza di terzi non consegnati; i master sono trattati come asset del progetto per l'uso in gioco.
- Trasformazione: `tools/process-upgrade-icon.ps1`, bounds alpha con soglia `8`, padding quadrato `12` e riduzione nearest-neighbor a `128×128` RGBA.
- Runtime: soltanto i derivati in `generated/` sono referenziati dalle `UpgradeDefinition`. `hd/.gdignore` e i tre preset export mantengono i master fuori da import, EXE, APK e AAB.

| Carta | Master HD escluso | Derivato runtime | SHA-256 master | SHA-256 runtime |
|---|---|---|---|---|
| Dai che si fredda! | `hd/upgrade_move_speed.png` (`1254×1254`) | `generated/move_speed.png` (`128×128`) | `325AD2FC344095D85EC84A4E13CC889EF38CD7AE9E881C01DBB7A2DBB9086737` | `D1BECE51AB9514672327DE6D4352D41003BF7A30C71080AA4B5313B9F3E30190` |
| Ritmo Serrato | `hd/upgrade_fire_rate.png` (`1536×1024`) | `generated/fire_rate.png` (`128×128`) | `5537E4537F0D6B36589AC47A4E5A1FB164EA2D2552EE0AB6D751A163A7B76260` | `BB3059B45D352F3896B89BCEEE0E97558FF289D7EB026AFE496378F722EE01F9` |
| Campo Ampio | `hd/upgrade_pickup_range.png` (`1536×1024`) | `generated/pickup_range.png` (`128×128`) | `B4ED225EE1E56AEF74D4EA33C831F16246866088FD91D302F4D15F076EED6AA6` | `C38CC5C73C58D986B28B1EB51E9AC92837F8A991322A658F6DF1D70EEDB4CB6D` |
| L'Ansia | `hd/upgrade_anxiety.png` (`1428×1101`) | `generated/anxiety.png` (`128×128`) | `B8143AF622A680791FCA8E5095C507315EF479702B37F4C211905ADDA689B74E` | `38869D6FF0BB7BE8035A22872DEED737FFB089B19A38B2CAE5E5E7ED815DBE95` |
| Birra | `hd/upgrade_beer.png` (`1536×1024`) | `generated/beer.png` (`128×128`) | `751D5AFF54F89D5B3A8021787EE58C2BB630560FADDD478022058A2F0CD00E47` | `5CF2536EADAD28C086308803858EC2FF2242DF0ADD6AE9BCE8EB4453A0D1DA85` |
| Ritardo Cronico | `hd/upgrade_chronic_delay.png` (`1536×1024`) | `generated/chronic_delay.png` (`128×128`) | `B5C0731E8A9BA2A16DEC42FE4DB58A234909504D1C3602944763C2F79F5DDB8E` | `B7263852BC77EFE3668C681DB0C99A1C5793EB5D02EF44E38925E35E65AEA1D1` |
| Forchettone da Braciere | `hd/upgrade_damage_meat_fork.png` (`1254×1254`) | `generated/meat_fork_damage.png` (`128×128`) | `AEA17B6EE93CE03DD2EC6430F08DCED45D3FA94AFF04923FC71404E75C34FD85` | `4EEE3E9990CDF5C432D03C382808036134AA69810F5A87B5BEA41A6418F15C8D` |
| Gossip | `hd/upgrade_gossip.png` (`1254×1254`) | `generated/gossip.png` (`128×128`) | `AF980C892968B8003977610F39789EE04D66FEB7B91A563A4100F3287C75C8E8` | `F337A087D2375D74D316F0A9E22D96C15353B83B81B0E2EA8E71D063EFED6AB6` |
| Non Ho Tempo Per Questo | `hd/upgrade_no_time.png` (`1536×1024`) | `generated/no_time.png` (`128×128`) | `1D86B7AEE938E13AB63D8F85E5AE9DD2EEB4526A02E88F69241818F0A335BDCF` | `FB27C5405CA2B9CD8C02F86DFF271DE664EEB0D086D34369BE330367E3A00D16` |
| Grigliata estiva | `hd/upgrade_summer_grill.png` (`1536×1024`) | `generated/summer_grill.png` (`128×128`) | `A14F484BA980599CCB75264F99C2334D9C799762CC26DF4DE5D1974EBD5C2139` | `11A7B6AC29E17FE58E50194BDF6D9D78A4CAF41BAEF59285145124E5D547560D` |
