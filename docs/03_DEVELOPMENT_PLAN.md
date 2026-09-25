# TITANBOUND: Development Plan (Roblox Studio)

**Související:** [01_KONCEPT.md](01_KONCEPT.md) · [02_GDD.md](02_GDD.md) · [04_PHASE1_MOVEMENT.md](04_PHASE1_MOVEMENT.md)

Plán vede od prázdného repozitáře k launch verzi. Vertical slice (fáze 1–11) obsahuje **Hunter Citadel, Greenwild, Ashen Valley, 3 typy nepřátel, 1 minibosse, Ember Colosse, 2 zbraně, progression, crafting a první Titan Form**. Další obsah přijde až po „fun gate“ ve fázi 11.

---

## 0. Principy

1. **Vertical slice first.** Radši jeden dokonalý Titan než sedm průměrných.
2. **Fun gate.** Každá fáze končí playtestem. Pokud core (pohyb, souboj, Titan) není zábavný, **nepřidává se obsah**, opravuje se core.
3. **Server authority.** Klient předvídá kvůli odezvě, server rozhoduje o všem důležitém (damage, loot, měny, inventář, crafting, progres, odměny z bossů).
4. **Data-driven.** Ladění patří do `Shared/Config/*` (zbraně, nepřátelé, Titáni, loot, recepty), ne do kódu. Designér mění čísla, ne logiku.
5. **Výkon od prvního dne.** Budgety platí už pro prototypy (§3). Mobil je cílová platforma, ne dodatek.
6. **Jeden Script na stranu.** Server `Main.server.luau` a klient `Main.client.luau`, vše ostatní jsou ModuleScripty (Services/Controllers).

---

## 1. Nástroje a workflow

| Nástroj | Účel | Verze |
|---|---|---|
| **Rojo** | synchronizace kódu z gitu do Studia, build place souboru | 7.4.4 |
| **Rokit** | správce toolchainu (`rokit install` podle `rokit.toml`) | – |
| **luau-lsp** | type-checking (`--!strict` všude), VS Code extension | 1.70.0 |
| **selene** | lint | 0.28.0 |
| **StyLua** | formátování | 2.0.2 |
| **GitHub Actions** | CI: format, lint, build, strict type-check na každý PR | `.github/workflows/ci.yml` |

**Hybridní workflow:**
- **Kód** (`src/`) žije v gitu a do Studia se dostává přes Rojo (`rojo serve` a Rojo plugin).
- **Mapy, terén, meshe, animace, zvuky** žijí ve Studiu a publikují se jako verze place souborů nebo **Packages** (sdílené modely s verzováním). Asset ID se zapisují do `Shared/Config/Assets/*.luau`.
- **Větve:** `main` je vždy hratelný. Každá fáze nebo featura má vlastní větev a PR s CI.
- **Places v jednom Experience:** `Citadel` (start place: hub a prolog), `Wilds1` (Greenwild a Ashen Valley). Každý place má vlastní Rojo project soubor (`citadel.project.json`, `wilds1.project.json`), které sdílí `src/`.

---

## 2. Architektura

### 2.1 Struktura (aktuální stav + plán)

```
src/
├─ ReplicatedStorage/Shared/            (ModuleScripts dostupné serveru i klientovi)
│  ├─ Loader.luau                       ✅ boot Services/Controllers (Init → Start)
│  ├─ Config/                           ✅ MovementConfig, InputConfig, GraphicsConfig, WorldConfig, TimeTrialConfig
│  │                                    ⏳ Weapons/, Enemies.luau, Titans/, Loot.luau, Recipes.luau, SkillTrees.luau, Regions.luau, Economy.luau
│  ├─ Net/                              ✅ Remotes.luau (registr všech remotes), MovementProtocol.luau
│  │                                    ⏳ CombatProtocol.luau, Packets.luau (buffer serializace)
│  ├─ Util/                             ✅ Signal, Trove, MathUtil, Validate, RateLimiter, Freeze
│  ├─ Combat/                           ⏳ Hitbox.luau, AttackTypes.luau (sdílené výpočty)
│  └─ Data/                             ⏳ Schema.luau, Migrations.luau
├─ ServerScriptService/Server/
│  ├─ Main.server.luau                  ✅ jediný server Script
│  ├─ Services/                         ✅ CharacterService, MovementService, TimeTrialService, TestCourseService
│  │                                    ⏳ CombatService, AbilityService, EnemyService, TitanService, TitanFormService,
│  │                                       DataService, InventoryService, CraftingService, RewardService, QuestService,
│  │                                       ProgressionService, WorldEventService, SquadService, PlaceService
│  ├─ World/                            ✅ TestCourseBuilder
│  ├─ Enemies/                          ⏳ Brain.luau, AttackTokens.luau, Archetypes/*
│  └─ Titans/                           ⏳ TitanBase.luau, EmberColossus/*
└─ StarterPlayer/StarterPlayerScripts/Client/
   ├─ Main.client.luau                  ✅ jediný LocalScript
   ├─ Controllers/                      ✅ Input, Movement, Camera, Animation, VFX, Quality, UI
   │                                    ⏳ CombatController, EnemyController, TitanController, TitanFormController,
   │                                       AudioController, RegionController, PrologueController, SquadController
   ├─ Movement/                         ✅ MovementContext, GrappleTargeting, Abilities/{Dash, Slide, WallRun, WallJump, Mantle, Grapple, Launch}
   │                                    ⏳ Abilities/Climb.luau (PHASE 4)
   ├─ Combat/                           ⏳ ComboRunner.luau, HitStop.luau, LockOn.luau
   └─ UI/                               ✅ Theme, Create   ⏳ komponenty HUD, menu (React-lua ve PHASE 8)
```
✅ = hotovo v této větvi, ⏳ = plánováno.

### 2.2 Služby (server) a kontrolery (klient)

| Server Service | Odpovědnost | Fáze |
|---|---|---|
| CharacterService ✅ | collision group, CharacterReady signál, přístup k root/humanoid | 1 |
| MovementService ✅ | validace schopností, speed envelope, rubber-band, FX relay | 1 |
| TimeTrialService ✅ | časované tratě, checkpointy, reset plane | 1 |
| CombatService | útoky, hit validace s rewind, damage, poise, i-frames | 2 |
| AbilityService | schopnosti zbraní, ultimate, cooldowny | 2 |
| EnemyService | AI nepřátel, spawnery, attack tokens | 3 |
| TitanService | fáze, útoky, weak pointy, brnění, aréna | 4 |
| TitanFormService | Titan Energy, transformace, moveset formy | 4 |
| WorldEventService | režisér eventů, cross-server oznámení | 5, 7 |
| PlaceService | teleporty mezi places, reserved servers | 5 |
| DataService | ProfileStore, session locking, schema, migrace | 6 |
| InventoryService | předměty, vybavení, transmog | 6 |
| CraftingService | recepty, upgrady, infuze | 6 |
| RewardService | loot tabulky, bad-luck protection, assist odměny | 6 |
| QuestService | Mission Board, kontrakty, Rank Trials | 6 |
| ProgressionService | Hunter Rank, skill trees, unlock atributy | 6 |
| SquadService | party, pozvánky, revive, týmové schopnosti | 7 |

| Client Controller | Odpovědnost | Fáze |
|---|---|---|
| InputController ✅ | akce z klávesnice, gamepadu a touch, touch tlačítka | 1 |
| MovementController ✅ | stavový automat pohybu, predikce, reporty serveru | 1 |
| CameraController ✅ | FOV, roll, trauma shake (později lock-on, Titan kamera) | 1 |
| AnimationController ✅ | procedurální pózy (později authored animace) | 1 / 9 |
| VFXController ✅ | pooled efekty podle tieru kvality | 1 / 9 |
| QualityController ✅ | tier kvality, auto-downgrade podle FPS | 1 |
| UIController ✅ | HUD | 1 / 8 |
| CombatController | komba, predikce zásahů, hit stop, parry/dodge okna | 2 |
| EnemyController | interpolace nepřátel, telegraphy | 3 |
| TitanController | intro, proxy interpolace, boss UI | 4 |
| TitanFormController | cinematic transformace, kamera a vstupy formy | 4 |
| RegionController | lighting/ambience podle regionu | 5 |
| PrologueController | skriptovaný prolog | 5 |
| AudioController | hudba (stems), ambience, SFX pool | 9 |
| SquadController | UI party, pingy, revive | 7 |

### 2.3 Síť
- **Registr:** všechny remotes jsou v `Shared/Net/Remotes.luau` (DEFINITIONS). Server je vytvoří při bootu, klient na ně čeká.
- **Reliable** `RemoteEvent` pro herní stav, **`UnreliableRemoteEvent`** pro kosmetiku (FX relay, zásahy pro VFX).
- **Každý handler:** rate limit (`RateLimiter`), typová validace (`Validate`), relay jen z validovaných hodnot (nikdy nepřeposílat raw tabulky klienta).
- **Pozice nepřátel a Titánů:** `buffer` pakety 10–20 Hz (unreliable) a interpolace na klientovi.
- **Budget:** < 50 KB/s na hráče průměrně.

### 2.4 Co ověřuje server

| Oblast | Validace |
|---|---|
| Pohyb ✅ | obálka rychlosti podle validovaných schopností, cooldowny, stamina, unlocky, grapple cíl (tag + dosah) |
| Damage | útok existuje a zbraň je vybavená, combo timing, dosah přes historii pozic (rewind ≤ 250 ms), LOS. Damage počítá jen server. |
| Loot | generuje server, sebrání ověřuje vzdálenost a vlastníka, osobní loot |
| Měny a inventář | jen server mutuje profil, idempotentní transakce s ID |
| Crafting | recept existuje, materiály vlastněné, atomická transakce |
| Boss odměny | účast (dmg ≥ 3 % nebo assist akce) evidovaná serverem |
| Progres | Rank Trials vyhodnocuje server z vlastních dat (killy, časy, objevy) |

---

## 3. Výkonové budgety (platí od PHASE 1)

| Metrika | Mobil (mid) | PC |
|---|---|---|
| FPS | 60 (min 30 low-end) | 60+ |
| Klientská paměť | ≤ 1,2 GB | ≤ 2 GB |
| Instance v dosahu streamingu | ≤ 40 000 | ≤ 60 000 |
| Aktivní particle emitory v záběru | ≤ 25 | ≤ 60 |
| Server Heartbeat (AI + validace) | ≤ 8 ms / frame | – |
| Síť | ≤ 50 KB/s / hráč | – |
| Aktivní nepřátelé / server | ≤ 60 | – |

---

## 4. Fáze

Odhady platí pro tým 2–3 lidí (1–2 skriptéři, 1 artist/designer).

### PHASE 1: Movement Prototype ✅ *(implementováno v této větvi)*
| | |
|---|---|
| **Co vytvořit** | Sprint, dash, air dash, slide, wall run, wall jump, mantle, grapple (i na pohyblivé body), coyote time, přenos hybnosti (Launch). Stamina. Server validace. Greybox trať „Movement Lab“ s časovkou. HUD pro pohyb, touch ovládání, kamera (FOV, roll, shake), procedurální pózy, VFX s tiery kvality. |
| **Roblox objekty** | `LinearVelocity`, `AlignOrientation`, `Attachment` na HumanoidRootPart. `HingeConstraint` (rotující grapple rameno). CollectionService tagy `GrapplePoint`, `TimeTrialGate`, `TimeTrialSpawn`, `ResetPlane`. `Trail`, `Beam`, `ParticleEmitter`. `ScreenGui`, `BillboardGui`, `CanvasGroup`. PhysicsService collision group `Characters`. `UnreliableRemoteEvent`. Lighting: `Atmosphere`, `Bloom`, `ColorCorrection`, `SunRays`. Workspace `StreamingEnabled`. |
| **Luau soubory** | viz [04_PHASE1_MOVEMENT.md](04_PHASE1_MOVEMENT.md) (39 souborů) |
| **Propojení** | `InputController` → `MovementController` (stavový automat) → remote `MovementAction` → `MovementService` (validace) → atributy `MoveState`/`MoveSide` a `MovementFx` → ostatní klienti (`AnimationController`, `VFXController`). `CameraController`, `VFXController` a `UIController` poslouchají signály `MovementController`. |
| **Testování** | Movement Lab na čas (medaile), Studio *Test → Clients and Servers* (2–4 hráči, replikace póz a lan), Device Emulator (touch), síťová emulace (Studio Settings → Network → Incoming Replication Lag 0,1–0,25 s) bez falešných korekcí, exploit test (rychlost přes command bar klienta → musí přijít rubber-band). CI: StyLua, selene, strict luau-lsp, Rojo build. |
| **Hotovo, když** | Designér zajede Movement Lab pod Gold (42 s). Tester bez nápovědy řekne „pohyb je zábavný“. 30 min hraní se 150 ms lagem bez falešné korekce. 60 FPS na mid-range mobilu. |

### PHASE 2: Combat Prototype *(2–3 týdny)*
| | |
|---|---|
| **Co vytvořit** | Framework zbraní (data-driven), **Greatsword** a **Dual Blades**: light combo, heavy/charge, dash attack, air attack. Block, **parry** (0,15 s), **perfect dodge** (i-frames z dashe), lock-on (soft i hard), hit stop, knockback, poise/stagger/execution. Tréninkové figuríny s telegraphy (žlutá = parry, červená = uhni) a DPS metr. |
| **Roblox objekty** | Animace (`Animation`, `Animator`, `AnimationTrack` s markery pro hit okna), modely zbraní (Model a `RigidConstraint` k ruce), hitboxy přes `workspace:GetPartBoundsInBox`/`Shapecast`, `Highlight` pro telegraphy, zvuky zásahů. |
| **Luau soubory** | `Shared/Config/Weapons/Greatsword.luau`, `DualBlades.luau` (frame data, motion values) · `Shared/Combat/Hitbox.luau` · `Shared/Net/CombatProtocol.luau` · `Server/Services/CombatService.luau` · `Server/Services/AbilityService.luau` · `Server/Combat/PositionHistory.luau` (rewind) · `Client/Controllers/CombatController.luau` · `Client/Combat/ComboRunner.luau`, `HitStop.luau`, `LockOn.luau` |
| **Propojení** | `MovementController.ActionStarted("Dash")` otevře perfect-dodge okno v `CombatController`. Server bere čas dashe z `MovementService:GetLastActionTime` (i-frames). `CameraController:AddTrauma` a hit stop, `VFXController` jiskry. Remote `CombatAttack` (reliable), `CombatHit` (unreliable, VFX). |
| **Testování** | Parry trenér (skriptované údery v náhodném rytmu), měření oken ve frame datech, 150 ms lag test, exploit testy (útok na vzdálený cíl, falešné targetIds, spam remotu). |
| **Hotovo, když** | Blind test 5 hráčů hodnotí souboj ≥ 4/5 a „heavy útok působí těžce“. Parry a perfect dodge jsou spolehlivé při 150 ms. Server odmítne všechny exploit testy. |

### PHASE 3: Enemy AI *(2–3 týdny)*
| | |
|---|---|
| **Co vytvořit** | Server AI bez Humanoidu (stavový automat), **Skulker / Brute / Spitter** a regionální varianty (Thorn/Cinder, Mossback/Magma, Spore/Ember), **attack tokens** (max. 2 útočníci na hráče), aggro, pathfinding, elitní modifikátory, spawnery (Encounter Slots). **Miniboss Gravehorn** (charge, dupání, zaseknutí o sloup, weak point na páteři). |
| **Roblox objekty** | Rigy v `ServerStorage/Enemies` (`AnimationController` a `Animator`), `PathfindingService`, `PathfindingModifier`, tag `EncounterSlot`, Attachments pro weak pointy. |
| **Luau soubory** | `Shared/Config/Enemies.luau` · `Server/Services/EnemyService.luau` · `Server/Enemies/Brain.luau`, `AttackTokens.luau`, `Archetypes/Skulker.luau`, `Brute.luau`, `Spitter.luau`, `Gravehorn.luau` · `Shared/Net/Packets.luau` (buffer) · `Client/Controllers/EnemyController.luau` |
| **Propojení** | Útoky nepřátel vyhodnocuje `CombatService` (stejná damage pipeline). Telegraphy jdou přes `EnemyController` a `VFXController`. Pozice se posílají unreliable pakety 10–20 Hz. |
| **Testování** | Aréna se spawnerem, stress test 60 nepřátel (MicroProfiler, heartbeat budget), férovost telegraphů (min. wind-up podle GDD §4.3). |
| **Hotovo, když** | Každý archetyp učí svou mechaniku. 60 nepřátel stojí ≤ 25 % serverového budgetu. Gravehorn nejde porazit bez využití sloupů nebo weak pointu. |

### PHASE 4: First Titan: Ember Colossus *(4–6 týdnů)*
| | |
|---|---|
| **Co vytvořit** | **Nejdřív technický spike:** šplhání po pohyblivém Titánovi (kolizní proxy v lokálním prostoru a Titan Grapple kotvy). Pak TitanService (3 fáze, časová osa útoků, HP weak pointů, lámání brnění), aréna (stoupající láva, gejzíry, harpuny, tavitelné pilíře), intro (8 s / 2 s), **Climb** schopnost, **Ember Titan Form** (Titan Energy, transformace, 5 útoků, kamera). |
| **Roblox objekty** | Titan jako skinned `MeshPart` s `Bone`s a animacemi, **neviditelné proxy Party** (tag `TitanClimbable`) aktualizované přes `workspace:BulkMoveTo`, kotvy (tag `TitanAnchor` + `GrapplePoint`), `Model.ModelStreamingMode = Persistent`, `Terrain` láva s `Part`y pro stoupající hladinu. |
| **Luau soubory** | `Shared/Config/Titans/EmberColossus.luau` · `Server/Services/TitanService.luau`, `TitanFormService.luau` · `Server/Titans/TitanBase.luau`, `EmberColossus/init.luau`, `EmberColossus/Attacks.luau`, `EmberColossus/Arena.luau` · `Client/Movement/Abilities/Climb.luau` · `Client/Controllers/TitanController.luau`, `TitanFormController.luau` |
| **Propojení** | Grapple už umí pohyblivé cíle (PHASE 1). Climb je nová schopnost ve stavovém automatu. `MovementService` dostane pravidla pro Climb (validace vzdálenosti od proxy). Damage do weak pointů jde přes `CombatService`. Titan Energy plní `CombatService` (parry, dodge, weak point). |
| **Testování** | Solo a 4 hráči, šplhání při 150 ms, výkon (proxy ≤ 60 Partů), designérské „exploit hledání“ (dá se Titan zabít od nohy? nesmí). |
| **Hotovo, když** | Fight trvá 8–12 min pro 4 hráče. Každá fáze vyžaduje pohyb a šplhání. Titan Form hodnotí testeři jako „wow moment“. Žádná degenerovaná strategie. |

### PHASE 5: First World *(4–6 týdnů)*
| | |
|---|---|
| **Co vytvořit** | **Prolog** „Pád Kessrinu“ (30–45 s), **Hunter Citadel** (greybox pak art), **Greenwild** a **Ashen Valley** (zóny podle konceptu §8), Encounter a Event Sloty, tajemství (jeskyně, puzzle se sochami, Glimmerfox), Waystones (fast travel), základní **WorldEventService** (Titan Detected, Meteor Storm), teleport Citadel ↔ Wilds1. |
| **Roblox objekty** | `Terrain` a `MaterialVariant`, `Atmosphere`/`ColorCorrection` per region (klientské prolínání), `Model.LevelOfDetail = StreamingMesh` pro vzdálené stavby, `TeleportService` a `TeleportOptions`, `ProximityPrompt` (interakce), `Sound` ambience. |
| **Luau soubory** | `Shared/Config/Regions.luau` · `Server/Services/PlaceService.luau`, `WorldEventService.luau` · `Server/World/EncounterDirector.luau`, `Secrets.luau` · `Client/Controllers/RegionController.luau`, `PrologueController.luau` |
| **Propojení** | Encounter Sloty spouští `EnemyService`. Eventy oznamuje UI banner. Prolog po dokončení zapíše `PrologueComplete` (v PHASE 6 do DataService, do té doby atribut). |
| **Testování** | „Prvních 10 minut“ podle konceptu §3 se stopkami. Heatmapa odboček (analytika). Pravidlo 3 minut na trasách. Streaming na mobilu. |
| **Hotovo, když** | Nový hráč projde prolog → Citadela → Greenwild → Gravehorn bez pomoci. Každá trasa splní pravidlo 3 minut. |

### PHASE 6: Progression *(3–4 týdny)*
| | |
|---|---|
| **Co vytvořit** | **DataService** (ProfileStore: session locking, schema a migrace), InventoryService, **CraftingService** (Ember recepty, Resonance upgrady), **RewardService** (loot tabulky, bad-luck protection, osobní loot), **QuestService** (Mission Board, kontrakty), **ProgressionService** (Hunter Rank E → C ve slice, Rank Trials, Movement a Weapon skill trees). Air Dash přejde z `DefaultUnlocks` do Movement stromu. |
| **Roblox objekty** | `DataStoreService` (přes ProfileStore z Wally), `MemoryStoreService` (bad-luck countery), `AnalyticsService` (economy events). |
| **Luau soubory** | `Shared/Data/Schema.luau`, `Migrations.luau` · `Shared/Config/Loot.luau`, `Recipes.luau`, `SkillTrees.luau`, `Quests.luau`, `Economy.luau` · `Server/Services/DataService.luau`, `InventoryService.luau`, `CraftingService.luau`, `RewardService.luau`, `QuestService.luau`, `ProgressionService.luau` |
| **Propojení** | `ProgressionService` nastavuje atributy `Unlock_*` (čte je MovementService i klient). Odměny z Titánů jdou přes `RewardService` s ID odměny (idempotence). |
| **Testování** | Rejoin a teleport uprostřed craftu (žádné dupy), stress test ukládání, migrace starých profilů, audit ekonomiky. |
| **Hotovo, když** | Nulové dupy v stress testech. Data přežijí teleport i pád serveru. Hráč pochopí Forge bez návodu. |

### PHASE 7: Multiplayer *(3 týdny)*
| | |
|---|---|
| **Co vytvořit** | **SquadService** (1–6 hráčů, pozvánky, společný teleport, soukromé výpravy přes `ReserveServer`), **revive** (downed 30 s, hold 3 s), týmové schopnosti (**Link Strike**, Hunter's Oath), **assist odměny**, škálování Titána `HP × (1 + 0,65 × (n − 1))`, quick-ping systém, cross-server eventy (`MessagingService`), anti-cheat hardening (fly/noclip detekce navazuje na MovementService). |
| **Luau soubory** | `Server/Services/SquadService.luau`, `ReviveService.luau` · `Client/Controllers/SquadController.luau`, `PingController.luau` |
| **Testování** | 6hráčové squady na Titánovi, teleport úspěšnost, spravedlnost odměn (logy), 20 hráčů na serveru při world eventu. |
| **Hotovo, když** | Teleport je úspěšný v > 99 % případů. Assist odměny fungují (support hráč dostane plný loot). 20 hráčů na eventu ≥ 45 FPS na mobilu. |

### PHASE 8: UI *(3 týdny)*
| | |
|---|---|
| **Co vytvořit** | Plný HUD (HP, stamina, **Titan Energy**, schopnosti, cíl, tým, **dynamický boss HUD**), menu (inventář s 3D náhledem, Forge, mapa s fog-of-war, Codex, nastavení), přístupnost (barvoslepost, shake slider, titulky, UI scale), **editor rozložení tlačítek na mobilu**, lokalizace (`LocalizationTable`: EN, CS, a dál ES, PT, DE). |
| **Roblox objekty** | `ScreenGui`, `ViewportFrame`, `CanvasGroup`, `UIGradient`, `LocalizationTable`, `GuiService` (gamepad navigace). |
| **Luau soubory** | Doporučení: **React-lua** (Wally balíček `jsdotlua/react`) pro menu, stávající kód-built HUD pro výkonově kritické prvky. `Client/UI/Components/*`, `Client/UI/Screens/*`, `Client/Controllers/UIController.luau` (rozšíření). |
| **Testování** | Gamepad-only a touch-only průchod všemi menu, UI render čas < 1 ms, čitelnost na 5" telefonu. |
| **Hotovo, když** | Všechny flows jdou projít na telefonu, gamepadu i PC. HUD při boss fightu nepřekáží. |

### PHASE 9: VFX + Audio *(3–4 týdny)*
| | |
|---|---|
| **Co vytvořit** | Authored animace (nahradí procedurální pózy tam, kde je to lepší), knihovna VFX (3 vrstvy, pooling), **destrukce** (pre-fractured modely a pool úlomků), lighting pass regionů, **AudioController** (nové Audio API: `AudioPlayer`, `AudioEmitter`, `AudioFader`, bus mix), dynamická hudba Titánů (stems podle fáze), ambience, UI zvuky, hooky pro kosmetické efekty (Transformation Effect, trails). |
| **Luau soubory** | `Shared/Config/Assets/Sounds.luau`, `Animations.luau`, `Vfx.luau` · `Client/Controllers/AudioController.luau` · `Client/Vfx/*` (efekty) · `Server/Services/DestructionService.luau` (jen herní destrukce) |
| **Testování** | Každá akce má vizuální i zvukovou odezvu (checklist), budgety tierů (Low/Med/High/Ultra) na reálných zařízeních. |
| **Hotovo, když** | Blind test: „silný útok působí silně“ ≥ 4,5/5. Low tier drží 60 FPS na low-end zařízení. |

### PHASE 10: Optimization *(2 týdny)*
| | |
|---|---|
| **Co vytvořit** | Profilace (MicroProfiler, ScriptProfiler, Developer Console → Memory), ladění streamingu (`StreamingMinRadius`/`TargetRadius`, Atomic/Persistent modely), LOD (`Model.LevelOfDetail`), audit počtu instancí, síťový audit (bandwidth per remote), server heartbeat budget, pooling všude. |
| **Testování** | Device lab: low-end Android (3 GB), iPhone 11, Xbox, slabé PC. 30min soak test (úniky paměti). |
| **Hotovo, když** | Všechny budgety z §3 splněné na všech cílových zařízeních. |

### PHASE 11: Playtesting *(3–4 týdny, iterativně)*
| | |
|---|---|
| **Co vytvořit** | Uzavřená alfa (skupina a pozvánky), telemetrie (`AnalyticsService` funnels z GDD §25), dotazníky, balanc (TTK, obtížnost Titána, ekonomika), bug triage, review přístupnosti. |
| **Fun gate** | Pokud slice nesplní KPI (například D1 < 35 %, dokončení Gravehorna < 60 %), **opravuje se core a nepřidává obsah.** |
| **Hotovo, když** | KPI z GDD §25 splněná ve dvou po sobě jdoucích testech. |

### PHASE 12: Launch Version *(2–3 týdny)*
| | |
|---|---|
| **Co vytvořit** | Monetizace (kosmetický shop, první Hunter Pass, transformation effects), store page (ikona a thumbnaily z Higgsfield konceptů převedené na finální rendery, A/B test), Experience Questionnaire (content maturity), lokalizace, moderace (TextChatService filtry), live-ops kalendář první sezóny, dashboardy, **rollback plán** (verzované places). |
| **Testování** | Nákupy v testovacím režimu, kontrola, že monetizace nedává výhodu (review podle GDD §19), release checklist. |
| **Hotovo, když** | Veřejné spuštění, crash-free sessions > 99 %, první sezóna naplánovaná. |

---

## 5. Harmonogram (orientační)

```
Týden:  1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27  28
P1      ██                                                                                                         ✅
P2          ███████
P3                 ███████
P4                        ████████████████
P5                                        ████████████████
P6                                                        ████████████
P7                                                                    █████████
P8                                                                              █████████
P9                                                                                        ████████████
P10                                                                                                   ██████
P11                                                                                                         ████████████ (paralelně od P5)
P12                                                                                                                     ███████
```
Zhruba **6–7 měsíců** do launch verze vertical slice pro malý tým. Sezóna 1 (Storm Archipelago) začíná vývoj během PHASE 11–12.

---

## 6. Definition of Done pro každý PR
- [ ] CI zelené (StyLua, selene, strict luau-lsp, Rojo build)
- [ ] Žádné `TODO`/placeholdery v kódu
- [ ] Každý nový remote je v `Remotes.luau`, je rate-limitovaný a validuje argumenty
- [ ] Ladění je v `Shared/Config`, ne v kódu
- [ ] Otestováno ve Studiu *Clients and Servers* (min. 2 hráči) a v Device Emulatoru (telefon)
- [ ] Budgety z §3 nepřekročené
