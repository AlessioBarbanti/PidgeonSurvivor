# Manifest asset — Pickup

## B39 — Coscia di piccione (pickup di cura)

- Data integrazione: 2026-08-27.
- Origine: master PNG RGBA fornito direttamente dal proprietario nella cartella
  `hd/` e già generato fuori da questo repository; il repository non inventa
  prompt, generatore, autore o licenza di terzi non consegnati.
- Trasformazione: `tools/process-arena-obstacle.ps1` (variante non quadrata di
  `process-upgrade-icon.ps1`), ritaglio sul bounding box alpha (soglia `8`,
  padding `6`) e riduzione nearest-neighbor a `48×51` RGBA, aspect ratio
  naturale invece di canvas forzato.
- Runtime: `scenes/pickups/health_pickup.tscn` assegna il derivato come
  `HealthPickup.texture` di default; finché lo slot resta vuoto, lo script
  disegna un segnaposto a codice (osso + carne grigliata caricaturale). `hd/.gdignore`
  e i tre preset export mantengono il master fuori da import, EXE, APK e AAB.

| Elemento | Master HD (escluso da import/export) | Derivato runtime | Dimensioni | SHA-256 master | SHA-256 runtime |
|---|---|---:|---:|---|---|
| Coscia di piccione | `hd/health_pickup.png` (`1254×1254`) | `generated/health_pickup.png` | `48×51` | `BD119E8E325B1716A23D76E1873E4B0C58E973B5893EB091B89EC4A6CA818B14` | `CA539C474D12C7C2CCDE7C2A113E3A17A5166408D4D0AF7C04AF70497560F241` |
