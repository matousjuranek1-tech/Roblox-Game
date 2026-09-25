# TITANBOUND: Game Design Document

**Verze:** 0.1 (pre-production) · **Stav:** vertical slice v přípravě, PHASE 1 (movement) implementována
**Související:** [01_KONCEPT.md](01_KONCEPT.md) · [03_DEVELOPMENT_PLAN.md](03_DEVELOPMENT_PLAN.md) · [ART.md](ART.md)

> Tento dokument je **živý**. Každá sekce má vlastníka (role v závorce) a mění se podle playtestů. Čísla jsou *výchozí ladění*, ne dogma.

## Obsah
1. [Vize a pilíře](#1-vize-a-pilíře)
2. [Svět a regiony](#2-svět-a-regiony)
3. [Movement](#3-movement-lead-game-designer)
4. [Combat](#4-combat-combat-designer)
5. [Zbraně](#5-zbraně-combat-designer)
6. [Titáni](#6-titáni-lead-game-designer--creative-director)
7. [Titan Climbing](#7-titan-climbing)
8. [Titan Form](#8-titan-form)
9. [Nepřátelé a AI](#9-nepřátelé-a-ai)
10. [Exploration](#10-exploration)
11. [World Events](#11-world-events-live-ops-designer)
12. [Destructible Environment](#12-destructible-environment)
13. [Progression](#13-progression)
14. [Crafting, loot a rarity](#14-crafting-loot-a-rarity-economy-designer)
15. [Ekonomika](#15-ekonomika-economy-designer)
16. [Multiplayer](#16-multiplayer-multiplayer-systems-designer)
17. [Social Hub: Hunter Citadel](#17-social-hub-hunter-citadel)
18. [Customizace a skiny](#18-customizace-a-skiny-character-designer)
19. [Monetizace](#19-monetizace)
20. [UI/UX](#20-uiux-uiux-designer)
21. [Boss intro](#21-boss-intro)
22. [Audio](#22-audio-sound-designer)
23. [Grafika a výkon](#23-grafika-a-výkon-performance-engineer)
24. [Live-ops](#24-live-ops)
25. [Analytika a KPI](#25-analytika-a-kpi)
26. [Rizika](#26-rizika-a-mitigace)

---

## 1. Vize a pilíře

**Vize:** nejlepší „lovecká“ hra na Robloxu. Bossové velcí jako hory, pohyb, který baví sám o sobě, a proměna v Titána jako vrchol každého lovu.

| Pilíř | Znamená | Neznamená |
|---|---|---|
| **Měřítko** | Titáni jsou vidět z dálky a mění prostředí. | Víc polygonů. Měřítko prodává silueta, atmosféra, zvuk a kamera. |
| **Mistrovství** | Timing, pozice, pohyb. | Stat-check bossové. |
| **Proměna** | Hráč roste od bezmocného po Titána. | Neustálé transformace (ztratily by kouzlo). |
| **Společně** | Záchrany, koordinace, sdílené odměny. | Vynucené role (tank/healer). |

**USP oproti jiným Roblox hrám:** (1) Titáni se šplháním a weak pointy, (2) Titan Form s úplně jiným movesetem, (3) movement na úrovni moderních AAA akcí, (4) world eventy, které spojí celý server.

**Obsahová sazba:** Roblox *Content Maturity: Mild* (fantasy násilí). Žádná krev: nepřátelé se rozpadají v jiskry, popel, listí nebo krystaly.

---

## 2. Svět a regiony

Lore je v [01_KONCEPT.md §0](01_KONCEPT.md#vlastní-ip-svět-lore-a-proč-dává-smysl-titan-form). Svět tvoří *Rozervané země*. Úlomek Srdcehvězdy v každém Titánovi je jeho jádro.

| # | Region | Rank | Titan | Atmosféra | Unikátní mechanika regionu | Fáze obsahu |
|---|---|---|---|---|---|---|
| 1 | **Hunter Citadel** | – | (Athrax, mrtvý) | zlatá hodina, kosti, výhně | Social hub | Vertical slice |
| 2 | **Greenwild** | E–D | Forest Guardian *(Heartwood update)* | smaragdový les, ruiny | Kořenový parkour, puzzle ruiny | Vertical slice |
| 3 | **Ashen Valley** | D–C | **Ember Colossus** | popel, láva, obsidián | Heat hazard, gejzíry, krátery kroků | Vertical slice |
| 4 | **Storm Archipelago** | C–B | Storm Wyrm | plovoucí ostrovy v bouři | Větrné proudy (gliding), bleskové tyče | Sezóna 1 |
| 5 | **Frozen Crown** | B | Frost Behemoth | ledové hory, vánice | **Chlad**: stání na místě mrazí, hřejí braziery | Sezóna 2 |
| 6 | **Sunken Kingdom** | B–A | Abyss Leviathan | zatopené ruiny, bioluminiscence | Příliv a odliv mění mapu, podvodní úseky | Sezóna 3 |
| 7 | **Titan Graveyard** | A–S | *Echo Titáni* | kostry dávných Titánů | Echo Hunts (remixy Titánů s modifikátory) | Sezóna 4 |
| 8 | **Void Frontier** | S–SS | Void Reaper | rozbitá realita | Změny gravitace, portály, zrcadlení | Sezóna 5 |
| 9 | **Celestial Kingdom** | SS–TITAN | Celestial Titan *(world boss)* | nad mraky, zlato, pastely | Celestial Eclipse event | Sezóna 6 |

**Pravidlo odlišnosti:** každý region musí mít jinou **paletu**, **zvukovou kulisu**, **traversal mechaniku** a **hazard**. Pokud se region dá popsat jako „předchozí region v jiné barvě“, design neprošel.

---

## 3. Movement *(Lead Game Designer)*

Implementace: [04_PHASE1_MOVEMENT.md](04_PHASE1_MOVEMENT.md). Veškeré ladění je v `src/ReplicatedStorage/Shared/Config/MovementConfig.luau`.

### 3.1 Stavy pohybu
`Idle/Run` (Humanoid) · `Sprint` (flag) · `Dash` · `AirDash` · `Slide` · `WallRun` · `Mantle` · `Grapple` · `Launch` (přenos hybnosti po odrazu) · *(PHASE 4)* `Climb`, `TitanGrapple` · *(PHASE 2)* `Attack`, `Block`, `Staggered`.

### 3.2 Přechody (povolené)
```
Run/Sprint ──► Dash, Slide(jen sprint), Grapple, Mantle(skok k hraně)
Air ─────────► AirDash(upgrade), WallRun, WallJump(u stěny), Mantle, Grapple
Dash ────────► Slide(na zemi, držený slide), Grapple, WallRun
Slide ───────► Dash (slide-cancel), Skok (slide-hop = Launch), Grapple
WallRun ─────► WallJump (Launch), Mantle, Grapple, Dash
Grapple ─────► Skok (release = Launch), dosažení cíle (Launch), Dash
Launch ──────► vše vzdušné
```

### 3.3 Upgrady (Movement skill tree, §13.4)
Air Dash · Double Wall Jump · Grapple Range +20 % · Slide Boost · Stamina Efficiency · *Momentum Master* (rychlost nad 40 studs/s dává +10 % dmg dalšímu útoku) · Safe Roll (tvrdý dopad bez zpomalení) · Titan Grapple Speed.

### 3.4 Anti-exploit
Postava je fyzikálně klientská (Roblox network ownership), server proto **validuje obálku rychlosti**. Každá schopnost otevírá serveru *allowance okno* s maximální povolenou rychlostí. Opakované překročení vrátí hráče na poslední validní pozici (rubber-band). Akce jsou rate-limitované a stamina se sleduje serverem s tolerancí na latenci.

---

## 4. Combat *(Combat Designer)*

### 4.1 Staty
| Stat | Význam |
|---|---|
| HP | 100 base, armor přidává plošně |
| Stamina | 100. Dash, block, šplhání. Regen 32/s po 0,65 s. |
| Attack | dmg zbraně × škálování perků |
| Poise Damage | jak rychle rozbíjí nepřátelský Poise |
| Crit | šance a násobek (výchozí 5 % / 1,5×). Weak point = garantovaný crit ×2. |
| Elementy | Ember, Storm, Tide, Frost, Grove, Void, Celestial. Každý Titan má slabinu. |

**Damage vzorec (server):**
`dmg = base × motionValue × (1 + Σ%bonus) × critMult × weakPointMult × elementMult × (1 − targetResist)`.
Hodnotu počítá **výhradně server** z dat zbraně a stavu hráče.

### 4.2 Obrana
- **Dash i-frames:** 0,18 s (0,12 s „perfect“ okno na začátku).
- **Block:** −70 % dmg, stojí staminu podle síly úderu. Při nule staminy *guard break* (0,8 s stun).
- **Parry:** okno 0,15 s před zásahem. Jen na žluté útoky. Odměna: velký poise dmg nepříteli, +6 % Titan Energy, zvuk „cink“ a záblesk.
- **Perfect Dodge:** Riposte okno 1,2 s (+50 % dmg), +8 % Titan Energy, lokální 0,3s slow-mo efekt (jen vizuál).

### 4.3 Telegraphy (pravidla pro všechny nepřátele)
| Barva | Význam | Min. wind-up |
|---|---|---|
| **Žlutý záblesk** | parry-able | 0,40 s (Titáni 0,8 s) |
| **Červená záře** | unblockable, uhni | 0,55 s (Titáni 1,0 s) |
| **Červené kruhy/čáry na zemi** | AoE zóna | 0,8 s |
| **Bílá/azurová** | odhalený weak point | – |

Barvy doplňují **tvary** (kosočtverec = parry, trojúhelník = uhni) kvůli barvoslepým hráčům.

### 4.4 Attack tokens
Na jednoho hráče smí najednou útočit **max. 2 nepřátelé** (další krouží a čekají na token). Souboj s přesilou je tak férový a čitelný. Elitní nepřátelé mají vlastní token.

### 4.5 Síťový model souboje
1. Klient stiskne útok, okamžitě přehraje animaci a VFX (predikce).
2. Klient pošle `Combat.Attack(attackId, comboIndex, targetIds[], clientTime)`.
3. Server ověří: vybavená zbraň, cooldown a combo timing (tolerance ±120 ms), **hitbox proti pozicím cílů převinutým o latenci** (historie 1 s, max rewind 250 ms), line of sight.
4. Server aplikuje dmg, poise a stav a broadcastne `Combat.Hit` (unreliable pro VFX, reliable pro smrt a loot).
5. Nepřátelské útoky řeší **server**. I-frames hráče se berou z `MovementService` (čas posledního dashe z validované akce).

---

## 5. Zbraně *(Combat Designer)*

Každá třída má vlastní **animace, combo strom, 4 schopnosti (2 aktivní sloty), ultimate, skill tree (3 větve) a legendární zbraně s mechanikou**. Vertical slice obsahuje **Greatsword** a **Dual Blades**. Ostatní přicházejí se sezónami.

### 5.1 GREATSWORD: „Váha, která láme hory“ *(slice)*
| | |
|---|---|
| **Identita** | Pomalé, široké útoky, extrémní dmg a poise. Charge. Super armor. |
| **Light combo** | 3 údery (0,45 / 0,5 / 0,7 s). Třetí je sweep 270°. |
| **Heavy** | Charge ve 3 úrovních (hold). Lvl 3 **True Cleave** má hit stop 140 ms. Od lvl 2 super armor. |
| **Dash attack** | *Shoulder Rush*: proražení s knockbackem. |
| **Air** | *Meteor Drop*: pád mečem s kruhovou rázovou vlnou. |
| **Schopnosti** | *Earthsplitter* (linie rázové vlny) · *Iron Stance* (counter postoj: prodloužené parry okno a odveta) · *Whirlwind* (roztočení, drain staminy) · *Colossus Grip* (chytit a hodit malého nepřítele) |
| **Ultimate** | *Worldbreaker*: přízračný obří meč dopadne z nebe. |
| **Skill tree** | **Breaker** (poise dmg, armor break) · **Juggernaut** (super armor, redukce dmg) · **Executioner** (rychlejší charge, crit na omráčené) |
| **Legendární** | **Pyreheart** (Ember): charge útoky zanechávají lávové stopy, lvl 3 exploduje. · **Gravehorn Cleaver**: Shoulder Rush omráčí. · **Stormcleaver** (Storm): plný charge uloží úder blesku do dalšího zásahu. |

### 5.2 DUAL BLADES: „Vítr s ostřím“ *(slice)*
| | |
|---|---|
| **Identita** | Extrémně rychlá komba, dash útoky, vzdušný souboj, stacky. |
| **Light combo** | 6 úderů (0,18–0,25 s). |
| **Heavy** | *Flurry* finisher. Ve vzduchu *Falcon Dive*. |
| **Dash attack** | *Phantom Step*: prodash skrz nepřítele se zásahem. |
| **Air** | Prodloužené air combo, *Blade Dance* (vznášení 0,6 s). |
| **Schopnosti** | *Shadow Step* (teleport za cíl) · *Crosswind* (projektil ve tvaru X) · *Blade Storm* (cyklon) · *Hunter's Mark* (označený cíl dostává +15 % od týmu) |
| **Ultimate** | *Thousand Cuts*: zpomalení času v kruhu a série úderů. |
| **Skill tree** | **Tempest** (air combat) · **Phantom** (uhýbání, perfect dodge bonusy) · **Shatter** (stacky tříštění: každý zásah praskne nepříteli krystalky esence) |
| **Legendární** | **Cinderfang Twins** (Ember): zásahy stackují Žár, při 10 stackách další dash exploduje. · **Gravehorn Tusks**: dash útok vrací staminu. |

### 5.3 SPEAR: „Přesnost a dosah“ *(Sezóna 1)*
Dlouhé výpady, **sweet spot na hrotu** (+30 % dmg za přesnost), *Pole Vault* (mobilita), hod a přivolání kopí, anti-air.
Větve: **Lancer** / **Vaulter** / **Impaler**. Legendární: **Tidebreaker Trident**: hozené kopí vytvoří gejzír, který stahuje nepřátele.

### 5.4 GAUNTLETS: „Rytmus pěstí“ *(Sezóna 2)*
Rytmická komba (úder v rytmu = bonus), *Ground Slam*, chyty, uppercut launcher, **Heat meter** roste s řetězením.
Větve: **Brawler** / **Titanfist** / **Counter**. Legendární: **Frostknuckle**: perfektní parry zmrazí útočníka.

### 5.5 CHAIN BLADES: „Dosah a přitažení“ *(Sezóna 3)*
Útoky na střední vzdálenost, **Hook** (přitáhne nepřítele k sobě, nebo hráče k velkému cíli), houpání na grapple pointech zbraní, spin AoE.
Větve: **Reaper** / **Tether** / **Serpent**. Legendární: **Wyrmcoil** (Storm): řetěz přeskakuje bleskem až mezi 4 nepřáteli.

### 5.6 ARC CANNON: „Energie na dálku“ *(Sezóna 4)*
Rychlé výstřely s **heat managementem** (místo munice přehřátí), charged shot, *Arc Mine*, *Recoil Jump* (mobilita), odstřelování weak pointů (klíčové u létajících Titánů).
**Balanc:** menší plošný dmg, vyšší weak point multiplikátor. **Krystalové brnění jen naruší, rozbít ho musí melee**, takže i střelec zůstává součástí šplhání.
Větve: **Artillery** / **Overclock** / **Support** (týmové štíty, rychlejší revive). Legendární: **Voidlance**: charged shot otevře mini-trhlinu, která stahuje nepřátele.

### 5.7 Pravidla pro nové třídy
Každá nová třída musí (a) mít **jinou vzdálenost nebo rytmus** souboje, (b) mít **vlastní interakci s Titánem** (šplhání, weak pointy, pohyb) a (c) být hratelná na mobilu **4 tlačítky**.

---

## 6. Titáni *(Lead Game Designer + Creative Director)*

**Společná pravidla:**
- Titan má **vlastní arénu** s aspoň 2 interaktivními prvky (harpuny, gejzíry, pilíře, bleskové tyče…).
- **3 fáze** a každá mění prostor nebo pravidla, ne jen rychlost útoků.
- **Weak points:** 1 hlavní jádro (úlomek Srdcehvězdy) a 2–6 vedlejších (brnění, orgány).
- **Pohyb Titána** nutí hráče pohybovat se: nikdy nestačí „stát u nohy a klikat“. Nohy mají aura knockback a dmg na nohy je snížený o 80 %.
- **Secret drop je vždy skill-based** (splň výzvu), plus malá RNG kosmetická šance.
- **Intro:** poprvé do 8 s, při opakování 2 s. Vždy jde přeskočit.

### 6.1 EMBER COLOSSUS: *The Mountain That Walks* (Ashen Valley) *(slice)*
Detail je v [01_KONCEPT.md §7](01_KONCEPT.md#7-první-titan-ember-colossus). Shrnutí:
| | |
|---|---|
| Aréna | Kalderová pánev: lávové jezero, terasy, obsidiánové pilíře (krytí), gejzíry (vystřelí hráče), 3 řetězové harpuny |
| Fáze | I. Probuzení (v jezeře, sweep, meteory, pound) → II. Rozžhavení (láva stoupá, breath, grab, eruption) → III. Srdce hory (odhalené srdce, Cataclysm) |
| Weak points | 2× krystal na předloktí, 2× krystal na ramenou, 2× hřbetní ventily, **Magmové srdce** |
| Env. útoky | stoupající láva, meteorický déšť, erupce ventilů |
| Soundtrack | taiko, žestě, sbor. Tep srdce = sub-bass beat. |
| Loot | Ember Heart, Colossus Basalt, Magma Core Fragment |
| Secret | **Pristine Ember Heart** (všech 6 krystalů před fází III) · Ashen Crown Shard (1 %) |
| Titan Form | **Ember Form** |

### 6.2 STORM WYRM: *The Sky That Screams* (Storm Archipelago)
| | |
|---|---|
| Aréna | Oko bouře: kruh plovoucích ostrovů, **větrné proudy** (gliding mezi ostrovy), **bleskové tyče** na ostrovech |
| Intro | Blesk osvítí mraky a v nich je vidět silueta hada dlouhého stovky studů. Wyrm proletí těsně nad hráči. |
| I. Nebeský lov | Wyrm krouží a útočí nálety. Hráči **grapplují na jeho hřbet v letu** (létající climbing) a ničí **hromosvody na ploutvích**. |
| II. Upoutaný | Po zničení tyčí spadne na ostrov. Harpuny připoutají křídla. Pozemní souboj, bleskové řetězy mezi hráči (rozestup!). |
| III. Kolaps oka | Bouře se hroutí a ostrovy padají. Hráči musí stále skákat na výše položené ostrovy a přitom útočit na **Storm Core v hrdle**. |
| Weak points | 4 hromosvody, Storm Core |
| Soundtrack | elektrické housle, hromová perkuse, mužský chorál |
| Loot | Storm Core, Wyrm Scale, Thunder Fin |
| Secret | **Eye of the Tempest**: Wyrm dorazen, zatímco na něm stojí aspoň 1 hráč |
| Titan Form | **Storm Form**: letový dash, blesky, bouřkový vír |

### 6.3 ABYSS LEVIATHAN: *The Tide That Hungers* (Sunken Kingdom)
| | |
|---|---|
| Aréna | Zatopené náměstí starého království. **Příliv a odliv** každých 90 s mění, co je souš. |
| I. Kroužení | Leviatan krouží pod vodou a vyráží. Když se vynoří, na jeho hřbetě jsou chvíli **korálové pláty** k rozbití. |
| II. Vír | Vtáhne hráče do tlamy. **Krátký interiérový segment uvnitř Leviatana**: zničit orgán do 60 s, jinak jsou hráči vyplivnuti s dmg. |
| III. Tsunami | Obří vlny. Úkryt za sochami králů. Leviatan se vyvrhne na náměstí a odhalí **Perlové srdce**. |
| Secret | **Pearl of the Deep**: interiérový orgán zničen pod 30 s |
| Titan Form | **Tide Form**: vodní biče, přílivová vlna, plavání v zemi |

### 6.4 FOREST GUARDIAN: *The Root of All Things* (Greenwild: Heartwood)
| | |
|---|---|
| Aréna | Heartwood: mýtina pod stromem velkým jako hora. **Aréna je součástí Guardiana.** |
| I. Kořeny | Guardian je zakořeněný a obnovuje kůrové brnění z **mízových uzlů** v aréně. Hráči je musí nejdřív zničit (objektivy prostředí). |
| II. Vykořenění | Vytrhne se ze země a chodí. Šplhání po jeho „kmeni“, kořenové zdi dělí tým. |
| III. Rozkvět | Spóry a léčivé květy. Pokud se květy neposekají, Guardian se hojí. |
| Secret | **Seed of Rebirth**: Guardian se ani jednou nevyléčil |
| Titan Form | **Grove Form**: kořenové pasti, trnové brnění, léčivý háj pro tým |

### 6.5 FROST BEHEMOTH: *The Silence of the Peaks* (Frozen Crown)
| | |
|---|---|
| Aréna | Zamrzlé jezero na vrcholu. **Chlad**: stání na místě plní Frost meter, hřejí braziery a Ember zbraně. |
| I. Stádo | Behemoth (mamutí obr) nabíhá a led praská podle jeho kroků. |
| II. Vánice | Viditelnost 30 studů, Behemoth se hledá podle **zvuku a záře klů**. |
| III. Kry | Jezero se rozpadne na plovoucí kry. Ledové brnění na hrbu láme **oheň** (motivace nosit starší Ember výbavu). |
| Secret | **Heart of Winter**: ulomit oba kly (volitelné weak pointy) |
| Titan Form | **Frost Form**: klouzání po ledu, ledovcové zdi, zmrazení |

### 6.6 VOID REAPER: *The End of All Shapes* (Void Frontier)
| | |
|---|---|
| Aréna | Úlomky reality. **Gravitace se mění**: chodí se po stěnách i stropu. |
| I. Nesouměrnost | Reaper mizí a objevuje se. Weak pointy jsou **úlomky obíhající kolem něj**. Dosáhne se na ně portály. |
| II. Zrcadlo | Aréna se zrcadlí a útoky přicházejí z obou stran. |
| III. Kopie | Reaper **kopíruje Titan Formy hráčů** a posílá na ně jejich prázdné stíny. |
| Secret | **Unshaped Fragment**: zabít ho bez použití Titan Form |
| Titan Form | **Void Form**: blink, gravitační studny |

### 6.7 CELESTIAL TITAN: *The Last Star* (Celestial Kingdom, world boss)
Objevuje se **jen při eventu Celestial Eclipse** (plánovaně 1–2× týdně a náhodně). Bojuje celý server (až 20 hráčů) na plovoucích platformách i **na Titánovi**. Mechaniky vyžadují **rozdělení serveru do 3 skupin** (3 kotvy světla). Titan Form: **Celestial Form** (nejvzácnější, zářivá křídla). Secret: **Heartstar Splinter**, klíč k hlavnímu tajemství příběhu.

### 6.8 TITAN GRAVEYARD: Echo Hunts
Kosti dávných Titánů rezonují. Každý týden rotují **Echo verze** poražených Titánů s modifikátory (například *Rozzuřený*, *Neviditelné weak pointy*, *Bez Titan Form*) a vlastním leaderboardem. Recykluje obsah a drží endgame.

---

## 7. Titan Climbing

| Prvek | Specifikace |
|---|---|
| **Climbable plochy** | Neviditelné kolizní proxy (Party) svařené s kostmi Titána, s tagem `TitanClimbable`. Vizuální mesh nekoliduje. |
| **Vstup** | Skok nebo grapple na Titana. **Titan Grapple** kotvy (tag `TitanAnchor`) jsou zvýrazněné. |
| **Pohyb po Titánovi** | Hráč je *připojený* k lokálnímu prostoru proxy: pozice se počítá relativně k částem Titána, takže se hýbe s ním. WASD = lezení po povrchu, skok = odraz na další plát. |
| **Stamina** | Lezení −8/s, držení při otřesu −25/s, odpočinek na **plochých plátech** (Rest Ledge) regeneruje. Při 0 hráč spadne. |
| **Otřes (Shake)** | Titan se otřese (0,8 s telegraph: prach a zvuk). Hráč musí **držet** (hold) a platí zvýšený drain. |
| **Weak point na těle** | Krystal nebo ventil má HP. Útoky vsedě na Titánovi jsou speciální (bodnutí nebo úder do krystalu). |
| **Pád** | Při pádu lze **grapplovat** zpět nebo dopadnout (dmg podle výšky, Safe Roll perk). |
| **Síť** | Klient simuluje lezení lokálně a posílá stav `ClimbAttach(partId, localOffset)`. Server validuje vzdálenost od proxy a rychlost po povrchu. Útoky na weak point ověřuje server podle vzdálenosti. |
| **Výkon** | Proxy jsou jen desítky jednoduchých Partů na Titána, updatované přes `BulkMoveTo` na serveru a interpolované na klientech. |

---

## 8. Titan Form

### 8.1 Titan Energy
| Zdroj | Zisk |
|---|---|
| Perfect Dodge | +8 % |
| Parry | +6 % |
| Zásah weak pointu | +3 % |
| Rozbití brnění Titána | +10 % |
| Execution | +5 % |
| Záchrana spoluhráče (revive, osvobození z grabu) | +10 % |
| Běžný dmg | **0 %** (záměrně, energie je odměna za skill) |
| Boj s Titánem | ×2 ke všemu |

### 8.2 Transformace
1. **Aktivace** (T / D-pad nahoru / velké tlačítko): 1,2 s **cinematic**. Kamera se oddálí (FOV 70 → 85, vzdálenost ×2,2), země se otřese, esence obtočí hráče, flash a transformace. Hráč je během animace **nezranitelný**.
2. **Forma:** 3,5× větší model, nový moveset (5 útoků), **vlastní kamera** (vyšší offset, pomalejší citlivost), **vlastní zvuky** (kroky otřásají zemí u ostatních), 50% redukce dmg, imunita na stagger, **pomalejší pohyb s velkým krokem**.
3. **Trvání:** 20 s (+2 s za každou úroveň Titan tree). Ultimate formu ukončí dřív.
4. **Konec:** forma se rozpadne v esenci a hráč na 1 s zpomalí (vyčerpání). Během této zranitelnosti je dobré být v bezpečí, což je taktika.

### 8.3 Formy
| Forma | Titan | Styl | Unikátní |
|---|---|---|---|
| Ember | Colossus | těžký brawler | Lava Slam, Meteor Throw, Ground Rupture, Inferno |
| Storm | Wyrm | vzdušný | krátký let, řetězový blesk |
| Tide | Leviathan | kontrola davu | vodní biče, přílivová vlna |
| Grove | Guardian | podpora | léčivý háj pro tým, kořenové pasti |
| Frost | Behemoth | tank | ledové zdi, zmrazení |
| Void | Reaper | assassin | blink, gravitační studny |
| Celestial | Celestial | ultimátní | křídla, světelné kopí |

**Titan Clash:** Titan Form proti Titánovi v konkrétní fázi spustí krátký souboj sil (držení a timing). Při úspěchu Titan padne na kolena a odhalí jádro.

**Technika:** forma je samostatný rig (`ServerStorage/TitanForms/<Name>`). Server swapne character model (zachová Humanoid stav a hráčovu identitu) a hlídá délku trvání i cooldown. Klient spouští cinematic a kameru.

---

## 9. Nepřátelé a AI

### 9.1 Archetypy (vertical slice)
| Archetyp | HP | Chování | Telegraph | Varianty |
|---|---|---|---|---|
| **Skulker** | nízké | smečky 3–5, kroužení, výpad | přikrčení 0,45 s (žlutý) | Thornskulker, Cinderskulker |
| **Brute** | vysoké, čelní brnění | pomalý, slam, máchnutí, štít | zvednutí paže 0,6 s (žlutý), slam 0,8 s (červený) | Mossback, Magma |
| **Spitter** | střední | drží odstup 25–40 studů, projektily, utíká | nafouknutí 0,5 s | Spore Spitter, Ember Wisp |
| **Miniboss Gravehorn** | boss | charge, dupání, přivolá Skulkery, zasekne se o sloup | hrabání 0,9 s | – |

### 9.2 AI architektura
- **Stavy:** `Idle → Patrol → Alert → Engage(Approach/Circle/WaitToken) → Attack(Windup/Active/Recovery) → Staggered → Dead`.
- **Server-authoritative**, bez Humanoidu (šetří výkon). Pohyb řídí `AlignPosition`/CFrame na serveru. Klienti interpolují a přehrávají animace přes `AnimationController`.
- **Tick rate podle vzdálenosti** od nejbližšího hráče: <60 studů 10 Hz, <200 studů 4 Hz, dál spí.
- **Pathfinding:** `PathfindingService` s cache a `PathfindingModifier` na nebezpečí.
- **Elitní modifikátory:** *Molten* (lávová stopa), *Shielded*, *Frenzied*, **Titanborn** (má vlastní weak point, dropuje Titan Shard).

---

## 10. Exploration

**Proč opustit cestu:** tajné oblasti dávají **sílu** (Titan Relics = body do Titan/Movement stromu), **kosmetiku**, **lore** a **zkratky**. Nejde jen o zlato.

| Typ | Příklad | Odměna |
|---|---|---|
| Secret cave | za vodopádem ve Whisperfall | Titan Shard, lore kámen |
| Hidden boss | *Hollow King* v kryptě Mossfall (volitelný) | Epic drop, titul |
| Ancient ruins a puzzle | 3 sochy natočené podle stínů | treasure room |
| Rare creature | Glimmerfox (utíká, spawn 5 %) | kosmetický trail |
| Parkour oblast | Kořenová věž v Rootway | Titan Relic nahoře |
| Underground | jeskyně pod Skull Hollow | zkratka a sběratelské předměty |
| Hidden Titan remains | kosti v Ashen Valley s echem | Codex záznam a dílo pro Muzeum |
| Treasure room | trezor v ruinách | Rare+ loot |
| **Zpětná tajemství** | obsidiánová pečeť (jen Ember Titan Form) | důvod k návratu |

**Mapa:** fog-of-war se odkrývá průzkumem. **Codex** ukazuje procenta objevení regionu. Za 100 % je region trophy (kosmetika). Minimapa ukazuje jen obecné oblasti, tajemství **nikdy**. Hunter perk *Loot Sense* dává jemný zvukový signál v blízkosti.

---

## 11. World Events *(Live-Ops Designer)*

`WorldEventService` (server) je **režisér**. Vybírá eventy podle vah, cooldownů, počtu hráčů a stavu regionu. Mezi eventy je min. 6–10 min. Oznámení: cinematic banner, roh v dálce, ping na mapě.

| Event | Spouštěč | Průběh | Odměna |
|---|---|---|---|
| **TITAN DETECTED** | náhodně, 1× za 25–40 min v regionu Titána | **WARNING: TITAN DETECTED**, Titan přejde regionem (migrační verze). Kdokoli se může přidat (10 min okno). | plný Titan loot, bonus za účast |
| **Titan Invasion** | vzácně, Citadela nebo tábor | Titanovy výtvory útočí na tábor, obrana ve vlnách. | Hunt Marks, titul |
| **Meteor Storm** | náhodně | Meteory dopadají a v kráterech jsou mini-elementálové a Titan Shardy. | materiály |
| **Void Rift** | náhodně (od Ranku B) | Trhliny chrlí void elity. Zavírají se držením zóny. | Void Fragmenty |
| **Ancient Temple Opening** | náhodně, 8 min | Zapečetěný chrám se otevře: puzzle dungeon s treasure room. | Epic+ šance |
| **Titan Migration** | náhodně | **Mírumilovný** obr prochází regionem. Dá se na něj vylézt a na jeho zádech je poklad a vyhlídka. *Průzkumný event.* | Relic, kosmetika |
| **Celestial Eclipse** | plánovaně a vzácně | Celý server bojuje s Celestial Titánem. | Celestial loot |
| **Monster Horde** | náhodně | Vlny na outpost. Při neúspěchu zůstane outpost vizuálně poškozený do dalšího eventu. | Hunt Marks |

**Cross-server:** `MessagingService` hlásí globální eventy (například „Eclipse začíná za 5 min na všech serverech“). Globální komunitní cíle počítá `MemoryStoreService`.

---

## 12. Destructible Environment

| Pravidlo | Implementace |
|---|---|
| Silné útoky viditelně reagují s prostředím | tag `Breakable` s atributem `Health`. Heavy a vyšší útoky dávají dmg prostředí. |
| **Pre-fractured modely** | intaktní model se po rozbití vymění za předpřipravené úlomky z **poolu** |
| Úlomky | unanchored 3–5 s, pak fade a návrat do poolu. **Max. počet** podle kvality: Low 20 / Med 60 / High 150 / Ultra 250. |
| Kosmetická destrukce | **jen na klientovi** (kameny, bedny, keře), deterministický reset |
| Herní destrukce | **server** (obsidiánové pilíře, zdi k tajemstvím), replikovaný stav |
| Praskliny | decaly z poolu, fade po 8 s |
| Reset | vše se obnoví po 60–120 s nebo při resetu arény. **Nikdy permanentní zničení mapy.** |

---

## 13. Progression

### 13.1 Hunter Rank
`E → D → C → B → A → S → SS → TITAN`. Každý rank vyžaduje **Rank Trial**:

| Přechod | Požadavky |
|---|---|
| E → D | Greenwild výprava, Gravehorn, 10× Perfect Dodge, 3 tajemství |
| D → C | Ember Colossus, craft Ember předmětu, *Zkouška popela* (sólo aréna na čas) |
| C → B | Storm Wyrm, Titan Form výzva (X dmg během jedné formy), 50% průzkum dvou regionů |
| B → A | Frost Behemoth a Leviathan, speciální mise *Lov bez stop* (stealth) |
| A → S | 3 Echo Hunty, 75% Codex |
| S → SS | Void Reaper, Echo bez smrti v squadu |
| SS → TITAN | Celestial Titan, *Poslední zkouška* (gauntlet všech mechanik) |

**Renown (XP)** plyne ze všeho a je jen *jednou* z podmínek.

### 13.2 Weapon Mastery
Používáním zbraně roste Mastery, 1 bod za level (max 30 na zbraň). Respec je **zdarma v hubu** (podpora experimentování).

### 13.3 Obecné skill trees
| Strom | Příklady uzlů | Zdroj bodů |
|---|---|---|
| **Movement** | Air Dash, Double Wall Jump, Grapple Range, Slide Boost, Stamina Efficiency, Momentum Master, Safe Roll | Rank up, Titan Relics |
| **Hunter** | Loot Sense, Tracking (zvýrazní weak pointy), Critical Eye, Execution+, Material Yield | Rank up, bestiář |
| **Titan** | Titan Energy gain, délka formy, druhý slot formy (swap), Titan Clash síla | Titan kill (první), Titan Relics |
| **Survival** | Max HP, rychlost revive, self-revive 1× za výpravu, lektvary, odolnosti | Rank up, výzvy |

### 13.4 Build
Build = zbraň + 2 schopnosti + ultimate + perky z 3 stromů + armor set bonus + Titan Form. Hráč má **3 loadout sloty** zdarma.

---

## 14. Crafting, loot a rarity *(Economy Designer)*

### 14.1 Titan materiály
| Titan | Materiály |
|---|---|
| Ember Colossus | Ember Heart, Colossus Basalt, Magma Core Fragment, *Pristine Ember Heart* |
| Storm Wyrm | Storm Core, Wyrm Scale, Thunder Fin |
| Abyss Leviathan | Leviathan Scale, Abyssal Pearl, Tide Gland |
| Forest Guardian | Heartwood, Ancient Sap, Bloom Seed |
| Frost Behemoth | Frost Tusk, Permafrost Hide, Glacial Core |
| Void Reaper | Void Fragment, Unshaped Shard |
| Celestial Titan | Starlight Essence, Heartstar Splinter |
| Obecné | Titan Bone, Titan Shard, monster materiály, zlato |

**Titan materiály jsou vázané na účet** (nelze obchodovat), aby si zachovaly hodnotu úspěchu.

### 14.2 Co se craftí (příklad Ember)
| Předmět | Recept | Unikátní |
|---|---|---|
| **Pyreheart** (Greatsword) | Ember Heart, 6× Basalt, 2× Magma Core, zlato | lávové stopy z charge |
| **Cinderfang Twins** (Dual Blades) | Ember Heart, 4× Basalt, 3× Magma Core | stacky Žáru |
| **Ember Armor** (3 díly) | Basalt, Titan Bone | set 2/3: imunita na heat hazard, 3/3: dash zanechá plamen |
| **Lava Trail** (kosmetika) | 10× Basalt | stopa za hráčem |
| **Ember Transformation** | automaticky za první kill | Titan Form |
| **Mountainbreaker** (Mythic) | Pristine Ember Heart + … | viz rarity |

**Upgrady:** Resonance +1…+10 (materiály a zlato, **bez šance na selhání**). **Infuze:** jádra Titánů dávají element.

### 14.3 Rarity: mechanika, ne jen barva
| Rarita | Co přináší |
|---|---|
| Common | základní staty |
| Uncommon | 1 menší perk |
| Rare | 2 perky |
| Epic | perky a **Trait** (mění jednu schopnost, například Whirlwind táhne nepřátele) |
| Legendary | **unikátní mechanika** měnící chování zbraně |
| Mythic | unikátní mechanika, **vlastní animační sada a VFX** a synergie s Titan Form |
| Titan | jen z Titánů. Zbraň obsahuje útok Titána jako schopnost. |
| Celestial | eventová. Alternativní režim zbraně (přepínání). |
| Secret | skrytý požadavek, efekt je překvapení (například **Mountainbreaker**: po 3 perfect dodge se zbraň na 5 s promění v Colossovu pěst) |

### 14.4 Loot pravidla
- **Osobní loot** (každý hráč má své dropy, žádné kradení).
- **Bad-luck protection:** každý neúspěšný pokus zvyšuje šanci na vzácný drop.
- **Server generuje loot**, klient ho jen zobrazuje. Sebrání ověřuje server (vzdálenost, vlastník).

---

## 15. Ekonomika *(Economy Designer)*

| Měna | Zdroj (faucet) | Využití (sink) |
|---|---|---|
| **Zlato** | dropy, mise, prodej | crafting poplatky, upgrady, barvy, respec kosmetiky |
| **Titan materiály** | Titáni (vázané) | crafting, formy |
| **Hunt Marks** | eventy, kontrakty | Event Shop (kosmetika, materiály) |
| **Robux** | – | kosmetika, Hunter Pass (§19) |

- **Žádná prémiová mezi-měna.** Ceny jsou přímo v Robuxech (transparentní).
- **Rozpočet faucetů:** cílové zlato za hodinu podle ranku (tabulka v `Shared/Config/Economy.luau`). Sinky rostou s rankem.
- **Obchodování:** **ne při launchi** (riziko dupe a scamů). Později jen kosmetika přes server-validované obchodní okno s escrow a cooldownem.
- **Každá transakce** jde přes `DataService` s atomickými operacemi a audit logem (`AnalyticsService` economy events).

---

## 16. Multiplayer *(Multiplayer Systems Designer)*

### 16.1 Typy serverů
| Server | Kapacita | Účel |
|---|---|---|
| **Citadel (hub)** | 30 | social, crafting, mise |
| **Wilds (veřejný)** | 12–16 | otevřený svět, world eventy, Titáni |
| **Private Expedition** | squad (1–6) | `ReserveServer`, soukromá výprava |
| **Titan Hunt** | squad (1–6) | přímý boj s Titánem z Mission Boardu |

Squad se teleportuje spolu (`TeleportService:TeleportAsync` s `TeleportOptions.ReservedServerAccessCode` nebo do stejného veřejného serveru).

### 16.2 Hunter Squads
- 1–6 hráčů, pozvánky, ikony nad hlavou, sdílený progres misí, **quick-ping** (Weak point! / Pomoc! / Grapple sem / Pozor!). Na mobilu je to nutnost.
- **Revive:** downed stav 30 s, spoluhráč oživuje 3 s holdem. V Titan fightech respawn na okraji arény po 15 s (bez wipe ve veřejných bojích).
- **Týmové schopnosti:**
  - **Link Strike:** 2+ hráči zasáhnou odhalený weak point do 1,5 s → bonus dmg a sdílená Titan Energy.
  - **Hunter's Oath:** revive dá oběma krátký buff.
  - **Titan Resonance:** 2 hráči v Titan Form najednou mohou spustit společný finisher.
- **Assist odměny:** plný loot dostane každý, kdo udělal ≥3 % dmg **nebo** revive, rescue z grabu, rozbití brnění či zásah harpunou. Podpora se vyplácí.
- **Škálování Titána:** `HP × (1 + 0.65 × (n − 1))`, sublineárně, takže víc hráčů = rychlejší kill.
- **Nevynucujeme kompozici.** Žádné role, každá zbraň zvládne každou mechaniku (jen jinak rychle).

---

## 17. Social Hub: Hunter Citadel

| Místo | Funkce |
|---|---|
| **Forge** (Brann) | crafting, upgrady, infuze, 3D náhled |
| **Blacksmith** | úpravy vzhledu zbraní (transmog), barvení |
| **Training Grounds** | figuríny s DPS metrem, parry trenér, **movement time trials** a leaderboard (už v PHASE 1) |
| **Mission Board** (Oda) | výpravy, kontrakty, Rank Trials |
| **Titan Museum** (Lyss) | trofeje z vlastních killů, Codex, lore, top lovci serveru |
| **Leaderboards** | speedkill Titánů podle velikosti squadu, time trials, rank |
| **Squad Area** | táborák, LFG tabule, emote plaza |
| **Portal Chamber** | teleporty do regionů, vizuální spektákl |
| **Cosmetic Shop / Wardrobe** | kosmetika, outfity, náhled |
| **World Map** | živá mapa s aktivními eventy napříč servery |

Hráči vidí vybavení ostatních (transmog) a mohou je **Inspect**. Hub má **fotogenická místa** (lebka, výhled z žebra) pro sdílení.

---

## 18. Customizace a skiny *(Character Designer)*

**Sloty:** Hair · Face · Outfit · Armor (**transmog**: vzhled odděleně od statů) · Weapon skin · Aura · Trail · Cape · Title · Emotes · Victory Pose · Spawn Animation · **Titan Transformation Effect**.

### 18.1 Kolekce (vlastní IP)
| Kolekce | Příběh | Vizuál | Signature efekt |
|---|---|---|---|
| **VOID HUNTER** | lovci, kteří přežili dotek Void Frontier | černý pancíř s magentovými trhlinami reality | Titan Form se zjeví trhlinou v prostoru |
| **CELESTIAL KNIGHT** | strážci nebeského království | bílo-zlaté pláty, plovoucí souhvězdí jako svatozář | transformace sestupem světla |
| **INFERNAL DEMON** | kult, který uctívá Colosse | rohatý magmový pancíř, doutnající plášť | kroky pálí zem |
| **STORM WARRIOR** | kmeny z archipelagu | kožešina, měď, bleskové tetování, plášť z mraku | blesk při dashi |
| **ANCIENT KING** | ztracení králové Sunken Kingdom | korálová koruna, zlato s mušlemi | vodní aura, přílivový spawn |
| **CYBER HUNTER** | Cech Artificerů (runová technologie z doby před Rozerváním) | neonové runy, visor, mechanické pláty | digitální glitch při transformaci |
| **SHADOW ASSASSIN** | Řád Stínového závoje | kouřová látka, maska | stopy kouře, zmizení v emotu |
| **FROST GUARDIAN** | strážci Frozen Crown | ledovcový pancíř, krystalové parohy na helmě | mrazivý dech, zamrzající stopy |

Každá kolekce obsahuje outfit, weapon skiny pro všechny třídy, auru, trail, emote a transformation effect. Část je **zdarma za výzvy** (například Frost Guardian za Heart of Winter), část je v shopu nebo v Hunter Passu.

---

## 19. Monetizace

**Princip:** hráči platí, protože **chtějí vypadat skvěle**, ne proto, že bez placení nemohou hrát.

| Produkt | Typ | Poznámka |
|---|---|---|
| Skiny, weapon skiny, aury, trails, capes | Developer Products / rotující shop | hlavní příjem |
| **Titan Transformation Effects** | kosmetika | nejviditelnější moment hry = nejvyšší hodnota |
| Finishers (execution animace), emotes, victory poses, spawn animace | kosmetika | |
| **Hunter Pass** (sezónní) | free a premium track | pouze kosmetika a Hunt Marks |
| Mount cosmetics | kosmetika | mounty přicházejí se Storm Archipelagem |
| Extra loadout / outfit sloty | game pass | pohodlí, **ne síla** |
| Private servery | Roblox VIP servers | levné |

**Nikdy:** prodej statů, XP boostery, loot boxy (placené náhodné předměty), energie nebo časovače hraní, placené revive, placené přeskočení Rank Trials. Nákup nesmí dát výhodu v leaderboardech.

**Soulad s pravidly:** Roblox pravidla pro placené náhodné předměty a regionální omezení řešíme tím, že **žádné nemáme**. Všechny nákupy jsou deterministické.

---

## 20. UI/UX *(UI/UX Designer)*

### 20.1 HUD (explorace)
```
┌───────────────────────────────────────────────────────────────┐
│ [Squad 1–5]                                  Cíl: jedna řádka │
│                                                               │
│                            (+)                                │
│                                                  loot feed ↘  │
│ ▬▬▬ HP                      ◉ Titan Energy        [1][2][U]   │
│ ─── Stamina (kontextová, mizí při plné)                       │
└───────────────────────────────────────────────────────────────┘
```

### 20.2 Dynamický boss HUD
- Po vstupu do arény se HUD **zúží**: skryje se loot feed a minimapa a objeví se **boss bar** nahoře (jméno, podtitul, **pipy fází**, žlutý segment pro „poise“ Titána).
- **Odhalený weak point:** indikátor na okraji obrazovky ukazuje směr.
- **Titan Form ready:** gauge vzplane a tlačítko pulzuje. Krátký zvukový „hum“.
- **Chycený spoluhráč:** jeho portrét bliká a nad ním je ikona „ZACHRAŇ“.

### 20.3 Menu
Radiální quick-menu (emoty, pingy) · Inventář s 3D ViewportFrame · Forge UI · Mapa s fog-of-war · Codex.

### 20.4 Přístupnost
Barvoslepé režimy a tvarové symboly telegraphů · posuvník **camera shake** (0–100 %) · redukce záblesků · titulky · škála UI · hold/toggle pro sprint a block · **editor rozložení tlačítek na mobilu**.

### 20.5 Mobil
Auto-target, velká tlačítka v oblouku kolem skoku (PHASE 1 už je má pro pohyb), zjednodušená komba (rytmus tapů), grapple auto-targeting.

---

## 21. Boss intro

| Krok | Poprvé | Opakovaně |
|---|---|---|
| Kamera ukáže okolí arény | 2,5 s | – |
| Hudba utichne, ambient a dunění | 1 s | – |
| Titan se objeví (unikátní animace) | 3 s | – |
| Title card **JMÉNO / PODTITUL** | 1,5 s | 2 s (řev a jméno) |
| **Přeskočit** | kdykoli (hold 0,5 s) | automaticky zkrácené |

Ve squadu platí: pokud aspoň jeden hráč vidí intro poprvé, přehraje se jen jemu. Ostatní vidí krátkou verzi a Titan čeká, dokud intro neskončí nebo nevyprší 8 s.

---

## 22. Audio *(Sound Designer)*

- **Titáni:** vlastní téma, instrumentace a **stems** (perkuse, žestě, sbor, full). Fáze přepínají vrstvy crossfadem. Vzdálený Titan má 2D „distant roar“ vrstvu, která prodává měřítko i mimo 3D dosah.
- **Ambience** per region (vítr v kořenech, praskání lávy, bouře…).
- **Zbraně:** vrstvení (whoosh, impact, materiál cíle, tail), ±8 % pitch variace, hit stop synchronizovaný se zvukem.
- **Schopnosti a UI:** krátké, taktilní, nerušící.
- **Technika:** nové Roblox Audio API (`AudioPlayer`, `AudioEmitter`, `AudioListener`, `AudioFader`, efekty) pro dynamický mix. **Ducking** hudby při velkých momentech. Voice pool s prioritami (max. souběžných zvuků podle kvality).

---

## 23. Grafika a výkon *(Performance Engineer)*

### 23.1 Kvalitativní tiery
| | Low | Medium | High | Ultra |
|---|---|---|---|---|
| Particle rate × | 0,25 | 0,5 | 1,0 | 1,25 |
| Max. úlomků | 20 | 60 | 150 | 250 |
| VFX ostatních hráčů (dosah) | 80 | 150 | 260 | 400 |
| Post-process | žádný | ColorCorrection | + Bloom, SunRays | + DepthOfField v cinematics |
| Trails | krátké | střední | plné | plné |

Tier se nastaví automaticky podle `SavedQualityLevel` a zařízení. **Auto-downgrade** proběhne, když průměrné FPS < 45 po dobu 10 s. Hráč může tier změnit ručně.

### 23.2 Techniky
- `StreamingEnabled` s `ModelStreamingMode`: **Atomic** pro nepřátele a propy, **Persistent** pro Titány, grapple pointy a klíčové kotvy.
- `Model.LevelOfDetail = StreamingMesh` pro vzdálené stavby (impostory).
- **Object pooling:** projektily, VFX, úlomky, damage čísla, beamy.
- **Distance-based VFX:** detail efektů klesá se vzdáleností, mimo dosah se efekt nespustí vůbec.
- **Server:** AI tick podle vzdálenosti, max. ~60 aktivních nepřátel na server, nepřátelé bez Humanoidu, fyzika jen tam, kde je potřeba.
- **Síť:** < 50 KB/s na hráče. `UnreliableRemoteEvent` pro kosmetiku. `buffer` pakety pro časté aktualizace (pozice nepřátel).
- **Cíl:** 60 FPS na mid-range mobilu (iPhone 11 / Android s 4 GB RAM), 30 FPS minimum na low-end. Klientská paměť pod ~1,2 GB na mobilu (měřit Developer Console → Memory).

---

## 24. Live-ops

| Rytmus | Obsah |
|---|---|
| **Denně** | 3 Hunter Contracts. Nepropadají, hromadí se až 7, takže žádný FOMO trest. |
| **Týdně** | Titan Bounty s modifikátory a leaderboardem, Echo Hunt rotace |
| **Každé 4 týdny** | mid-season event (například Meteor Festival) |
| **Sezóna (8 týdnů)** | nový Titan nebo Echo, Hunter Pass, nová zbraň každé 2 sezóny, nový region každé 1–2 sezóny |
| **Komunitní cíle** | globální počitadla (například „1 000 000 rozbitých krystalů“), která odemknou event pro všechny |

**Roadmapa po launchi:**
S1 Storm Archipelago a Storm Wyrm, Spear · S1.5 Greenwild *Heartwood* a Forest Guardian · S2 Frozen Crown a Frost Behemoth, Gauntlets · S3 Sunken Kingdom a Abyss Leviathan, Chain Blades · S4 Titan Graveyard a Echo Hunts, Arc Cannon · S5 Void Frontier a Void Reaper · S6 Celestial Kingdom a Celestial Titan.

---

## 25. Analytika a KPI

**Nástroje:** Roblox `AnalyticsService` (custom events, **funnels**, economy events), Creator Dashboard retention.

| KPI | Cíl (vertical slice playtest) |
|---|---|
| Dokončení prologu | ≥ 92 % |
| Dosažení Greenwildu | ≥ 80 % |
| Kill Gravehorna | ≥ 60 % |
| Kill Ember Colosse (do 3 h hraní) | ≥ 35 % |
| D1 retention | ≥ 35 % |
| D7 retention | ≥ 12 % |
| Průměrná session | ≥ 25 min |
| Titan Form použití na Titan fight | 1–2 na hráče (ne víc) |

**Funnel eventy:** `Prologue_Step_{1..6}`, `FirstExpedition_Start`, `Gravehorn_Kill`, `Ember_Encounter`, `Ember_Phase_{1..3}`, `Ember_Kill`, `TitanForm_First`.
**Playtest metriky:** čas do prvního killu, smrti na fázi bosse, míra použití parry a perfect dodge, heatmapy smrtí a odboček z cesty.

---

## 26. Rizika a mitigace

| Riziko | Dopad | Mitigace |
|---|---|---|
| Scope (9 regionů, 7 Titánů, 6 zbraní) | vysoký | **Vertical slice first.** Další obsah až když je core zábavný (gate po PHASE 11). |
| Technika šplhání po pohyblivém Titánovi | vysoký | Technický spike v PHASE 4 hned na začátku, kolizní proxy, lokální prostor. |
| Výkon na mobilu | vysoký | Budgety od PHASE 1, quality tiery, profilace každý sprint. |
| Exploity (speed, dmg, loot) | vysoký | Server authority všude, validace, rate limity, audit log. |
| Kvalita animací | střední | Dedikovaný animátor, procedurální vrstvy (PHASE 1 poser) jako záloha. |
| Obsahové sucho po launchi | střední | Echo Hunts, world eventy a remixy recyklují obsah. |
| Kolize názvu | střední | Rebrand na **TITANWAKE** (viz koncept §0) před marketingem. |
