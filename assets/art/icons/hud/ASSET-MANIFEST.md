# Icone HUD

## Calice Sobrietà di Alea — PS-104/PS-106 (07/09/2026)

- Origine: asset originale del progetto, generato con OpenAI ImageGen built-in
  per PS-104; nessun riferimento esterno usato.
- Autore: OpenAI ImageGen su direzione del progetto.
- Licenza: asset originale del progetto, utilizzabile e modificabile nel gioco
  e nei suoi materiali promozionali.
- Runtime: PS-104 sostituisce i placeholder nei percorsi già cablati da
  [PS-106](../../../../docs/cards/3_in_sprint/PS-106-integra-icona-calice-sobrieta-alea-hud.md);
  l'integrazione, refresh e gate percettivi rimangono di PS-106.
- Trasformazioni: `tools/process-layered-hud-icon.ps1 -Size 128` conserva la
  canvas condivisa 1254×1254, usa nearest-neighbor e separa il vetro dal vino
  tramite la gamma cromatica borgogna del master. `hd/.gdignore` esclude i
  master da import ed export.

### Prompt finale

```text
Create a single centered pixel-art game HUD icon master: an elegant stemmed
red-wine goblet, upright, three-quarter frontal view, tall bowl, narrow stem
and sturdy foot. This is for the character Alea's "Sobriety" meter in Pidgeon
Survivor. Polished 32-bit arcade pixel art with chunky readable pixel
clusters, crisp dark plum/navy outline, restrained palette, muted antique gold
rim and stem details, subtle cool pale-blue glass highlights, deep burgundy
red wine visibly filling roughly the lower half of the bowl. The silhouette
must remain obvious when reduced to a 32x32 HUD icon: large bowl, clear empty
upper bowl, clear wine surface, no small decorative clutter. Isolated subject
with transparent background, fully inside the canvas, generous even padding.
No text, labels, logos, border, UI frame, cards, characters, animals, hands,
shadows, reflections outside the goblet, photorealism, smooth vector style,
gradients, or multiple objects. The wine and glass must be visually separable
so production can split them into aligned layers later.
```

| Percorso | Dimensioni | Uso | SHA-256 |
|---|---:|---|---|
| `hd/alea_sobriety_goblet_master.png` | `1254×1254` RGBA PNG | Master ImageGen escluso da import/export | `F52F5DF80A6CF0E2D9C8713287728AD9FE1F9F057D828785A06F6047CC7BA72B` |
| `hd/alea_sobriety_wine_fill_source.png` | `1254×1254` RGBA PNG | Sorgente isolata del solo vino, esclusa da import/export | `37474AB4B0C293F90BF9211AF74638F0C268353C5ABBD283B01F07E09DFD20E6` |
| `generated/alea_sobriety_glass_empty.png` | `128×128` RGBA PNG | Layer statico runtime: vetro, outline, stelo e piede | `4DD0A8FA01059199FE6F3876839F991FE2CA76E44B1B74F389113A10418908DD` |
| `generated/alea_sobriety_wine_fill.png` | `128×128` RGBA PNG | Layer runtime: solo liquido, mascherato dal basso | `60BC7C175B4C5BE33053F1FCD509CC18A1AA66FAA63517162AC28E49DDFC8135` |
