# Manifest UI ricompensa Barb

## Caricatura di Barb (PS-036)

Integrata il 31 agosto 2026. Origine: progetto IL GIOCO, generata secondo la
direzione approvata nella card PS-036. Autore: progetto IL GIOCO con assistenza
OpenAI ImageGen built-in. Licenza: Licenza del progetto.

### Prompt finale

```text
Use case: precise-object-edit
Asset type: decorative character portrait for a Godot 4 pixel-art survivor game's special reward header
Input images: Image 1 is the exact current pixel-art portrait to edit; Image 2 is the approved character reference for Barb.
Primary request: simplify the current seasoned "Maestro della griglia" portrait with three precise changes while preserving identity and grill-master wear.
Change 1 — remove the lower hand: completely remove the gloved hand resting across Barb's belly/apron. Reconstruct the apron front and pocket naturally where that hand was. No hand or fingers may rest on the torso. Keep only the raised thumbs-up hand as an active visible hand. To preserve the idea of a matching pair of grill gloves, one empty spare leather glove may be neatly tucked partly into the apron pocket, clearly limp and unoccupied, but it must not look like a hand pressing against the body.
Change 2 — chunkier pixel art: make the entire portrait visibly more pixelated and game-sprite-like, with larger deliberate square pixel clusters, fewer tiny dither details, sharper stepped contours, simplified shading bands, and a lower-resolution 16-bit/32-bit arcade portrait feel. Keep it polished and readable, not blurry, noisy, smooth-painted, or photorealistic.
Change 3 — darker eyes: keep Barb's eyes blue but make them a deeper, darker steel-blue/navy-blue rather than bright cyan. They should remain recognizable without glowing.
Preserve exactly: Barb's recognizable face and friendly mischievous smile, beard, short receding hair, silver eyebrow piercing, corrected natural-length thumbs-up, worn brown leather glove, charcoal grill apron over forest-green shirt, brass hardware, soot/grease/ash stains, subtle sweat and facial soot, warm ember rim light, three-quarter angle, crop and silhouette.
Tone: seasoned, warm, humorous master of the grill who has just finished real work.
Scene/backdrop: keep a perfectly flat solid #ff00ff chroma-key background for local removal.
Constraints: only one person; no lower hand on belly; no extra active hands; no grill, food, utensils, tools, hat, flames, smoke cloud, text, logo, watermark, UI frame, or extra props. Keep all visible body parts inside canvas. Do not use magenta or pink in the subject. Background must remain one uniform chroma color with no shadow, gradient, texture, floor plane, reflection, or lighting variation. Crisp hard silhouette suitable for chroma-key removal.
```

### Trasformazioni e uso runtime

1. Il master cromatico ImageGen e stato salvato in `hd/`, escluso da import ed
   export tramite `.gdignore`.
2. `remove_chroma_key.py` ha prodotto il master RGBA con campionamento del
   bordo, soft matte, soglie `12/220` e despill; colore rilevato `#f205e5`.
3. `tools/process-character-select-cta.ps1` ha ritagliato i bounds alpha e
   ridotto nearest-neighbor con `ScalePercent=24`, `VisibleAlphaThreshold=8` e
   `Padding=4`.
4. Il runtime referenzia soltanto `generated/barb_portrait.png`; i due master
   HD non entrano in EXE, APK o AAB.

| Percorso | Ruolo | Dimensioni | SHA-256 |
|---|---|---:|---|
| `assets/art/ui/barb_reward/hd/barb_portrait_raw_chroma.png` | master ImageGen cromatico | `1254x1254` RGB | `50C3B7EBA1CA29ADF8FB0063FC5CF4D1001985F17385A0DA9708EB4C14B01DEF` |
| `assets/art/ui/barb_reward/hd/barb_portrait_source.png` | master RGBA ripulito | `1254x1254` RGBA | `434A4529E3A2B5A574DB974038D8997699E9546452E46565D06D6E0EF46FD93C` |
| `assets/art/ui/barb_reward/generated/barb_portrait.png` | derivato runtime | `294x297` RGBA | `4F87DC0DB9149CFF04363AE80093F2D8FFCACE7AB549C9734D10982BF4A19D79` |

La caricatura e decorativa (`mouse_filter = IGNORE`): testi, focus, carte e
hit target restano nodi Godot separati. La resa percettiva finale resta
soggetta al controllo del proprietario sugli screenshot e su Pixel 9.
