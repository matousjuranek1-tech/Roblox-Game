# PHASE 1: Movement Prototype

**Stav:** implementováno · **Cíl:** pohyb, který baví sám o sobě a je připravený na souboj (PHASE 2) i Titány (PHASE 4).

---

## 1. Spuštění

### Varianta A: postavit place (nejrychlejší)
```bash
rokit install                                   # rojo, selene, stylua, luau-lsp, lune
rojo build default.project.json -o Titanbound.rbxlx
```
Otevři `Titanbound.rbxlx` v Roblox Studiu a stiskni **Play** (F5).

### Varianta B: živá synchronizace (vývoj)
1. Nainstaluj Rojo plugin do Studia (verze 7.4.x).
2. V terminálu spusť `rojo serve`.
3. Ve Studiu otevři **prázdný place** (ne šablonu *Baseplate*, jejíž SpawnLocation by kolidoval s Labem), v Rojo pluginu klikni **Connect** a pak **Play**.

### Nastavení Experience (jednorázově)
- **Game Settings → Avatar → Avatar Type: R15.** Procedurální pózy (včetně slidu pod překážkami) počítají s R15.
- Doporučeno: **Game Settings → Avatar → Scale** na výchozí hodnoty (měřítko trati je navržené pro standardní postavu).

Server při startu postaví **Movement Lab** (200 studů nad počátkem). Vypnout ho jde atributem `DisableMovementLab = true` na Workspace.

---

## 2. Ovládání

| Akce | Klávesnice | Gamepad | Dotyk |
|---|---|---|---|
| Pohyb | WASD | levá páčka | joystick |
| Skok / wall jump / coyote jump | Space | A | Jump |
| Sprint | Shift (držet) | L3 (přepínač) | SPRINT (přepínač) |
| Dash (ve vzduchu air dash) | Q | B | DASH |
| Slide (ve sprintu) | C / Ctrl | R3 | SLIDE |
| Grapple (na zaměřený bod) | E | LB | HOOK |
| Wall run | automaticky: skoč podél stěny se sprintem | | |
| Mantle | automaticky: skoč k hraně a drž směr | | |
| Restart časovky | R | D-pad dolů | – |
| Nápověda / debug | H / F3 | D-pad nahoru / – | – |

---

## 3. Soubory

Rojo mapování: `*.server.luau` = **Script**, `*.client.luau` = **LocalScript**, `*.luau` = **ModuleScript**, složka = **Folder**.

### Sdílené: `ReplicatedStorage.Shared`
| Soubor | Typ | Účel |
|---|---|---|
| `src/ReplicatedStorage/Shared/Loader.luau` | ModuleScript | Boot služeb a kontrolerů (Init → Start) |
| `src/ReplicatedStorage/Shared/Config/MovementConfig.luau` | ModuleScript | **Veškeré ladění pohybu** a server validace |
| `src/ReplicatedStorage/Shared/Config/InputConfig.luau` | ModuleScript | Bindingy (klávesnice, gamepad, touch) |
| `src/ReplicatedStorage/Shared/Config/GraphicsConfig.luau` | ModuleScript | VFX budgety pro Low/Medium/High/Ultra |
| `src/ReplicatedStorage/Shared/Config/WorldConfig.luau` | ModuleScript | Tagy, atributy, collision groups |
| `src/ReplicatedStorage/Shared/Config/TimeTrialConfig.luau` | ModuleScript | Medailové časy tratí |
| `src/ReplicatedStorage/Shared/Net/Remotes.luau` | ModuleScript | Registr všech remotes |
| `src/ReplicatedStorage/Shared/Net/MovementProtocol.luau` | ModuleScript | Kontrakt klient ↔ server pro pohyb |
| `src/ReplicatedStorage/Shared/Util/Signal.luau` | ModuleScript | Typované lokální eventy |
| `src/ReplicatedStorage/Shared/Util/Trove.luau` | ModuleScript | Úklid připojení a instancí |
| `src/ReplicatedStorage/Shared/Util/MathUtil.luau` | ModuleScript | Frame-rate nezávislé vyhlazování, vektorové pomůcky |
| `src/ReplicatedStorage/Shared/Util/Validate.luau` | ModuleScript | Validace síťových dat (NaN, inf, instance) |
| `src/ReplicatedStorage/Shared/Util/RateLimiter.luau` | ModuleScript | Token bucket pro remotes |
| `src/ReplicatedStorage/Shared/Util/Freeze.luau` | ModuleScript | Hluboké zmrazení configů |

### Server: `ServerScriptService.Server`
| Soubor | Typ | Účel |
|---|---|---|
| `src/ServerScriptService/Server/Main.server.luau` | Script | Jediný server script: remotes a boot služeb |
| `src/ServerScriptService/Server/Services/CharacterService.luau` | ModuleScript | Collision group `Characters`, signál CharacterReady |
| `src/ServerScriptService/Server/Services/MovementService.luau` | ModuleScript | **Anti-exploit:** validace schopností, speed envelope, rubber-band, FX relay |
| `src/ServerScriptService/Server/Services/TimeTrialService.luau` | ModuleScript | Časovky, checkpointy, reset plane |
| `src/ServerScriptService/Server/Services/TestCourseService.luau` | ModuleScript | Postaví Movement Lab |
| `src/ServerScriptService/Server/World/TestCourseBuilder.luau` | ModuleScript | Geometrie Movement Labu |

### Klient: `StarterPlayer.StarterPlayerScripts.Client`
| Soubor | Typ | Účel |
|---|---|---|
| `…/Client/Main.client.luau` | LocalScript | Jediný klientský script: boot kontrolerů |
| `…/Client/Controllers/InputController.luau` | ModuleScript | Akce ze vstupů, touch tlačítka |
| `…/Client/Controllers/MovementController.luau` | ModuleScript | **Stavový automat pohybu** |
| `…/Client/Controllers/CameraController.luau` | ModuleScript | FOV, roll, trauma shake |
| `…/Client/Controllers/AnimationController.luau` | ModuleScript | Procedurální pózy (lokální i vzdálení hráči) |
| `…/Client/Controllers/VFXController.luau` | ModuleScript | Trail, prach, lano (pooled, podle tieru) |
| `…/Client/Controllers/QualityController.luau` | ModuleScript | Tier kvality a auto-downgrade podle FPS |
| `…/Client/Controllers/UIController.luau` | ModuleScript | HUD: stamina, pipy, zaměřovač, časovka, nápověda, debug |
| `…/Client/Movement/MovementContext.luau` | ModuleScript | Stav postavy, LinearVelocity „mover“, raycast helpery |
| `…/Client/Movement/GrappleTargeting.luau` | ModuleScript | Auto-targeting grapple bodů |
| `…/Client/Movement/Abilities/Dash.luau` | ModuleScript | Dash a air dash |
| `…/Client/Movement/Abilities/Slide.luau` | ModuleScript | Slide (svah, headroom, slide-hop) |
| `…/Client/Movement/Abilities/WallRun.luau` | ModuleScript | Wall run |
| `…/Client/Movement/Abilities/WallJump.luau` | ModuleScript | Wall jump (impuls) |
| `…/Client/Movement/Abilities/Mantle.luau` | ModuleScript | Mantle (výšvih na hranu) |
| `…/Client/Movement/Abilities/Grapple.luau` | ModuleScript | Grapple (i pohyblivé cíle) |
| `…/Client/Movement/Abilities/Launch.luau` | ModuleScript | Přenos hybnosti ve vzduchu |
| `…/Client/UI/Theme.luau` | ModuleScript | Barvy a fonty |
| `…/Client/UI/Create.luau` | ModuleScript | Deklarativní tvorba UI |

### Mimo hru
| Soubor | Účel |
|---|---|
| `default.project.json` | Rojo projekt včetně Lighting (Future, Atmosphere, Bloom, ColorCorrection, SunRays), StreamingEnabled a StarterPlayer nastavení |
| `tests/smoke.luau` | Runtime smoke testy v Lune (moduly, utility, geometrie Labu) |
| `.github/workflows/ci.yml` | CI: StyLua, selene, strict luau-lsp, Rojo build, smoke testy |

---

## 4. Jak to do sebe zapadá

```
 Klient                                                              Server
 ───────────────────────────────────────────────────────────────     ─────────────────────────────────────
 InputController ──ActionBegan / JumpRequested──► MovementController
                                                   │  PreSimulation: ground → stamina → sprint →
                                                   │  ability.Update → auto (Mantle, WallRun) → grapple target
                                                   │
                                                   ├─ MovementAction("Start"/"End", action, payload) ──► MovementService
                                                   │                                                      │ rate limit, cooldown,
                                                   │                                                      │ stamina, unlock, payload
                                                   │ ◄── MovementCorrection("Rejected"/"Corrected") ──────┤ speed envelope 5 Hz
                                                   │                                                      │
                                                   ├─ signals ─► CameraController (FOV, roll, shake)      ├─ Character attributes
                                                   ├─ signals ─► VFXController (trail, dust, rope)        │  MoveState / MoveSide ──► ostatní klienti
                                                   ├─ snapshot ► AnimationController (pózy)               └─ MovementFx (unreliable) ──► VFX ostatních
                                                   └─ snapshot ► UIController (HUD)
 UIController ── TimeTrial("Restart") ─────────────────────────────────────────────────────────────►  TimeTrialService
              ◄─ TimeTrial("Started"/"Checkpoint"/"Finished"/"Reset"/"Cancelled") ─────────────────  (segment raycast gatů)
```

**Fyzikální model:** Humanoid dělá chůzi, schody, svahy a skok. Schopnosti přebírají řízení jedním `LinearVelocity` na HumanoidRootPart:
- *Vector mode* (všechny osy): wall run, grapple, mantle, air dash,
- *Plane mode* (jen X/Z, gravitace zůstává): dash, slide, Launch.

`AlignOrientation` natáčí postavu, když je `Humanoid.AutoRotate` vypnuté. Obě omezení vytváří klient, takže existují jen u vlastníka postavy.

**Předávání stavu:** každá schopnost vrací ze `Stop()` volitelné navazující akce. Například wall run → wall jump → **Launch** (hybnost) → grapple → Launch. Díky tomu je řetězení vždy rychlejší než běh.

**Validace na serveru (shrnutí):**
- Každý serverový teleport (spawn, korekce, checkpoint) validaci **ukotví** na cílové pozici. V „settle“ okně (0,6 s) se přijímají jen pozice dosažitelné z kotvy a nic z tohoto okna se nestane cílem rubber-bandu.
- Vzorek bez pohybu (stání nebo výpadek replikace) neposouvá základnu. Další pohyb se změří přes celou mezeru (max. 1,5 s), takže Wi-Fi zakolísání nevypadá jako speed hack.
- Trvalé akce (slide, wall run, grapple) se uzavřou na „End“, na další Start, nebo po své nejdelší poctivé délce. Uzavření zkrátí povolení na launch okno a naúčtuje staminu wall runu.
- Na klientu reagují wall jump, uvolnění grapplu a slide-hop jen na **čerstvý stisk** skoku (podržený skok je neopakuje).

**Připravenost na další fáze:**
- `MovementController.ActionStarted("Dash")` je hook pro **perfect dodge** (PHASE 2). Server má `MovementService:GetLastActionTime(player, "Dash")` pro i-frames.
- Grapple čte pozici cíle každý frame, takže funguje na **pohyblivých kotvách Titána** (PHASE 4). Rotující rameno v Labu to ověřuje.
- `CameraController:AddTrauma()` / `:Kick()` použije souboj i Titáni.

---

## 5. Testování

### 5.1 Automaticky (CI a lokálně)
```bash
stylua --check src tests
selene src
rojo build default.project.json -o Titanbound.rbxlx
rojo sourcemap default.project.json -o sourcemap.json
luau-lsp analyze --platform=roblox --sourcemap=sourcemap.json --definitions=globalTypes.d.luau src
lune run tests/smoke.luau Titanbound.rbxlx
```
`globalTypes.d.luau` se stahuje z tagu luau-lsp (viz CI). Smoke testy ověřují 179 podmínek: načtení všech modulů, chování utilit a geometrii Labu (pořadí a směr gatů, podlahy pod checkpointy, výšku mezery u slide bariér, návaznost rampy).

### 5.2 Ručně ve Studiu (checklist)
| # | Test | Očekávání |
|---|---|---|
| 1 | Sprint po sprint strip | FOV plynule roste, postava se naklání v zatáčkách |
| 2 | Mezery 10 / 14 / 18 | 10 a 14 sprint-skokem, 18 jen s dashem nebo air dashem |
| 3 | Slide pod žlutými bariérami | Bez slidu neprojdeš. Slide projede a sám pokračuje, dokud nad hlavou není místo. |
| 4 | Rampa | Slide dolů zrychluje (debug SPEED až ~70) |
| 5 | Mantle schody +6 / +10 / +12 | +12 jen skokem těsně u hrany s držením dopředu |
| 6 | Stěny A → B → C | Wall run, Space = wall jump na protější stěnu, kamera se naklání od stěny |
| 7 | Komín | Střídavé wall jumpy, nahoře mantle. Na jedné stěně opakovaně nejde. |
| 8 | Grapple chasm | Zaměřovač skáče na nejlepší bod, lano vystřelí, tah zrychluje, po doletu výskok. Rotující rameno jde chytit. |
| 9 | Pád do propasti | Návrat na poslední checkpoint (toast „Back to checkpoint“) |
| 10 | Časovka | Start → 5 checkpointů → cíl, medaile a osobní rekord. R restartuje. |
| 11 | **Multiplayer** (Test → Clients and Servers, 2–3 hráči) | Ostatní vidí lano, trail, prach a pózy (slide, wall run, grapple) |
| 12 | **Mobil** (Device Emulator, telefon) | Tlačítka SPRINT/DASH/SLIDE/HOOK kolem skoku, HUD čitelný |
| 13 | **Gamepad** | Bindingy z tabulky, nápověda se přepne na gamepad |
| 14 | **Lag** (Studio Settings → Network → Incoming Replication Lag 0,15–0,25) | Žádné falešné korekce při celé trati |
| 15 | **Exploit:** v klientském command baru `game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 150` | Server do 0,6 s vrátí postavu zpět a v Output je `[MovementService] … corrected` |
| 16 | **Výkon** (MicroProfiler, Ctrl+F6) | Movement a VFX pod 0,5 ms na frame |

### 5.3 Ladění pocitu
| Chci… | Uprav v `MovementConfig` |
|---|---|
| svižnější dash | `Dash.Speed` ↑, `Dash.Duration` ↓ (drž vzdálenost ≈ 14 studů) |
| delší slidy | `Slide.Friction` ↓, `Slide.MaxDuration` ↑ |
| „lepivější“ wall run | `WallRun.Gravity` ↓, `WallRun.MaxDuration` ↑ |
| víc vzdušné kontroly | `Launch.AirTurnRate` ↑, `Launch.Decay` ↓ |
| agresivnější grapple | `Grapple.PullSpeed`, `Grapple.PullAcceleration` ↑, `Grapple.Cooldown` ↓ |
| méně/více staminy | `Stamina.RegenPerSecond`, `Stamina.RegenDelay` a náklady schopností |

Server validace čte stejný config, takže po zrychlení schopnosti se automaticky rozšíří i povolená obálka rychlosti.

---

## 6. Známá omezení (vědomě odložená)
| Omezení | Kdy se řeší |
|---|---|
| Pózy jsou procedurální (bez autorských animací) | PHASE 9 (AnimationController zůstane jako vrstva) |
| Pohyb zatím nemá zvuky | PHASE 9 (AudioController) |
| Air Dash je odemčený pro všechny (`DefaultUnlocks`) | PHASE 6 (Movement skill tree) |
| Server stamina pro wall run se odečítá až při uzavření běhu („End“ nebo vypršení) | stačí pro anti-exploit. Plná simulace není potřeba. |
| Upravený klient, který opakovaně posílá Start slidu, udrží na zemi až ~68 studs/s (StartSpeed × 1,25 + 8). Slide vyžaduje zem a pohyb a MaxSpeed povolí jen při sjezdu. | PHASE 7: integrátor „distance budget“ (povolená vzdálenost za okno místo okamžité rychlosti) |
| Detekce „vznášení“ (fly hack bez horizontální rychlosti) | PHASE 7 (anti-cheat hardening) |
| Pózy předpokládají R15 | R15 je povinné nastavení Experience |
