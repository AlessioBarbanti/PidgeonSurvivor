# Manifest asset — Icone piccioni speciali

## B49 — Icone UI degli archetipi nemici

- Data generazione: 28 agosto 2026.
- Origine: OpenAI ImageGen built-in. Autore: progetto IL GIOCO con assistenza
  OpenAI ImageGen. Licenza: Licenza del progetto.
- Scopo: icone per il futuro tutorial UI; soggetto, contorno e accento restano
  leggibili a dimensioni ridotte. Non sono ancora assegnate al runtime né
  sostituiscono le texture gameplay B49.
- Prompt condiviso: icona quadrata per gioco mobile, un solo piccione fantasy
  pixel-art 16-bit centrato, silhouette semplice con contorno navy/scuro e
  poche campiture grandi, pensata per restare leggibile a `48×48`; nessun testo,
  badge, cornice, UI, logo, watermark o persona. Sfondo a chroma `#00ff00`
  richiesto per il cutout; l'output consegnato da ImageGen era già PNG RGBA con
  angoli trasparenti, quindi non ha richiesto la rimozione chroma.
- Trasformazione: `tools/process-upgrade-icon.ps1`, bounds alpha con soglia `8`,
  padding quadrato `12`, resize nearest-neighbor RGBA a `128×128`. I master
  `1254×1254` in `hd/` sono esclusi da import/export tramite `.gdignore`; solo
  i derivati in `generated/` sono destinati a un futuro riferimento runtime.
- Verifica statica: quattro derivati `128×128` RGBA con angoli trasparenti e
  bbox alpha controllato. Resta aperta la verifica percettiva sulle card e sul
  Pixel 9 quando le icone saranno collegate alla UI.

| Archetipo | Direzione specifica | Master HD escluso | Derivato runtime | SHA-256 master | SHA-256 runtime |
|---|---|---|---|---|---|
| Sciamatore | Piccione arancio-marrone rapido, ali a V e silhouette compatta | `hd/enemy_swarmer.png` (`1254×1254`) | `generated/enemy_swarmer.png` (`128×128`) | `3E021666C1FEEFFC9B413FB16A1507E4A21B06A9587CEF03C03F536076DD9899` | `7B147D945748B0C4CDF1F8F25FCD4F3ACB1B5FBDA8B2545E2D84F941BAD50D12` |
| Corazzato | Piccione grigio massiccio con pettorale e casco da coperchio | `hd/enemy_armored.png` (`1254×1254`) | `generated/enemy_armored.png` (`128×128`) | `218769C82C275AFD69F684383D17528413B418FA33251684325A1BDA5B510C84` | `2F9BC6CD2DD4BFBDFE7F98F798ADB9F2B103EFCC94041217E44CCDE22349438D` |
| Divisore | Piccione viola rotondo con crepa lavanda e due testine emergenti | `hd/enemy_splitter.png` (`1254×1254`) | `generated/enemy_splitter.png` (`128×128`) | `3287730E46317014B2A6FC543344C255668FF47F03A4FD5E0657DFB091371243` | `20E6EE8B9EBF2CD677DA84D73B5D932EF28265EC273A05C099259816C0734FE8` |
| Tiratore | Piccione teal snello con fionda e punto rosso di mira | `hd/enemy_ranged.png` (`1254×1254`) | `generated/enemy_ranged.png` (`128×128`) | `F03131C90F300C13F4EC41AFAA48AB4250A96FB42663A351B2FAD8B4F13176ED` | `EFE641018D14DF3D34B04AA72FAF897549F383E9BF1240BC8EC6F7390638762E` |
