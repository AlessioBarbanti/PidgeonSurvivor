# Manifest asset — Icone Signature Evil PS-052

## Produzione art-only del 1 settembre 2026

Le otto icone definitive sono state prodotte in anticipo rispetto
all'integrazione prevista da PS-052. I file esistono come master HD e derivati
runtime, ma **non sono referenziati** da `data/bosses/signatures/*.tres`, scene o
script. I valori di gameplay e gli `accent_color` restano invariati;
l'accettazione percettiva del proprietario resta aperta.

- Origine: OpenAI ImageGen built-in.
- Autore: progetto IL GIOCO con assistenza OpenAI ImageGen.
- Licenza: Licenza del progetto.
- Riferimenti ispezionati: le otto icone approvate in
  `assets/art/icons/abilities/generated/`. Non sono state allegate come input a
  ImageGen: hanno guidato densità, outline, margini e leggibilità del brief.

### Prompt e grammatica condivisa

Prompt comune normalizzato: icona quadrata da Boss Signature, emblema singolo
centrato, pixel-art arcade rifinita, outline prugna scuro, palette satura
limitata, cluster grossi, silhouette netta, contenuto circa `78%` e almeno `10%`
di margine trasparente; nessun testo, cornice, pulsante, logo, watermark,
scenario, fotorealismo, checkerboard o rumore minuto; forma e colore devono
descrivere soltanto l'area e il comportamento dichiarati dalla Signature.

| Signature | Specifica del prompt e accento |
|---|---|
| Gran Piroetta | Tutu crema-rosa avvolto da due archi magenta opposti che formano una rotazione quasi circolare, una sola scintilla oro; `#ff5799`. |
| Shock Termico | Un anello ciano di grandi cristalli racchiude un burst arancio nello stesso centro, con un solo vapore a S; `#6bdcff`. |
| Powerslide | Un pattino inline viola con esattamente quattro ruote su una traiettoria di fuoco arancio rettilinea e diagonale; `#ff5c2e`. |
| Cosplay Casuale | Maschera teatrale a due volti viola-ciano in trasformazione, una freccia curva di scambio e tre frammenti astratti; `#f23ddb`. |
| Onda d'Urto Tellurica | Pugno roccioso pesante che colpisce il centro, un solo anello ambra in espansione e quattro fratture verso l'esterno; `#ff9e29`. |
| Reggaeton time! | Due silhouette umane nella stessa posa, figura ciano davanti e clone prugna traslucido in offset, su una breve onda ritmica; `#59ebff`. |
| Rallentamento Zen | Loto menta davanti a un guscio esagonale, onde lente concentriche e un proiettile che si dissolve sul bordo; `#52f0cc`. |
| Tempesta di Tuoni | Nuvola compatta, lampo giallo-bianco e aura circolare ciano con tre scintille orbitali; `#9edbff`. |

### Art review e correzioni

- Powerslide v1 è stata scartata perché mostrava cinque ruote; la versione
  promossa richiede quattro ruote e una sola traiettoria lineare.
- Reggaeton v1 è stata scartata perché una silhouette risultava aviaria; la
  versione promossa usa esattamente due sagome umane in offset, senza becco,
  ali, piume o note musicali.
- Le altre sei candidate hanno superato la review di silhouette e coerenza col
  telegraph al primo passaggio.

### Trasformazione deterministica

I derivati sono ottenuti con:

```powershell
.\tools\process-upgrade-icon.ps1 -InputPath <master> -OutputPath <runtime> `
  -Size 256 -Padding 20
```

Lo script ritaglia sui bounds alpha con soglia predefinita `8`, applica padding
quadrato e riduce nearest-neighbor. I master restano in `hd/`, protetti da
`.gdignore`; soltanto `generated/` è destinato al runtime futuro.

### File e integrità

| Signature | Master HD escluso | SHA-256 master | Derivato runtime | SHA-256 runtime |
|---|---|---|---|---|
| Gran Piroetta | `hd/evil_alea_grand_spin_source.png` (`1254x1254`) | `8D61857B73DDECC974272DE19A3C49024E205DC8F0A1C1972C579C1FA1068BAE` | `generated/evil_alea_grand_spin.png` (`256x256`) | `FFEBC5F5F2FBDC6F2626EDAD745C1777AD9E0213E74B2F37AD89111CD1666F91` |
| Shock Termico | `hd/evil_aleo_thermal_shock_source.png` (`1254x1254`) | `7BDA6DF7307423642FD41973F5FF65C345BFBB65E475A9DA25AD68F649BDAC6D` | `generated/evil_aleo_thermal_shock.png` (`256x256`) | `3226C6B8DBC4BCA2DDD1E7E7AFA3E778AAF21516DBD6104F65F68661226827A9` |
| Powerslide | `hd/evil_bea_powerslide_source.png` (`1254x1254`) | `7C4B0B98FD2625733F575E7A56AA846762DCDB679EB7E69B4E365F2BFD39D320` | `generated/evil_bea_powerslide.png` (`256x256`) | `13FE63DF5C6F3F358DE56FCAB1EF27B180288BA55E982998C1590DA633844875` |
| Cosplay Casuale | `hd/evil_lollo_random_cosplay_source.png` (`1254x1254`) | `2F95D1092C148258E7BEDD2F6C08B4F1BE8C94DA0375A7135BAA98E1E18C9A9F` | `generated/evil_lollo_random_cosplay.png` (`256x256`) | `C24BFCE64A98156E3BECFBA473CFA7FF37D3F0A41AFA3054ECADF93337F37787` |
| Onda d'Urto Tellurica | `hd/evil_magno_telluric_shockwave_source.png` (`1254x1254`) | `1EFBF71020EADE171BEC38DA377BD1FE4DB14E775F82B0E31CB8D23E6BF5C0DB` | `generated/evil_magno_telluric_shockwave.png` (`256x256`) | `BB34D1C67845D2D5EA2445A740C1F492C155B77F9ED44BDC417B7737C5BC1C80` |
| Reggaeton time! | `hd/evil_marghe_reggaeton_clone_source.png` (`1254x1254`) | `44CFEF5FB4E040284A9D68243436BA861C86148FE44C5DCC88908CF44891B71F` | `generated/evil_marghe_reggaeton_clone.png` (`256x256`) | `6779344E31D87CFBA24DAA891358ED913846EBA4033AFA49B1AED29EC570DC8B` |
| Rallentamento Zen | `hd/evil_migi_zen_slowdown_source.png` (`1254x1254`) | `BB93691D5C1AD18B09E5D5CDDE098F5D3BC4C3007F325759A95D37BA9CA4E2A7` | `generated/evil_migi_zen_slowdown.png` (`256x256`) | `7646D234A07EE18346DCA4552C6108214F135919BA4AFE3176484F5ED5C349B6` |
| Tempesta di Tuoni | `hd/evil_zat_thunder_storm_source.png` (`1254x1254`) | `1EF5909DB1E308D1A8F99E4070EC6866A205B24C03E9FF2E8D5E22FE3AABBB24` | `generated/evil_zat_thunder_storm.png` (`256x256`) | `2A35A3E469FBBC26100F52223A04E332C9C3ED218C656245B7D4C0DF6AE0EC25` |
