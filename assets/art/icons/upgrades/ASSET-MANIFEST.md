# Manifest asset — Icone potenziamenti

## B26/B27 — Forchettone da Braciere e refresh carte

- Data integrazione: 2026-08-26.
- Origine: dieci master PNG RGBA forniti dal proprietario e già generati manualmente per il progetto. Il repository non inventa prompt, generatore, autore o licenza di terzi non consegnati; i master sono trattati come asset del progetto per l'uso in gioco.
- Trasformazione: `tools/process-upgrade-icon.ps1`, bounds alpha con soglia `8`, padding quadrato `12` e riduzione nearest-neighbor a `128×128` RGBA.
- Runtime: soltanto i derivati in `generated/` sono referenziati dalle `UpgradeDefinition`. `hd/.gdignore` e i tre preset export mantengono i master fuori da import, EXE, APK e AAB.

| Carta | Master HD escluso | Derivato runtime | SHA-256 master | SHA-256 runtime |
|---|---|---|---|---|
| Dai che si fredda! | `hd/upgrade_move_speed.png` (`1254×1254`) | `generated/move_speed.png` (`128×128`) | `325AD2FC344095D85EC84A4E13CC889EF38CD7AE9E881C01DBB7A2DBB9086737` | `D1BECE51AB9514672327DE6D4352D41003BF7A30C71080AA4B5313B9F3E30190` |
| A Tutta Brace! | `hd/upgrade_a_tutta_brace.png` (`1254×1254`) | `generated/a_tutta_brace.png` (`128×128`) | `0507F740E6375EA387C08DEBEACDA37D8E190A5F1DFB5650E8014BA6E675B917` | `E9FEB0A8F163D742F42B335165F43ECB8AA647ACBA151A7A0783FEF4F5C7850A` |
| Pinza Lunga | `hd/upgrade_pinza_lunga.png` (`1536×1024`) | `generated/pinza_lunga.png` (`128×128`) | `658AC17A1399B005B95B633270C9BF00E6FC18771F24BC3232BA5160854D7AB0` | `510E9DC95679DA1793E3A5AE1C63CBB18120083AB6246E3FA95CE4D0C846D533` |
| L'Ansia | `hd/upgrade_anxiety.png` (`1428×1101`) | `generated/anxiety.png` (`128×128`) | `B8143AF622A680791FCA8E5095C507315EF479702B37F4C211905ADDA689B74E` | `38869D6FF0BB7BE8035A22872DEED737FFB089B19A38B2CAE5E5E7ED815DBE95` |
| Birra *(superata da PS-078, vedi sotto)* | `hd/upgrade_beer.png` (`1536×1024`) | `generated/beer.png` (`128×128`) | `751D5AFF54F89D5B3A8021787EE58C2BB630560FADDD478022058A2F0CD00E47` | `5CF2536EADAD28C086308803858EC2FF2242DF0ADD6AE9BCE8EB4453A0D1DA85` |
| Ritardo Cronico *(superata da PS-078, vedi sotto)* | `hd/upgrade_chronic_delay.png` (`1536×1024`) | `generated/chronic_delay.png` (`128×128`) | `B5C0731E8A9BA2A16DEC42FE4DB58A234909504D1C3602944763C2F79F5DDB8E` | `B7263852BC77EFE3668C681DB0C99A1C5793EB5D02EF44E38925E35E65AEA1D1` |
| Forchettone da Braciere | `hd/upgrade_damage_meat_fork.png` (`1254×1254`) | `generated/meat_fork_damage.png` (`128×128`) | `AEA17B6EE93CE03DD2EC6430F08DCED45D3FA94AFF04923FC71404E75C34FD85` | `4EEE3E9990CDF5C432D03C382808036134AA69810F5A87B5BEA41A6418F15C8D` |
| Gossip *(superata da PS-078, vedi sotto)* | `hd/upgrade_gossip.png` (`1254×1254`) | `generated/gossip.png` (`128×128`) | `AF980C892968B8003977610F39789EE04D66FEB7B91A563A4100F3287C75C8E8` | `F337A087D2375D74D316F0A9E22D96C15353B83B81B0E2EA8E71D063EFED6AB6` |
| Non Ho Tempo Per Questo *(superata da PS-078, vedi sotto)* | `hd/upgrade_no_time.png` (`1536×1024`) | `generated/no_time.png` (`128×128`) | `1D86B7AEE938E13AB63D8F85E5AE9DD2EEB4526A02E88F69241818F0A335BDCF` | `FB27C5405CA2B9CD8C02F86DFF271DE664EEB0D086D34369BE330367E3A00D16` |
| Grigliata estiva | `hd/upgrade_summer_grill.png` (`1536×1024`) | `generated/summer_grill.png` (`128×128`) | `A14F484BA980599CCB75264F99C2334D9C799762CC26DF4DE5D1974EBD5C2139` | `11A7B6AC29E17FE58E50194BDF6D9D78A4CAF41BAEF59285145124E5D547560D` |
| Via dalla Griglia! | `hd/upgrade_via_dalla_griglia.png` (`1536×1024`) | `generated/via_dalla_griglia.png` (`128×128`) | `34B1BA47CF7A77420BB8D234E1EDFA90CE515FAD2C971078E8C16BC42B816A7F` | `5E0DFAC171B055D44585369710AC062DCC2386D488C1BC3FC41BCA6759E30A9D` |
| Pirofila Rinforzata | `hd/upgrade_pirofila_rinforzata.png` (`1536×1024`) | `generated/pirofila_rinforzata.png` (`128×128`) | `BB901AE4F937B915000CF84B55D95ACCCA1C384EDE83B1BDEC4AA6FDECC267FF` | `7CAFFC2C6B5508AB15188AF475EA7AFE24A81B2E696189D815000EB312CA7C0B` |
| Il condimento di Barb | `hd/upgrade_condimento_di_barb.png` (`1254×1254`) | `generated/condimento_di_barb.png` (`128×128`) | `D44E4CD8BCDECBAD002CADC75709AB0812607FBC453BE7BB045FB30D055FA3C0` | `9ED19225F4EA8F431BE4853E1193F71CE95FA41D1850F76245B2A958D2611E26` |
| Bis di Salsiccia | `hd/upgrade_bis_di_salsiccia.png` (`1254×1254`) | `generated/bis_di_salsiccia.png` (`128×128`) | `5DF4E4F86A2261AC344508820CBEBDBCAB2F8187E85C1286C5B2BD850E9D92DF` | `44BCF523C7B388C3555E7BA09E416A216017E517DADF957D20F598C8044E88F4` |

## B41 — Forme d'attacco con tagli di carne

- Data integrazione: 28 agosto 2026.
- Direzione approvata dal proprietario: sostituire i tre badge geometrici
  provvisori con soggetti da griglia riconoscibili — Spiedino, doppia Costina e
  Coppa — mantenendo invariati ID e comportamento delle carte.
- Origine: OpenAI ImageGen built-in; le rigenerazioni di Colpo Perforante e
  Raffica Doppia sono state fornite dal proprietario come candidate HD. Autore:
  progetto IL GIOCO con assistenza OpenAI ImageGen; licenza: Licenza del
  progetto. Il master
  `upgrade_damage_meat_fork.png` è stato usato soltanto come riferimento dello
  stile pixel-art arcade, della palette griglia e del peso dei contorni.
- Trasparenza: output su chroma uniforme verde, rimosso con
  `remove_chroma_key.py --auto-key border --soft-matte
  --transparent-threshold 12 --opaque-threshold 220 --despill
  --edge-contract 1`.
- Runtime: `tools/process-upgrade-icon.ps1`, bounds alpha con soglia `8`, padding
  quadrato `12`, nearest-neighbor a `128×128` RGBA. I master `1024×1024` delle
  due rigenerazioni e il master Coppa `1254×1254` restano in `hd/`, esclusi da
  import ed export; soltanto i derivati mantengono i nomi già referenziati dalle
  `UpgradeDefinition`.

Prompt condiviso normalizzato: icona quadrata HD, un soggetto centrale in
pixel-art arcade coerente col Forchettone da Braciere, contorno scuro, carni
rosso-brune grigliate, osso avorio, scintille ambra, nessun testo, badge,
cornice, persona, arma da fuoco o oggetto estraneo. Specifiche per carta:

I prompt integrali effettivamente usati e la reference di stile con hash sono
storicizzati in `docs/archive/generation-prompts-and-references.md`.

- **Colpo Perforante:** un unico spiedino metallico attraversa esattamente tre
  bocconi di carne disossata, in diagonale, con punta e scintille di
  penetrazione leggibili.
- **Raffica Doppia:** esattamente due Costine con osso, separate e lanciate a
  ventaglio con due brevi scie calde.
- **Esplosione Finale:** una fetta rotonda di Coppa marezzata al centro di un
  burst radiale compatto di fiamme ed ember.

| Carta | Master HD escluso | Derivato runtime | SHA-256 master | SHA-256 runtime |
|---|---|---|---|---|
| Colpo Perforante *(superata da PS-078, vedi sotto)* | `hd/upgrade_piercing_rounds_spiedino.png` (`1024×1024`) | `generated/piercing_rounds.png` (`128×128`) | `903FD8857DBC68D2A17B0B5996B809A357CC6851F4851E0EA6408523392FBC1C` | `C619A100C1E7D31B81AA98474C192211AED394FD8D48C8D2354D245CB851858B` |
| Raffica Doppia *(superata da PS-078, vedi sotto)* | `hd/upgrade_double_barrel_costine.png` (`1024×1024`) | `generated/double_barrel.png` (`128×128`) | `1859ED1F8E47311DCB14797F355A4EDBECDF2E246837D79EA5AFB1CB1AD3A1FD` | `A7F5FB212CED181A29050970D397DE23795CB2B4405A47D1D154F731E83318CE` |
| Esplosione Finale *(superata da PS-078, vedi sotto)* | `hd/upgrade_death_burst_coppa.png` (`1254×1254`) | `generated/death_burst.png` (`128×128`) | `1F78D20AED70B10DC174E69691899F69FFE9059FA12FA39BDEBD4D1EEA74CD0A` | `8E47934030DAA0A5BE124B151B54E10BBC8F58D3A0F7EFBA79543DA388AE450D` |

## PS-078 — Le Specialità di Barb come tagli alla griglia

- Data integrazione: 5 settembre 2026.
- Contesto: le sette Specialità di Barb (`beer_signature`, `chronic_delay`,
  `damage_shockwave`, `death_burst`, `double_barrel`, `gossip_projectiles`,
  `piercing_rounds`) passano dal linguaggio visivo generico da
  upgrade/abilità a un "menù secco" di tagli di carne alla griglia — nomi e
  icone nuovi, effetto meccanico invariato. `anxiety_signature` (`L'Ansia`)
  resta fuori da questa card: nessuna icona è stata prodotta per lei, la sua
  riga di manifest non è toccata (materia di PS-100).
- Origine: **ImageGen via Codex CLI (gpt-image)**, invocato tramite i tool
  MCP `mcp__plugin_imagegen_imagegen__generate_image_set` e
  `mcp__plugin_imagegen_imagegen__generate_image` di questa sessione Claude.
  Autore: progetto IL GIOCO con assistenza OpenAI ImageGen; licenza: Licenza
  del progetto. Riferimenti di stile usati (solo come guida di palette,
  contorno e pixel density, mai come edit target): `hd/upgrade_damage_meat_fork.png`
  (Alette, Hamburger, Costine, Tagliata, Salsiccia), `hd/upgrade_death_burst_coppa.png`
  (Fiorentina), `hd/upgrade_piercing_rounds_spiedino.png` (Arrosticini).
- Prima passata: un lotto di sette immagini generato con
  `generate_image_set` (stesso `style_guide` condiviso) è andato in timeout
  di post-elaborazione lato Codex a metà lavoro; solo `Alette` è arrivata
  pulita. Il file consegnato per "arrosticini" da quel lotto conteneva in
  realtà un soggetto sbagliato (una rastrelliera di costine, non uno spiedino
  di bocconi) ed è stato scartato senza essere integrato. Le rimanenti sei
  icone sono state rigenerate una per una con `generate_image`, specificando
  `background: transparent`. Due di queste rigenerazioni singole
  (`Costine`, `Salsiccia`) sono state a loro volta scartate dopo controllo:
  erano PNG RGB con uno scacchiera di trasparenza disegnata dentro l'immagine
  invece di un canale alfa vero, e sono state rigenerate una seconda volta
  con l'istruzione esplicita di alfa reale senza scacchiera. Tutti e sette i
  master finali in tabella sono stati verificati con Pillow: RGBA reale,
  alpha `0` ai quattro angoli.
- Trasformazione: `tools/process-upgrade-icon.ps1`, bounds alpha con soglia
  `8`, padding quadrato `12`, riduzione nearest-neighbor a `128×128` RGBA.
- Runtime: soltanto i derivati in `generated/` sono da referenziare dalle
  sette `UpgradeDefinition` (wiring fuori ambito di questa card). I master
  restano in `hd/`, esclusi da import/export dal `.gdignore` locale e dai tre
  preset di `export_presets.cfg` (verificato invariato).

Prompt condiviso (`style_guide` del lotto, riusato anche come preambolo delle
rigenerazioni singole): icona pixel-art arcade coerente con la famiglia
grigliatore esistente (spiedino a tre bocconi, doppia costina, coppa con
burst radiale, forchettone su bistecca) — contorno scuro spesso, cel-shading
piatto senza sfumature morbide, palette calda (umber carbonizzato, rosso
mattone, arancio arrostito, ambra dorata), segni di griglia a incrocio
diagonale sulla carne esposta, piccoli accenti di brace/scintilla
ambra-oro con bordo rosso scuro sottile, soggetto singolo centrato con
margine uniforme, sfondo trasparente reale (nessuna scacchiera), nessun
testo/badge/cornice/piatto/posate estranee/persona/arma da fuoco/piccione,
tela 1024×1024, silhouette leggibile anche a 128×128.

Prompt specifici effettivamente usati (soggetto + accento per carta):

- **Alette:** "three grilled chicken wings (whole flats/drumettes with
  visible bone tips), fanned out from a shared origin point at slightly
  different angles like a loose spread, each with crisp golden-brown grilled
  skin and light char-grill striping. Accent: a couple of tiny quick
  sizzle/spark flecks near the wingtips to suggest fast, hot cooking — the
  divergence of the three wings' directions is itself the main visual cue,
  not an arrow or motion line. No arrows, no chevrons, no speed lines."
- **Costine:** "a wide horizontal rack of pork ribs (costine) — four or five
  bones repeating side by side in a row, lying flat as seen straight-on from
  above the grill, deep brick-red char-grill sear marks running across the
  meat between the bones. The composition must read as a WIDE, repeated
  multi-bone rack, clearly different in silhouette from a single thick
  steak. Accent: two or three thick, heavy wisps of smoke drifting slowly
  downward and outward from the rack instead of rising upward quickly,
  conveying a slow, heavy, unhurried cook." (rigenerata con l'aggiunta "real
  alpha channel, fully transparent pixels, absolutely no checkerboard
  pattern baked into the image" dopo lo scarto della prima resa RGB).
- **Hamburger:** "a single grilled hamburger sandwich (toasted bun, one
  smashed beef patty with crisp charred edges, a corner of melted cheese
  peeking out) pressed flat and slightly askew as if just smashed onto a hot
  griddle grate, the top bun tilted from the impact. Accent: a thin ring of
  grease and juice splatter droplets plus a few small spark flecks radiating
  outward evenly from the point of the smash, like a compact shockwave
  centered on the burger. No plate, no fries, no wrapper."
- **Fiorentina:** "one single large, thick T-bone Fiorentina steak lying
  diagonally, unmistakably the biggest single cut of the family, with a
  prominent curved T-shaped bone clearly visible along one edge of the steak
  (not inside the meat) and deep parallel diagonal sear marks across the
  meat surface. The composition must read as ONE SOLID chunky mass with a
  single bone silhouette on the edge, clearly different from a repeated
  multi-bone rib rack. Accent: a compact radial flame burst hugging tightly
  to the steak's own silhouette — flame points stay close to the meat's edge
  rather than sprawling far into the empty margin."
- **Tagliata:** "a tagliata steak already sliced into three or four thick
  fanned slices, splaying outward and separating from one shared edge like
  an opened hand of cards, each slice showing a seared brown crust on the
  outside and a pink-red seared interior with fine grill-mark striping on
  the top face. Accent: two or three short, faint warm heat-shimmer streaks
  trailing outward in the same fanning direction as the slices, echoing
  pieces flying apart."
- **Salsiccia:** "a grilled link sausage twisted into three or four visible
  knotted segments forming a short chain (salsiccia a nodi), char-grilled
  casing with light diagonal sear striping along each link. Accent: one
  small bright ember/spark glow sitting right at one of the twisted knots
  between two links, as if energy or a hit is passing from one link to the
  next along the chain." (rigenerata con la stessa aggiunta anti-scacchiera
  di Costine dopo lo scarto della prima resa).
- **Arrosticini:** "one single long thin metal skewer stick threaded
  diagonally straight through five small cubed chunks of grilled lamb meat
  arranged in a tight single-file row along the skewer, each cube clearly
  separate with visible gaps between cubes and char-grill marks on its
  faces. The skewer's bare pointed metal tip must clearly poke out well past
  the last meat chunk at one end, and a short bare handle end shows at the
  other end beyond the first chunk. This must NOT look like a rack of ribs
  or a chain of linked segments — the cubes are individually separate pieces
  threaded on one visible straight skewer line, matching a shish-kebab
  silhouette. Accent: a small bright spark/glint right at the protruding
  pointed tip, showing the point breaking through and past the final
  chunk." (rigenerata con soggetto rinforzato dopo che il primo tentativo del
  lotto aveva consegnato un soggetto sbagliato).

| Carta | Master HD escluso | Derivato runtime | SHA-256 master | SHA-256 runtime |
|---|---|---|---|---|
| Alette *(rigenerata il 5 settembre 2026, vedi nota sotto)* | `hd/upgrade_speciality_alette.png` (`1254×1254`) | `generated/alette.png` (`128×128`) | `CE89B284CFA5AFC8E13A3E6A4440D539652CC0D8C06B9C372C948EF64D67268B` | `D0646894C00704A20169F6D94C2714C221380DA6DE230D6EF1F905DC5A29398C` |
| Costine | `hd/upgrade_speciality_costine.png` (`1024×1024`) | `generated/costine.png` (`128×128`) | `05C12DCFB121FB75B3CF40EFE3D44B862F27763119712145F0A94E8C30C9F7B4` | `C409A68089330B6C258B519770E70F185004ECA19D874FB0045C5550EC77B328` |
| Hamburger | `hd/upgrade_speciality_hamburger.png` (`1024×1024`) | `generated/hamburger.png` (`128×128`) | `062A40100934580EDACC07A5C5D9692945E1269CDA57108F0780AA74CD7C0AC8` | `74DD19F9243E1F75B9D3B2BD7A182F7B351A3C28C0FEF4A79C9C708B6C29B9C1` |
| Fiorentina | `hd/upgrade_speciality_fiorentina.png` (`1024×1024`) | `generated/fiorentina.png` (`128×128`) | `D945EE9B6F97C1427B1F74BA5FE06C1C5A197D1381F4F17E1C0BE366BB9900C6` | `0485A376B82E5999BAD0A3172E612417A72863BAABA3E96AADC3EB5887536EB0` |
| Tagliata | `hd/upgrade_speciality_tagliata.png` (`1024×1024`) | `generated/tagliata.png` (`128×128`) | `635ABFDE5BC4A9F8411B1ECB0030BA3B01BFA80E71910089FF0418A6B4BF71E3` | `CCD2C3FC0384EF17835183A4229227ECEC6595BAD4A352105F846D3236F08A53` |
| Salsiccia | `hd/upgrade_speciality_salsiccia.png` (`1024×1024`) | `generated/salsiccia.png` (`128×128`) | `8433B944B41FF4C9DF50264829BBB0B2A7CED9502241AFFBFA492FDEE1DA8575` | `D851001ED285C3C3EDE1EEBE2F27BEA7DD97A95A533080DF7D81DA9912900FF2` |
| Arrosticini | `hd/upgrade_speciality_arrosticini.png` (`1024×1024`) | `generated/arrosticini.png` (`128×128`) | `E37D5C651265C1D8286D98E54E14BB3AF4C32652B66122C4DA9982CA5143F0FC` | `4D42B3845EC05006B8CAABF921F03EB72A2B17CB510AC1AD5C8CBA64296A4801` |

Nota — rigenerazione di `Alette` (5 settembre 2026): la prima versione
(hash storicizzato sopra come superato) raffigurava tre cosce di pollo con
osso singolo dritto e pallina in fondo. Il proprietario ha rilevato una
collisione di leggibilità con `assets/art/pickups/generated/health_pickup.png`
(la coscia di pollo è già il pickup della vita del gioco): a 128×128 un
upgrade non deve poter essere scambiato con un pickup. Rigenerato in place
(stessi nomi file, wiring `.tres` invariato) come tre alette vere — segmento
piatto e angolato con gomito visibile a "V" spezzata, nessun osso esposto,
nessuna pallina — mantenendo la divergenza di direzione delle tre alette che
racconta la dispersione del colpo di `beer_signature` e i segni di
griglia/scintille della stessa famiglia. Origine: **ImageGen via Codex CLI
(gpt-image)**, tool MCP `mcp__plugin_imagegen_imagegen__generate_image` di
questa sessione Claude. Prompt effettivo:

> Pixel-art arcade game upgrade icon, square canvas 1024x1024, transparent
> background (real alpha channel, fully transparent pixels, absolutely no
> checkerboard pattern baked into the image). Subject: three whole grilled
> chicken wings, each wing bent sharply at a visible elbow joint into an
> angular "V" shape (drumette segment and flat/wingette segment meeting at a
> clear bend) — this is a FLAT, ANGLED wing silhouette, explicitly NOT a
> rounded drumstick shape. Do NOT show any single straight protruding bone
> with a round ball/knob at its tip — no exposed white bone at all, the
> wings are meat-only with crisp golden-brown grilled skin and light
> char-grill diagonal striping across both segments of each wing. The three
> wings radiate outward from a shared origin point, each pointing in a
> slightly different diverging direction (like a loose fan spread), to
> visually read as scattered shot dispersion. Accent: a couple of tiny quick
> sizzle/spark flecks near the wingtips suggesting fast, hot cooking. No
> arrows, no chevrons, no speed lines, no plate, no bone, no drumstick
> shape. Style: matching an established barbecue pixel-art family — thick
> dark outline, flat cel-shading without soft gradients, warm palette
> (charred umber, brick red, roasted orange, golden amber), centered
> composition with uniform margin, crisp readable silhouette even at small
> size 128x128. No text, no badge, no frame, no person, no firearm, no
> pigeon.

Verificato con Pillow: master RGBA reale `1254×1254`, alpha `0` ai quattro
angoli; derivato RGBA reale `128×128`, alpha `0` ai quattro angoli, nessuna
scacchiera. Trasformazione: `tools/process-upgrade-icon.ps1`, soglia alpha
`8`, padding quadrato `12`, nearest-neighbor. Confronto diretto a dimensione
reale con `health_pickup.png`: il pickup resta un singolo pezzo tondeggiante
con osso bianco a vista e pallina terminale; il nuovo `alette.png` è un
gruppo di tre cunei piatti e angolati senza osso, disposti in ventaglio — le
due silhouette non si sovrappongono più nemmeno a colpo d'occhio a 128px.

## PS-107 — Rigenera l'icona di Punto di Cottura (ex Salamoia Bolognese)

- Data integrazione: 7 settembre 2026.
- Contesto: il master orfano precedente `hd/upgrade_salamoia_bolognese.png`
  (mai derivato) era stato bocciato in art review durante PS-093 per tre
  motivi: silhouette a tre nuclei diagonali (ciotola, pennello, bistecca)
  invece di un unico cluster compatto, illeggibilità a 48×48 (macchia
  arancione/marrone indistinguibile), e confondibilità con "Il condimento di
  Barb" (stesso soggetto ciotola/spezie, stessa palette). Il vecchio master
  resta sul disco come storico bocciato, non toccato da questa card.
- Origine: **ImageGen via Codex CLI (gpt-image)**, tool MCP
  `mcp__plugin_imagegen_imagegen__generate_image` di questa sessione Claude,
  `background: transparent`. Autore: progetto IL GIOCO con assistenza OpenAI
  ImageGen; licenza: Licenza del progetto. Nessuna immagine di riferimento
  usata come edit target; la calibrazione di stile/densità/palette è avvenuta
  per ispezione diretta di `generated/meat_fork_damage.png`,
  `generated/pinza_lunga.png` e, per contrasto negativo,
  `generated/condimento_di_barb.png`.
- Direzione: un unico cluster fuso bistecca+termometro da cucina, non tre
  elementi separati. La sonda del termometro è infilata diagonalmente nella
  bistecca; il quadrante analogico mostra un arco colorato rosso-arancio-verde
  con l'ago fermo esattamente nella zona verde "perfetta", e un unico
  glint/scintilla ciano-bianco concentrato sul quadrante è l'elemento univoco
  di "colpo critico/punto di cottura perfetto" (accento cromatico freddo,
  isolato, mai ripetuto altrove nell'immagine — a differenza degli accenti
  ambra ricorrenti nel resto della famiglia). Nessuna ciotola, erbe, aglio,
  vaso o pennello: la composizione non condivide silhouette con "Il
  condimento di Barb". Densità di contorno: bistecca + sonda/quadrante +
  un solo accento di glint, coerente con `meat_fork_damage.png`/
  `pinza_lunga.png`, non con l'estremo scatter di `condimento_di_barb.png`.
- Prompt effettivo: "Pixel-art arcade game upgrade icon, square canvas
  1024x1024, transparent background (real alpha channel, fully transparent
  pixels, absolutely no checkerboard pattern baked into the image). Subject:
  ONE single compact visual cluster — a single thick grilled steak wedge
  lying diagonally (comparable size and weight to a classic fork-and-steak
  icon, not oversized), with a single metal meat thermometer probe plunged
  straight down into the center of the steak at a steep diagonal angle. The
  probe's thin shaft disappears into the meat; its round analog dial gauge
  head sits just above the steak surface, clearly visible. The dial face
  shows a simple colored arc gauge (red on one end, orange in the middle,
  green at the other end) with a thin dark needle pointing exactly into the
  green 'perfect' zone at the top of the dial. Right at the tip of the needle
  in the green zone, a small sharp bright cyan-white starburst spark/glint
  bursts outward, as the single unique visual cue for 'critical hit / perfect
  cooking point', compact and sitting directly on the dial, not scattered
  into the background margin. Add only one or two thin diagonal grill sear
  marks on the steak's surface. Do not include a bowl, jar, herbs, garlic,
  paintbrush, or any scattered spice flecks anywhere in the image. Style:
  matching an established pixel-art barbecue arcade family — thick dark
  outline, flat cel-shading without soft gradients, warm palette (charred
  umber, brick red, roasted orange) for the steak and thermometer body, plus
  a single isolated accent of bright cyan-white spark glow only at the
  critical-hit starburst (nowhere else in the image). Single compact centered
  composition with uniform margin, crisp readable silhouette even when scaled
  down to 128x128 and 48x48 pixels. No text, no numbers, no badge, no frame,
  no plate, no cutlery besides the thermometer, no person, no firearm, no
  pigeon."
- Verificato con PowerShell/System.Drawing: master RGBA reale `1254×1254`,
  alpha `0` ai quattro angoli. Trasformazione:
  `tools/process-upgrade-icon.ps1`, soglia alpha `8`, padding quadrato `12`,
  nearest-neighbor a `128×128` RGBA, derivato `128×128` verificato senza
  scacchiera. Leggibilità a 48×48 verificata esplicitamente con un
  downscale nearest-neighbor addizionale del derivato (fuori pipeline
  runtime, solo per art review): bistecca, sonda, quadrante e i tre colori
  dell'arco restano distinti a colpo d'occhio; confronto diretto contro lo
  stesso downscale di `meat_fork_damage.png` (silhouette comparabile) e
  `condimento_di_barb.png` (diventa una macchia illeggibile a quella scala,
  confermando il problema originale che questa card doveva evitare).
- Runtime: nessun file `.tres`/scena/registry referenzia ancora il derivato.
  Il cablaggio nel catalogo live resta a
  [PS-108](../../../../docs/cards/2_to_do/PS-108-integra-carta-punto-di-cottura.md).

| Carta | Master HD escluso | Derivato runtime | SHA-256 master | SHA-256 runtime |
|---|---|---|---|---|
| Punto di Cottura | `hd/upgrade_cooking_point_crit.png` (`1254×1254`) | `generated/cooking_point_crit.png` (`128×128`) | `D3D6ECE6067D288831E531DA77047EA8324778E6E475E60773540DBDA743BAA6` | `451EA2A9C00E090D252FDAE509EB3CDF068823C3C781A71FB7C96BA0445723E6` |

## PS-094 — Placeholder icona per la nona Specialità (cariche multiple abilità attiva)

- Data integrazione: 7 settembre 2026.
- Contesto: [PS-094](../../../../docs/cards/3_in_sprint/PS-094-specialita-cariche-abilita-attiva.md)
  introduce una nona Specialità di Barb (cariche multiple sull'abilità
  attiva). Per contratto PS-090 questa card non produce icone: nome e icona
  definitivi restano materia della card `tipo: art` aperta in handoff
  ([PS-118](../../../../docs/cards/2_to_do/PS-118-nome-e-icona-nona-specialita-cariche-abilita.md)).
  Il gioco non deve però referenziare un'icona nulla nel frattempo.
- Origine: nessuna sintesi. Placeholder deterministico generato con
  `tools/generate-art-placeholder.ps1` (PS-110), stessa geometria
  `128×128` delle altre icone upgrade. Non è arte finale: il pixel `(0,0)`
  resta la firma magenta piena (`255,0,255,255`) finché PS-118 non sostituisce
  i byte del file.
- Trasformazione: `generate-art-placeholder.ps1 -OutputPath generated/ability_charge_stacking.png -Width 128 -Height 128 -Label 'PS-094'` (nessun master HD: non c'è nulla da derivare finché l'icona reale non esiste).
- Runtime: `data/upgrades/specialities/ability_charge_stacking.tres` referenzia
  già questo percorso `generated/`; PS-118 sostituirà solo i byte del file,
  nessun cambio di wiring.

| Carta | Master HD escluso | Derivato runtime | SHA-256 master | SHA-256 runtime |
|---|---|---|---|---|
| *(nome di lavoro, vedi PS-118)* — placeholder | — | `generated/ability_charge_stacking.png` (`128×128`) | — | `C1D862377E4F07F3ECD3C1EB98627245DC7FF041331659230595A3772CFB5818` |
