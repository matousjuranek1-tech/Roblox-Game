# TITANBOUND: Koncept hry

> Pracovní název: **TITANBOUND**. Doporučená změna názvu je v sekci [0. Název](#0-název-a-identita).
> Koncept art: [docs/ART.md](ART.md) (vygenerováno přes Higgsfield).

[![Key art: lovec proti Ember Colossovi](https://d8j0ntlcm91z4.cloudfront.net/user_3Gqcr0XXTvKdyVYMJhbBfyh7i3j/hf_20260925_124434_785df3df-4552-422f-835b-6778f365ea67_min.webp)](https://d8j0ntlcm91z4.cloudfront.net/user_3Gqcr0XXTvKdyVYMJhbBfyh7i3j/hf_20260925_124434_785df3df-4552-422f-835b-6778f365ea67.png)

**Jednou větou:** kooperativní akční hra o lovcích, kteří loví Titány velké jako hory, šplhají po nich, trhají jim brnění a nakonec se sami na pár vteřin stanou Titánem, kterého porazili.

**Žánr:** co-op action RPG, open-zone exploration, boss hunting.
**Platformy:** Roblox (PC, mobil, konzole, tablet).
**Hráči:** 1–6 v Hunter Squadu, 12–20 na serveru divočiny, 30+ v hubu.
**Cílová skupina:** hráči 10–25 let, kteří mají rádi rychlý souboj, bossy, pohyb (parkour, grapple) a hraní s kamarády.

---

## 0. Název a identita

Při kontrole názvu jsme našli **kolizi**. Jméno „Titanbound“ už používá:
- *Titanbound* pro Shadowdark RPG (Torchlight Creative): sourcebook přesně o **šplhání po Titánech a jejich zabíjení**, tedy stejná fantasy.
- *Titanbound: Beyond the Rift* (Ludus Magnus Studio): desková hra.

Stejné jméno ve stejném žánru oslabuje hledatelnost i vlastní IP. Proto navrhujeme tyto varianty:

| Název | Význam | Hodnocení |
|---|---|---|
| **TITANWAKE** ⭐ doporučeno | „Probuzení Titánů“ a zároveň „probuzení Titána v tobě“ (Titan Form). *Wake* znamená i „brázdu“ za obřím tvorem. | Krátký, dobře se hledá (Roblox search „titan“), bez nalezené herní kolize. |
| COLOSSFALL | Pád kolosů. | Silný zvuk, ale „-fall“ evokuje Titanfall od EA. |
| SUNDERHUNT | Lov v Rozervaném světě. | Originální, ale bez slova „Titan“ se hůř hledá. |
| TITANSCAR | Jizvy, které Titáni nechali ve světě. | Dobrá atmosféra, horší výslovnost pro mladší hráče. |
| HUNTERS OF THE SUNDERING | Podtitul, ne hlavní název. | Vhodné jako podtitul. |

**Doporučení:** **TITANWAKE: Hunters of the Sundering**. Do schválení používáme v dokumentech i v kódu pracovní název TITANBOUND. Kód na názvu nezávisí.
Před spuštěním je potřeba ještě ověřit ochrannou známku (USPTO/EUIPO) a obsazenost jména na Robloxu.

### Vlastní IP: svět, lore a proč dává smysl Titan Form

- **Svět:** *Rozervané země (The Sundered Lands)*.
- **Rozervání (The Sundering):** před sto lety spadla z nebe **Srdcehvězda (Heartstar)** a probodla svět. Pod povrchem spali **Titáni**, prastaré bytosti, z nichž každá je „orgánem“ světa: oheň hor, dech bouří, krev moří, růst lesů, ticho ledu. Úlomky Srdcehvězdy se jim zaryly do těl. Titáni se probudili v bolesti a roztrhali kontinent: ostrovy vyzvedli do bouře, království potopili a hory zamrazili.
- **Titáni nejsou zlí.** Jsou to raněné přírodní síly. Každý nese uvnitř úlomek Srdcehvězdy, který ho pohání k zuřivosti. **Tento úlomek je jeho jádro, a tedy i hlavní weak point.**
- **Lovci (Hunters)** jsou lidé, kterým po útoku Titána zůstala v těle **jiskra titanské esence**. Esence se dá **svázat (bond)** se sebou samým. Kdo porazí Titána a absorbuje jeho esenci, dokáže krátce **probudit Titána v sobě**. To je **TITAN FORM**, jádro hry a důvod názvu.
- **Hunter Citadel** je postavena uvnitř kostry **Athraxe, Prvního Padlého**: prvního Titána, kterého kdy lovec porazil. Žebra jsou mosty a věže, lebka je hlavní brána. Hub je tak na první pohled nezaměnitelný.
- **Dlouhodobé tajemství (pro sezóny):** kdo nebo co Srdcehvězdu seslal? Je zabíjení Titánů skutečně správné? Void Reaper spolkl největší úlomek a deformuje realitu. Celestial Titan možná hvězdu hodil. Na tomto příběhu lze stavět roky obsahu.

### Klíčové postavy (NPC)

| Postava | Role | Funkce ve hře |
|---|---|---|
| **Maršálka Oda Kerr** | Velitelka lovců. V prologu ti hodí zbraň. | Mission Board, Rank Trials |
| **Brann Železná ruka** | Kovář bez levé ruky, kterou mu vzal Titán | Forge, crafting, upgrady |
| **Lyss Vey** | Učenkyně a kurátorka Titanského muzea | Codex, lore, tajemství, sběratelství |
| **Maera Voss** | *První lovkyně* (legenda, socha v Citadele) | Příběhové háčky, endgame |

---

## 1. Hlavní fantasy

> **„Jsem malý člověk ve světě, kde chodí hory. A jednou budu to, co je loví.“**

Čtyři pilíře (každá featura musí posilovat aspoň jeden):

1. **MĚŘÍTKO (Scale is the star).** Titáni jsou obří, viditelní z dálky a mění krajinu. Hráč cítí respekt.
2. **MISTROVSTVÍ (Skill over stats).** Uhýbání, parry, pohyb a šplhání rozhodují víc než čísla na zbrani.
3. **PROMĚNA (Become the Titan).** Hráč z lovce postupně roste a nakonec se sám stává Titánem.
4. **SPOLEČNĚ (Hunt together).** Nejlepší momenty vznikají s kamarády: záchrana spoluhráče ze sevření, koordinovaný útok na odhalený weak point.

**Emoční oblouk vertical slice:** v prologu tě Ember Colossus málem zabije a zničí město. O pár hodin později stojíš v jeho aréně, lezeš mu po rameni, trháš mu srdce z hrudi a jeho vlastní silou se **proměníš v Ember Titána**. Kruh se uzavře.

---

## 2. Prvních 30 sekund: prolog „Pád Kessrinu“

Žádné menu ani baseplate. Hráč se objeví **přímo v útoku**.

| Čas | Co se děje | Co se hráč učí |
|---|---|---|
| **0:00** | Černá obrazovka, hluboké **BUM**, třes kamery. Fade-in: večerní ulice hraničního města **Kessrin**. Na horizontu (asi 600 studů daleko) se z kouře zvedá **Ember Colossus**, 180 studů vysoký, s lávou prosvítající prasklinami. Řev v sub-basu. Prach padá ze střech, NPC utíkají kolem hráče. | *Tohle je svět.* |
| **0:03** | Hráč dostane ovládání. Cíl: **„UTEČ K BRÁNĚ“**. Světelná stopa ukazuje směr. Do domu před hráčem narazí hořící balvan hozený Titánem a ulice se propadne. | Pohyb, sprint (Shift) |
| **0:06** | Na střeše stojí **maršálka Oda Kerr**: *„Hej! Chytej!“* Hodí zbraň, která se se zábleskem zapíchne do dlažby. Hráč jí proběhne a automaticky ji vezme. | *Mám zbraň.* |
| **0:10** | Propadlá ulice, 14studová mezera. Nápověda: **Sprint + Skok**. Za mezerou je nízká zřícená trám. Nápověda: **Slide**. | Movement |
| **0:14** | Titan hází žhavé meteory. Na zemi se objeví **červené kruhy** (telegraph). Nápověda: **Q, úhyb**. Pokud hráč uhne v poslední chvíli, spustí se zpomalení na 0,3 s a nápis **PERFECT DODGE**. | Čitelné útoky a odměna za timing |
| **0:18** | Ze sutin vyskočí **Cinderskulker** (malé monstrum). Viditelně se nahrbí (telegraph) a skočí. 3–4 zásahy ho zabijí. Poslední úder má výrazný hit stop, kamera se otřese a monstrum se rozpadne na jiskry. | Souboj je satisfying |
| **0:24** | Hráč doběhne na náměstí u brány. Colossus je teď **mnohem blíž**, protože během sekvence šel k městu. Zvedne obě paže a jeho hrudní jádro zazáří. Do hráče vlétne pár jisker **titanské esence** a jeho ruka na zlomek sekundy oranžově zaplane (*předzvěst Titan Form*). | *Něco ve mně je.* |
| **0:28** | **ÚDER.** Obrovská rázová vlna se valí ke kameře. Maximální shake, bílý záblesk. | |
| **0:30** | **CUT.** Černo. Název hry se zvukem dopadu. Text: *„Přežil jsi. Tentokrát.“* | |

**Hned potom:** hráč se probudí na ošetřovně **Hunter Citadel**. Oda Kerr: *„Titan v tobě nechal jiskru. Takových je málo. Vítej mezi lovci.“*

**Technické poznámky:**
- Prolog je **izolovaná oblast v place hubu** (streamovaná zvlášť, daleko od města), ne samostatný place, takže hráč nečeká na teleport. Nový hráč (`DataService: PrologueComplete == false`) se spawne tam.
- Skriptovaná sekvence (Titan, meteory, destrukce, NPC dav) běží **na klientovi**. Server spawnuje hráče a ověřuje jen dokončení (pozice u brány a čas). Ostatní hráči jsou v prologu skrytí.
- Opakované spuštění prolog přeskočí. V menu Codexu lze prolog přehrát znovu.
- Cílová délka je 30–45 s. Tempo se nesmí zastavit ani na moment.

---

## 3. Prvních 10 minut

| Čas | Kde | Zážitek | „Zajímavý moment“ |
|---|---|---|---|
| 0:30–1:30 | **Citadela** | Průchod pod žebry Athraxe (wow záběr hubu). Oda vydá **Hunter License, Rank E**. | Objevení nového světa |
| 1:30–2:30 | **Zbrojnice** | Výběr zbraně: **Greatsword** nebo **Dual Blades**. Na tréninkových figurínách lze každou vyzkoušet 15 s a později ji zdarma přepnout. Rychlá kosmetika (vlasy, barvy). Lze přeskočit. | Nová schopnost |
| 2:30–3:00 | **Mission Board → Portal Chamber** | První výprava *„Stíny v Greenwildu“*. Portál je vizuální spektákl s rotujícími prstenci. | Nová oblast |
| 3:00–4:30 | **Greenwild: Rootway** | Parkour po obřích kořenech. Učí wall run a grapple přes rokli. První smečka 3 **Thornskulkerů**. | Souboj, pohyb |
| 4:30–5:30 | **Mossfall Ruins** | První **Mossback Brute**. Jeho útok **žlutě zablikne**, takže jde o parry. Úspěšné parry ho omráčí. První loot (Skulker Fang, šance na Uncommon). | Nová mechanika (parry) |
| 5:30–6:30 | **Whisperfall** | Za vodopádem svítí krystal. Kdo odbočí, najde **tajnou jeskyni** s lore kamenem a **Titan Shardem**. | Tajemství |
| 6:30–7:30 | **Náhodná událost** | Jedna ze tří: raněný lovec žádá o pomoc (obrana 30 s), **Rift Crack** chrlí elitní nepřátele, nebo kolem proběhne vzácný **Glimmerfox**. | Nečekaná situace |
| 7:30–9:30 | **Gravehorn's Clearing** | **Miniboss GRAVEHORN** (2 fáze). Nabíhá (úhyb do strany), dupe rázovými vlnami (skok). Když narazí do sloupu, na 4 s se zasekne a hráč mu **vyskočí na hřbet** a rozbije **krystal na páteři**. To je první ochutnávka šplhání a weak pointů. | Boss encounter |
| 9:30–10:00 | **Návrat do Citadely** | Loot: **Gravehorn Antler**, Hunter Skill Point. **Forge:** Brann vykove první vlastní zbraň. Na World Map pulzuje červeně **ASHEN VALLEY: TITAN DETECTED**. | Upgrade a nový cíl |

Po 10 minutách hráč ví, **kam směřuje** (Ember Colossus na mapě), **jak se zlepšovat** (Forge, skill tree) a **že svět skrývá tajemství** (vodopád).

---

## 4. Core gameplay loop

![Titan climbing](https://d8j0ntlcm91z4.cloudfront.net/user_3Gqcr0XXTvKdyVYMJhbBfyh7i3j/hf_20260925_124435_15e65474-9483-47a3-93fe-81faf0f34d91_min.webp)

Tři vnořené smyčky:

```
MIKRO (30 s – 2 min)          STŘEDNÍ: VÝPRAVA (15–25 min)            MAKRO (dny – týdny)
┌────────────────────┐        ┌───────────────────────────────┐       ┌──────────────────────────┐
│ pohyb → objev      │        │ HUB → výběr výpravy            │       │ crafting → nové schopnosti│
│   ↓                │        │   ↓                            │       │   ↓                       │
│ souboj → loot      │  ───►  │ cesta → průzkum → monstra      │ ───►  │ Rank Trial → nový region  │
│   ↓                │        │   ↓                            │       │   ↓                       │
│ odměna/tajemství   │        │ event / tajná oblast           │       │ silnější Titan → Titan Form│
│   ↓ (opakuj)       │        │   ↓                            │       │   ↓                       │
└────────────────────┘        │ MINIBOSS → upgrade             │       │ Echo Hunts, sezóny, eventy│
                              │   ↓                            │       └──────────────────────────┘
                              │ TITAN ENCOUNTER → boss fight   │
                              │   ↓                            │
                              │ Titan Materials → návrat do hubu│
                              └───────────────────────────────┘
```

**Jak výprava zajišťuje „nečekané situace“ bez procedurálního terénu:**
Každý region je ručně postavený, ale obsahuje **Encounter Sloty** (například 14) a **Event Sloty** (například 6). Při startu serveru výpravy se náhodně vybere:
- které sloty jsou aktivní a kteří nepřátelé v nich jsou (z poolu regionu),
- **Modifikátor výpravy**, například *Popelová bouře* (horší viditelnost, ohniví nepřátelé silnější, +50 % Ember materiálů) nebo *Titanova migrace* (Titan přechází regionem, dá se na něj naskočit),
- 1–2 **world eventy** během výpravy (viz GDD).

**Pravidlo 3 minut:** designér ověřuje na mapě výpravy, že na každé trase nejsou mezi dvěma „zajímavými momenty“ víc než 3 minuty. Může jít o souboj, objev, vzácný drop, event, nové místo nebo boss.

---

## 5. Combat

**Filozofie:** rychlý, čitelný a skill-based souboj. Nesmí to být button spam. Každý útok nepřítele má čitelnou přípravu a každá správná reakce hráče je odměněná.

### Ovládání

| Akce | PC | Gamepad | Mobil |
|---|---|---|---|
| Light Attack | LMB | X / □ | Tlačítko Útok |
| Heavy Attack (hold = charge) | RMB hold | Y / △ | Podržet Útok |
| Dash / úhyb | Q | B / ○ | Tlačítko Dash |
| Block (hold) / Parry (tap v čase) | F | RB / R1 | Tlačítko Štít |
| Air Attack | útok ve vzduchu | útok ve vzduchu | útok ve vzduchu |
| Ability 1 / 2 | 1 / 2 (nebo E/R) | RT / LT | Tlačítka schopností |
| Ultimate | 3 | LB + RB | Tlačítko Ult |
| Titan Form | T (když je bar plný) | D-pad nahoru | Velké zářící tlačítko |
| Lock-on | MMB / Tab | R3 | Tap na nepřítele |

### Klíčové mechaniky

- **Frame data:** každý útok má fáze *startup / active / recovery* v ms, definované v datech (`Shared/Config/Weapons`).
- **Perfect Dodge:** pokud by nepřítel zasáhl hráče v prvních **0,12 s** dashe, spustí se *Perfect Dodge*. Následuje krátké zpomalení (jen vizuál na klientovi) a server otevře **Riposte okno** (1,2 s, další útok +50 % dmg). Hráč získá **+8 % Titan Energy**.
- **Parry:** Block zmáčknutý **do 0,15 s** před zásahem. Nepřítel dostane velké **Poise damage**, hráč Titan Energy. Parry funguje jen na **žlutě blikající** útoky. **Červeně** blikající útoky jsou unblockable a musí se uhnout.
- **Poise a stagger:** nepřátelé mají Poise bar. Po jeho rozbití je nepřítel sražený a následuje **Execution** (finisher animace + velký loot bonus).
- **Air combat:** launcher (heavy nahoru) vyhodí nepřítele do vzduchu. Air combo drží hráče ve vzduchu (hang time).
- **Lock-on:** soft aim-assist (kužel 35°) je vždy aktivní, hard lock je volitelný. Nutné pro mobil a gamepad.
- **Tři zdroje:** *Stamina* (dash, block, šplhání), *Ultimate charge* (plní se dealováním dmg) a **Titan Energy** (plní se **jen skillem**: perfect dodge, parry, weak point, execution, zásah Titána).

### Juice („silný útok musí působit silně“)

| Prvek | Light hit | Heavy hit | Weak point / execution |
|---|---|---|---|
| Hit stop | 40 ms | 90 ms | 140 ms |
| Camera shake (trauma) | 0,08 | 0,25 | 0,45 |
| Particles | jiskry | jiskry, prach, úlomky | záblesk, shockwave, jiskry |
| Zvuk | vrstvený impact (±8 % pitch) | + sub-bass | + reverb tail, tlumení hudby o 3 dB |
| Nepřítel | flinch | knockback | stagger nebo smrtící rozpad |
| Prostředí | – | praskliny (decal) a prach | praskliny, úlomky, crater decal |

### Anti-exploit
Klient předvídá animaci a VFX okamžitě. Serveru pošle jen **„použil jsem útok X na cíle [ids]“**. Server ověří cooldown, combo timing, vybavenou zbraň, **dosah přes historii pozic** (lag compensation 250 ms) a **damage počítá sám**. Klient nikdy neposílá čísla damage.

---

## 6. Movement

**Hráč musí mít radost už jen z pohybu.** Movement je PHASE 1 a je implementovaný v této větvi (viz [04_PHASE1_MOVEMENT.md](04_PHASE1_MOVEMENT.md)).

| Schopnost | Popis | Výchozí ladění |
|---|---|---|
| **Sprint** | Hold Shift / toggle L3 / tlačítko na mobilu. Nestojí staminu, protože pohyb po světě má být radost. | 16 → 28 studs/s, plynulé zrychlení |
| **Dash** | Směrový výpad 8 směry (bez vstupu dopředu). Později i-frames pro Perfect Dodge. | 76 studs/s, 0,19 s, 20 staminy, cd 0,35 s |
| **Slide** | Při sprintu. Nízký hitbox (podjede překážky), z kopce zrychluje, slide-jump drží hybnost. | start 48, max 72, 0,9 s |
| **Wall Run** | Ve vzduchu podél stěny. Lehký oblouk, kamera se nakloní. | 36 studs/s, max 1,4 s, 16 staminy/s |
| **Wall Jump** | Odraz od stěny, řetězení mezi dvěma stěnami (komín). Ze stejné stěny dvakrát za sebou nejde. | 44 ven, 52 nahoru |
| **Mantle** | Automatický výšvih na hranu až 4,5 studu nad chodidly (ze skoku tedy asi 12 studů od země). | 0,2–0,4 s |
| **Grapple** | Auto-targeting na Grapple Pointy (kužel před kamerou). Funguje i na **pohyblivé** body, což je základ pro Titan Grapple. | dosah 150, tah 100 studs/s, cd 0,9 s |
| **Air Dash** | *Upgrade* (Movement tree). Jeden za skok. | 62 studs/s, 0,17 s |
| **Titan Grapple** | *PHASE 4.* Zavěšení na kotevní body Titána a přechod do šplhání. | – |
| **Coyote time** | Skok 0,12 s po opuštění hrany. Hráč nevidí, ale cítí ho. | 0,12 s |

**Principy pocitu z pohybu:**
1. **Zachování hybnosti:** wall jump, grapple i slide-jump předávají rychlost do vzduchu (*Launch*), takže řetězení je vždy rychlejší než běh.
2. **Řetězení:** sprint → slide → skok → wall run → wall jump → grapple → air dash → mantle. Žádná schopnost nezastaví flow.
3. **Kamera jako zpětná vazba:** FOV se zvětšuje s rychlostí, kick při dashi, náklon při wall runu, trauma shake při tvrdém dopadu.
4. **Stamina jako rozhodnutí, ne brzda:** regenerace je rychlá (32/s po 0,65 s). Stamina ale omezuje nekonečné wall-runy a na Titánech šplhání.

---

## 7. První Titan: EMBER COLOSSUS

[![Ember Colossus](https://d8j0ntlcm91z4.cloudfront.net/user_3Gqcr0XXTvKdyVYMJhbBfyh7i3j/hf_20260925_124434_c8f11951-f949-4327-a6a1-95ef8308be2f_min.webp)](https://d8j0ntlcm91z4.cloudfront.net/user_3Gqcr0XXTvKdyVYMJhbBfyh7i3j/hf_20260925_124434_c8f11951-f949-4327-a6a1-95ef8308be2f.png)

> **EMBER COLOSSUS: THE MOUNTAIN THAT WALKS**
> Čedičový obr s lávou v žilách. Ve hrudi pod obsidiánovým pancířem pulzuje **Magmové srdce**, v němž je úlomek Srdcehvězdy.

- **Výška:** asi 180 studů (hráč má 5,5), silueta shrbené hory s korunou sopečných věží.
- **Aréna: Kalderová pánev.** Kráter s lávovým jezerem uprostřed, čedičové terasy v několika výškách, **obsidiánové pilíře** (zničitelné krytí), **gejzíry** (vystřelí hráče vzhůru, třeba až na rameno Titána) a **3 řetězové harpuny** na okraji arény.
- **Intro (poprvé asi 8 s, lze přeskočit):** kamera přeletí kalderu, hudba utichne, láva začne bublat. Colossus se zvedne z jezera, z těla mu stéká magma a zařve. Title card **EMBER COLOSSUS / THE MOUNTAIN THAT WALKS**. **Při opakování jen 2 s:** řev a jméno.

### Fáze

| Fáze | HP | Chování | Co musí hráči dělat |
|---|---|---|---|
| **I. Probuzení** | 100–70 % | Stojí v jezeře. *Magma Sweep* (máchnutí paží přes arénu), *Meteor Toss* (3–5 meteorů s červenými kruhy), *Ground Pound* (rázové prstence). | Přeskakovat a předashovat paži. Po Ground Poundu mu zůstane **pěst 3 s zaseklá v terase**. Hráči **vyběhnou po paži** a rozbijí **krystalové brnění na předloktí**. **Harpuny** přišpendlí paži na 8 s a vytvoří rampu. |
| **II. Rozžhavení** | 70–35 % | Vyleze z jezera, **láva stoupá** a aréna se zmenšuje. *Lava Breath* (kuželový plamen), *Eruption* (z hřbetních ventilů padají úlomky), **Grab** (chytí hráče). | Schovat se za obsidiánové pilíře (po 2 zásazích se roztaví). **Gejzíry** vystřelí hráče na ramena, kde **Titan Grapple** kotvy vedou k ventilům na zádech a hráči je rozbijí. **Zachránit chyceného spoluhráče** úderem do zápěstí (solo: vymanit se staminou). |
| **III. Srdce hory** | 35–0 % | Hrudní pancíř praskne a odhalí **Magmové srdce**. Colossus pravidelně padá vyčerpaný na koleno. **Cataclysm:** nebe zčervená a padají meteory všude. | Zaútočit na srdce, když klečí. Při Cataclysmu **vylézt na jeho tělo** (jediné bezpečné místo) nebo se schovat ve věži. **Titan Form** umožní *Titan Clash* (přetlačování paží). |

**Konec:** po zničení srdce Colossus klesne do lávy a ta kolem něj ztuhne v kámen (3s cinematic). Z jeho hrudi vyletí esence do všech zúčastněných a spustí se **TITAN FORM UNLOCKED: EMBER**.

### Loot
| Drop | Šance | Použití |
|---|---|---|
| Ember Heart | 100 % při prvním zabití, pak 35 % | Ember Greatsword/Blades, Ember Transformation |
| Colossus Basalt | 100 % (3–6 ks) | Ember Armor |
| Magma Core Fragment | 60 % | Upgrady Titan Form |
| **Pristine Ember Heart** *(secret)* | **Skill drop:** všech 6 krystalů rozbitých před fází III | Mythic *Mountainbreaker* |
| **Ashen Crown Shard** *(secret)* | 1 % | Kosmetická koruna s aurou popela |

### Audio identita
Taiko bubny, hluboké žestě a sbor. **Fáze I:** jen perkuse. **Fáze II:** přidají se žestě a sbor. **Fáze III:** plný orchestr a **sub-bass tep synchronizovaný s pulzem srdce** (vizuální pulz = beat hudby). Zvuky Titána: drcení kamene, syčení magmatu a řev, který zní jako velryba smíchaná s praskáním ohně.

### Ember Titan Form (odměna)

[![Titan Form](https://d8j0ntlcm91z4.cloudfront.net/user_3Gqcr0XXTvKdyVYMJhbBfyh7i3j/hf_20260925_124434_28716c1b-ca23-41e6-b652-8a9d2818988a_min.webp)](https://d8j0ntlcm91z4.cloudfront.net/user_3Gqcr0XXTvKdyVYMJhbBfyh7i3j/hf_20260925_124434_28716c1b-ca23-41e6-b652-8a9d2818988a.png)

**Aktivace:** kamera se oddálí, země se otřese, esence obtočí hráče a proběhne transformace. Hráč je **3,5× větší**, má **20 s** trvání, 50% redukci damage, nelze ho omráčit a má jiný moveset, kameru i zvuky:

| Vstup | Útok |
|---|---|
| Light | **Titan Punch** (3-hit combo, každý úder otřese zemí) |
| Heavy | **Lava Slam** (skok a dopad, kruh lávy) |
| Ability 1 | **Meteor Throw** (vytrhne ze země balvan a hodí ho) |
| Ability 2 | **Ground Rupture** (linie praskajících lávových trhlin) |
| Ultimate | **Inferno** (exploze, která formu předčasně ukončí za masivní damage) |

**Vzácnost:** plný bar trvá **2,5–4 minuty dobré hry**, protože se plní jen skillem. Při boji s Titánem se plní 2× rychleji, takže každý hráč má v Titan fightu 1–2 transformace. **Transformace je moment, ne rotace.**

---

## 8. První mapa: vertical slice

![Greenwild](https://d8j0ntlcm91z4.cloudfront.net/user_3Gqcr0XXTvKdyVYMJhbBfyh7i3j/hf_20260925_124434_b0e0e465-ad08-459c-85c1-280053aadf95_min.webp)

Vertical slice běží ve **2 places**: **Citadel** (hub + prolog) a **The Wilds I** (Greenwild + Ashen Valley propojené průsmykem).

### GREENWILD (asi 2 000 × 2 000 studů), Rank E–D
| Zóna | Obsah |
|---|---|
| **Waystone Outpost** | Příchod portálem, obchodník, fast-travel Waystone. |
| **Rootway** | Parkour po obřích kořenech (tutorial pohybu v prostředí), grapple přes rokli. |
| **Mossfall Ruins** | Ruiny starého království, hnízda Brutů. **Puzzle:** natočit 3 sochy podle stínů a otevřít trezor (treasure room). |
| **Skull Hollow** | Lebka dávného Titána zarostlá v kopci. Očním důlkem se vchází do **podzemní jeskyně** se vzácným tvorem **Glimmerfox** (utíká, chycení dává kosmetiku). |
| **Whisperfall** | Vodopád se skrytou jeskyní, lore kámen, Titan Shard. |
| **Spore Marsh** | Spore Spitteři, jedovaté tůně, vzácné byliny. |
| **Gravehorn's Clearing** | Aréna minibosse, kruh sloupů (náraz do nich ho omráčí). |
| **The Ashgate** | Průsmyk do Ashen Valley. Otevře se po poražení Gravehorna. |

### ASHEN VALLEY (asi 2 500 × 2 500 studů), Rank D–C

![Ashen Valley](https://d8j0ntlcm91z4.cloudfront.net/user_3Gqcr0XXTvKdyVYMJhbBfyh7i3j/hf_20260925_124434_ca79af5d-2bd5-459f-bfc5-7663b8834c28_min.webp)

| Zóna | Obsah |
|---|---|
| **Cinder Camp** | Předsunutý tábor lovců, Waystone, polní kovadlina. |
| **Ruiny Kessrinu** | **Město z prologu**, teď v troskách. Hráč stojí v místě, kde začínal, a v ulici je otisk Titanovy nohy. Vedlejší quest *Odina ztracená medaile*. |
| **Footprint Fields** | Krátery po Colossových krocích, v každém mini-encounter nebo loot. |
| **Magmové řeky a obsidiánové věže** | Lávový parkour, grapple pointy, heat hazard. |
| **Spálená strážní věž** | Vyhlídka a spawn world eventů. |
| **Kalderová pánev** | Aréna Ember Colosse. |
| **Výheň Prvního kováře** *(secret)* | Za lávopádem je obsidiánová pečeť, kterou rozbije **jen Ember Titan Form**. Oblast tak dává důvod se vrátit po poražení Titána. |

### Nepřátelé (3 archetypy × regionální varianty)

![Enemies](https://d8j0ntlcm91z4.cloudfront.net/user_3Gqcr0XXTvKdyVYMJhbBfyh7i3j/hf_20260925_124434_918b37a4-2ddb-4fa9-b562-0c4ef6971c99_min.webp)

| Archetyp | Greenwild | Ashen Valley | Učí |
|---|---|---|---|
| **Skulker** (rychlý, slabý, smečky) | Thornskulker | Cinderskulker | Základní útok a úhyb před výpadem |
| **Brute** (pomalý, obrněný zepředu, parry-able) | Mossback Brute | Magma Brute | Parry, poziční hra (slabá záda) |
| **Spitter** (střelec, drží odstup) | Spore Spitter | Ember Wisp | Mobilita (dash a grapple k němu) |

**Produkční výhoda:** jedna AI a animace na archetyp, region mění jen model, element a 1 speciální útok.

**Miniboss GRAVEHORN**: obří kanec-jelen s krystalem Titána prorostlým páteří ([koncept](https://d8j0ntlcm91z4.cloudfront.net/user_3Gqcr0XXTvKdyVYMJhbBfyh7i3j/hf_20260925_124435_ff449b60-e9e5-4e8f-ab2f-11c21f68b05c.png)). Učí weak pointy, využití prostředí a první „šplhání“.

---

## 9. Progression

| Osa | Jak se postupuje | Proč je zábavná |
|---|---|---|
| **Hunter Rank** E → D → C → B → A → S → SS → **TITAN** | **Rank Trials** kombinují výkon, ne jen XP (viz níže). | Rank je důkaz skillu, ne času. |
| **Vybavení** | Crafting z Titan Materials, upgrade **Resonance** (+1 až +10). | Každý Titan = nová sada s unikátní mechanikou. |
| **Weapon Skill Trees** | Body z **Weapon Mastery** (používáním zbraně). | Build a styl. |
| **Obecné stromy** (Movement, Hunter, Titan, Survival) | Body z ranků a **z průzkumu** (Titan Relics v tajných oblastech). | **Průzkum dává sílu.** |
| **Titan Forms** | Odemknutí poražením Titána, upgrady esencí. | Sbírka proměn. |
| **Codex a Muzeum** | Trofeje, bestiář, lore. | Sběratelství, tituly, kosmetika. |

**Požadavky ranků (příklad):**
- **E → D:** dokončit Greenwild, porazit Gravehorna, 10× Perfect Dodge, objevit 3 tajemství.
- **D → C:** porazit Ember Colosse, vyrobit Ember předmět, splnit Rank Trial *Zkouška popela* (sólo aréna na čas).
- **C → B:** Storm Wyrm, Titan Form mastery výzva, 50% průzkum Greenwildu i Ashen Valley.
- **S → SS:** Echo Titáni bez smrti v squadu.
- **SS → TITAN:** Celestial Titan a finální Trial. Odměnou je prestižní aura a zlaté jméno.

**Horizontální síla:** růst čísel je záměrně mírný (vybavení je spíš sidegrade s mechanikou). Skill tak zůstává nejdůležitější a starý obsah neztrácí smysl.

---

## 10. Art direction

![Hunter Citadel](https://d8j0ntlcm91z4.cloudfront.net/user_3Gqcr0XXTvKdyVYMJhbBfyh7i3j/hf_20260925_124433_20e8994c-a383-48d7-ae76-49fc0f13770f_min.webp)

**Styl:** *„Painted Stylized Roblox“*. Chunky, čisté stylizované meshe s ručně malovanými gradienty a silnou siluetou. **Ne** Minecraft/voxel, **ne** levné free-modely, **ne** fotorealismus.

### Pravidla
1. **Silhouette > detail.** Každý Titán musí být poznat z 1 000 studů jen podle siluety (Colossus = shrbená hora s korunou věží).
2. **Měřítko je hvězda.** Titáni mají **málo velkých tvarů**, žádný drobný šum. Detail je jen tam, kde hráč leze (úchyty, krystaly).
3. **Tvarový jazyk nepřátel:** trojúhelník = agresivní (Skulker), čtverec = tank (Brute), kruh = střelec nebo levitace (Spitter).
4. **Čitelné nebezpečí:** červená = uhni, žlutá = parry, bílá nebo azurová = weak point. Barvy jsou **rezervované**, prostředí je nepoužívá pro dekoraci.
5. **Hráči:** proporce Roblox R15, lehce stylizované. **Zbraně 1,3× větší** kvůli čitelnosti.

### Barevný scénář regionů
| Region | Paleta | Nálada |
|---|---|---|
| Hunter Citadel | slonovina, zlatá, teal | bezpečí, velkolepost |
| Greenwild | smaragd, teal stíny, teplé slunce | zvědavost |
| Ashen Valley | uhel, karmín, oranžová emise | hrozba, horko |
| Storm Archipelago | fialová, azurová, bílé blesky | závrať |
| Frozen Crown | bílá, ledová modř, růžový úsvit | ticho, osamění |
| Sunken Kingdom | hluboký teal, bioluminiscence | tajemno |
| Titan Graveyard | kost, sépie, přízračná zelená | melancholie |
| Void Frontier | černá, magenta, inverze | děs, zkreslení |
| Celestial Kingdom | bílá, zlatá, pastely | transcendence |

### Technika v Robloxu
- **Lighting:** `Future` (High) s fallbackem `ShadowMap`. **Atmosphere** per region (Density a Haze prodávají měřítko), **ColorCorrection** per region s plynulým přechodem, **Bloom** s vysokým thresholdem (svítí jen emise a neon), jemné **SunRays**, **Clouds** na Terrain.
- **Materiály:** `SmoothPlastic` a vlastní **MaterialVariants** (ručně malované, tileable). `SurfaceAppearance` jen na hero assetech (Titáni, zbraně).
- **VFX:** stylizované flipbook particly, **3 vrstvy** (záblesk nebo jádro, tvar, doznívající kouř). VFX spoluhráčů mají nižší opacity než vlastní, aby zůstaly čitelné v co-opu.
- **UI:** „cinematic minimal“. Tenké linie, krémová bílá a **ember oranžová** jako akcent, tmavé průsvitné panely, font Montserrat nebo Builder Sans ([mockup HUD](https://d8j0ntlcm91z4.cloudfront.net/user_3Gqcr0XXTvKdyVYMJhbBfyh7i3j/hf_20260925_124434_157c7519-471f-48b3-acc5-19e9c74cc96d.png)).

---

**Další dokumenty:**
- [02_GDD.md](02_GDD.md): kompletní Game Design Document
- [03_DEVELOPMENT_PLAN.md](03_DEVELOPMENT_PLAN.md): architektura a 12 fází vývoje v Roblox Studiu
- [04_PHASE1_MOVEMENT.md](04_PHASE1_MOVEMENT.md): implementace PHASE 1 (setup, ovládání, testování)
