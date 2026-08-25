# Manifest branding applicazione

## Icona applicazione Pidgeon Survivor

Data: 25 agosto 2026  
Generatore: OpenAI ImageGen built-in  
Autore dichiarato: progetto Pidgeon Survivor con assistenza OpenAI ImageGen  
Licenza: asset proprietario del progetto, approvato per la distribuzione  
Riferimento visivo: `assets/art/ui/welcome/welcome_logo.png`, fornito dal
proprietario; usato soltanto per identità, palette e stile, senza riprodurre
titolo, insegna o sottotitolo.

### Prompt finale

```text
Use case: logo-brand
Asset type: final square app icon master for the Godot game Pidgeon Survivor on Windows and Android
Input image: the supplied Pidgeon Survivor welcome logo is a visual brand reference only; create a new standalone icon composition, do not reproduce the title sign or ribbon.
Primary request: create a bold, instantly recognizable 1:1 app icon featuring one cool city pigeon in a close chest-up portrait, centered and facing slightly right, wearing chunky black pixelated deal-with-it sunglasses. Give it a vivid orange beak, grey-blue feathers, and the brand's teal-to-purple iridescent neck. Behind the pigeon place a simple orange-gold circular barbecue ember halo with a very subtle grill-grid suggestion, against a deep midnight navy background with a few restrained warm pixel sparks.
Style/medium: polished hand-crafted 2D pixel-art arcade illustration matching the supplied brand reference; crisp clustered pixels, thick near-black silhouette, chunky readable shapes, high contrast, premium game-store icon finish.
Composition/framing: exact square 1:1; one large centered subject occupying about 68% of the canvas; keep all essential head, beak, glasses, halo, and outline inside the central 76% safe zone so Android circular/squircle masks cannot crop them; full-bleed background; no outer frame and no baked rounded corners.
Color palette: midnight navy, charcoal outline, pigeon grey-blue, teal and purple iridescence, orange beak, amber and ember-red glow.
Text: none.
Constraints: exactly one pigeon; iconic at 48 px; symmetrical visual weight; solid opaque background; clean silhouette; no transparent checkerboard; no humans; no logo words; no letters; no numbers; no title sign; no ribbon; no UI; no watermark; no photorealism; no gradients that make the silhouette muddy.
```

### Prompt finale foreground adattivo

```text
Create an Android adaptive-icon foreground layer from the supplied final Pidgeon Survivor app icon. Preserve the pigeon character, pixel sunglasses, orange beak, grey-blue feathers, teal-purple iridescent neck, thick near-black pixel-art outline, and orange barbecue halo as faithfully as possible. Remove the entire midnight-navy square background and all loose sparks outside the halo, replacing them with true alpha transparency. Keep exactly one centered pigeon plus its complete orange halo, with comfortable transparent padding: all essential head, beak, sunglasses, shoulders, and halo must remain inside the central 66% safe zone of the 1:1 canvas so circular and squircle Android masks do not crop them. Do not add text, letters, numbers, frames, corners, shadows, new objects, or a replacement background. Output a square PNG with genuine transparent background, crisp pixel-art edges, and the same polished arcade-game style and color palette as the reference.
```

### Trasformazioni e uso runtime

- `pidgeon_survivor_app_icon.png`: output ImageGen RGB `1254×1254` copiato
  senza ritaglio, ricampionamento o correzioni locali; usato da
  `application/config/icon`, dal preset Windows e come main icon Android;
- `pidgeon_survivor_adaptive_foreground.png`: secondo output ImageGen RGBA
  `1254×1254`, derivato dal master eliminando il fondale; ridotto
  deterministicamente al `70%` con ricampionamento bicubico e centrato sul
  canvas trasparente originale. Il contenuto con alpha maggiore di `8` occupa
  `x=247..990`, `y=230..1034`; usato come foreground adattivo Android. Lo
  SHA-256 dell'output ImageGen prima della trasformazione era
  `2d2d03ae6996d72b4c1034cab164bb10f38930cf2ae5a2a5891e958799217fd3`;
- `pidgeon_survivor_adaptive_background.png`: PNG RGB `432×432` creato
  deterministicamente con il colore notte `#071126`; nessun contenuto
  generativo, testo o dettaglio interattivo;
- Godot genera le densità Android inferiori dal master; gli elementi essenziali
  restano nella safe zone centrale, mentre alone e scintille possono essere
  tagliati dalle maschere del launcher;
- l'icona monocromatica Android 13+ non è inclusa e resta opzionale per B20.

| File | Formato | SHA-256 |
|---|---|---|
| `pidgeon_survivor_app_icon.png` | `1254×1254` RGB PNG | `99e86e1354361736973e789e80f0c2382650d54ef4f5160c49c04fe856c5ba32` |
| `pidgeon_survivor_adaptive_foreground.png` | `1254×1254` RGBA PNG | `a1a0ea8bb66a3a1818f285b8c46aa110db4a74f02cd696d1d9d9e3206ce43a4f` |
| `pidgeon_survivor_adaptive_background.png` | `432×432` RGB PNG | `86ec85dbe31e6dccc77933b6b7f0d595c1f6068b90d95a99435441b5bfc6ad4f` |
