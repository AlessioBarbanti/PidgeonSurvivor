# Manifest asset — Ritratti Evil PS-052

## Produzione art-only del 1 settembre 2026

Gli otto ritratti definitivi sono stati prodotti in anticipo rispetto
all'integrazione prevista da PS-052. I file esistono come master HD e derivati
runtime, ma **non sono referenziati** da `data/friends/*.tres`, scene o script.
PS-051 e PS-052 mantengono stato, fallback e criteri correnti; l'accettazione
percettiva del proprietario resta aperta.

- Origine: OpenAI ImageGen built-in, a partire dalla direzione visuale del cast
  del progetto IL GIOCO.
- Autore: progetto IL GIOCO con assistenza OpenAI ImageGen.
- Licenza: Licenza del progetto.
- Riferimenti ispezionati: i ritratti `players/carousel/*.png` e la direzione
  visuale in `docs/characters.md`.
- Input ImageGen effettivi: i ritratti carosello di Alea, Aleo, Bea e Lollo sono
  stati usati come edit target per identità, costume e linguaggio pixel-art. Per
  Magno, Marghe, Migi e Zat la generazione è stata guidata dal brief testuale;
  i fratelli visivi sono stati studiati ma non allegati come input.

### Prompt e grammatica condivisa

Prompt comune normalizzato: ritratto quadrato da Boss intro, busto centrale a
tre quarti, pixel-art arcade rifinita con outline prugna scuro, cluster leggibili
e margine sicuro; preservare acconciatura, corporatura, colori dell'abito e
accessori del personaggio; applicare una sola grammatica Evil composta da fumo
prugna controllato, occhio magenta-viola luminoso, poche crepe energetiche e rim
light personale; sfondo realmente trasparente; nessun testo, cornice, logo,
watermark, gore, personaggio aggiuntivo, scenario o trasformazione in demone o
volatile generico.

| ID | Specifica del prompt |
|---|---|
| `evil_alea` | Ballerina classica bionda, costume avorio-oro e ornamento preservati; posa composta e minacciosa, accento magenta. |
| `evil_aleo` | Termotecnico robusto con capelli castani, barba ramata, occhiali, tuta nera, manometri e tubi; accento ciano-rame. |
| `evil_bea` | Pattinatrice agile con lunghi ricci scuri, occhiali, fascia e giacca sportiva viola; sorriso predatorio e accento arancio caldo. |
| `evil_lollo` | Cosplayer iperattivo con capelli scuri, goggles ciano, sciarpa e tuta retrofuturista blu-gialla originale; accento magenta elettrico. |
| `evil_magno` | Uomo molto largo e muscoloso, capelli lunghi e barba, canotta nera con emblema bovino dorato; posa pesante e accento ambra tellurico. |
| `evil_marghe` | Donna morbida con capelli neri molto lunghi, occhiali, outfit reggaeton viola-magenta e oro; rotazione ritmica e accento ciano clone. |
| `evil_migi` | Donna calma con capelli neri raccolti, occhiali, tuta protettiva teal e guscio segmentato; minaccia controllata e accento menta. |
| `evil_zat` | Medica elettrica con caschetto castano, divisa bianco-ciano, guanti teal e simbolo generico a cuore; accento ciano con lampo giallo. |

Alea e Aleo hanno richiesto un passaggio correttivo `background-extraction`:
rimuovere soltanto il checkerboard chiaro incorporato, preservando soggetto,
pixel-art, colori, effetti e inquadratura, e produrre alfa reale senza ridisegno.

### Trasformazione deterministica

I derivati sono ottenuti con:

```powershell
.\tools\process-upgrade-icon.ps1 -InputPath <master> -OutputPath <runtime> `
  -Size 256 -Padding 24
```

Lo script ritaglia sui bounds alpha con soglia predefinita `8`, inserisce il
soggetto in un canvas quadrato trasparente e riduce nearest-neighbor. I master
restano in `hd/`, protetti da `.gdignore`; soltanto `generated/` è destinato al
runtime futuro.

### File e integrità

| Personaggio | Master HD escluso | SHA-256 master | Derivato runtime | SHA-256 runtime |
|---|---|---|---|---|
| Alea | `hd/evil_alea_source.png` (`1145x1374`) | `6EA34F34A2657A015C4DA5227788751BE61B4B03888FEE79724920C52E20CEED` | `generated/evil_alea.png` (`256x256`) | `DBC64CC4398AF5152F4724266BFC415F4CC5A2915CDF881F3AAEE83BC3840571` |
| Aleo | `hd/evil_aleo_source.png` (`1239x1270`) | `615835723D6DFE04EFDF58021765937CBF401693354E4553C7154D19F9538B03` | `generated/evil_aleo.png` (`256x256`) | `F5A25E8B53E17BD4B1D9D4CCA35176EA6B399D3C39795DDB70CCC789A91DAEF2` |
| Bea | `hd/evil_bea_source.png` (`1254x1254`) | `D010B56345970E3D45DFDDDF23F4CC698F3DDE70981C290B87CEC80A2790F18F` | `generated/evil_bea.png` (`256x256`) | `81AEF0A3B73D1C102FAB653BC151AF33A42EA9082A35422E559294F61C8CCE8E` |
| Lollo | `hd/evil_lollo_source.png` (`1254x1254`) | `009820FFB0BF06C639EEFEF83BD4561DF9AA70A0B4200B61C96899D2C1749FA5` | `generated/evil_lollo.png` (`256x256`) | `21A4B9A35F38614F2C4DCDE502CBD004FCD65F2764EB0C68B06219115B8D914B` |
| Magno | `hd/evil_magno_source.png` (`1254x1254`) | `BDC3FF4097E0220928FAFA2C24E7C0C6EB9FE8DFE2FAF55A7C4F3FC2D6A8EFBC` | `generated/evil_magno.png` (`256x256`) | `D55F715224C99EE59EAB98B95E135C64B4B07105845390F57DA5095197CBF6F1` |
| Marghe | `hd/evil_marghe_source.png` (`1254x1254`) | `A5B56E0568578E6ACC9A49FD75966D792EB1ED68D4F3C6BB3AC643FB6A075504` | `generated/evil_marghe.png` (`256x256`) | `9C3818FA2B550E49DA73FEA0051AD87479D15BC97A3A9D1422D35B1BF90B18E3` |
| Migi | `hd/evil_migi_source.png` (`1254x1254`) | `1C4605A9C582DF2582BFA5241FE96ABC89B83F944F64B816BE439000BA7D3904` | `generated/evil_migi.png` (`256x256`) | `9818F360B1A24562DB3E4CE0FEFC4173EDC34F9F16A802F073D0AA19C1A25573` |
| Zat | `hd/evil_zat_source.png` (`1254x1254`) | `334B650872FB8201E1B4B8E4D1FE9174998155658A2D91DCCCD0A6C7C74D15B4` | `generated/evil_zat.png` (`256x256`) | `AAD26DFA34729C379CE24F735F2DF569C315D6F9A2CAF2371D6CA64EA2257F00` |
