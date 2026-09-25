# TITANBOUND *(pracovní název, návrh: TITANWAKE)*

Co-op akční Roblox hra o lovcích, kteří loví Titány velké jako hory, šplhají po nich, trhají jim brnění a na pár vteřin se sami stávají Titánem, kterého porazili.

![Key art](https://d8j0ntlcm91z4.cloudfront.net/user_3Gqcr0XXTvKdyVYMJhbBfyh7i3j/hf_20260925_124434_785df3df-4552-422f-835b-6778f365ea67_min.webp)

## Dokumentace
| Dokument | Obsah |
|---|---|
| [docs/01_KONCEPT.md](docs/01_KONCEPT.md) | Fantasy, prvních 30 s, prvních 10 min, core loop, combat, movement, Ember Colossus, první mapa, progression, art direction, návrhy názvu |
| [docs/02_GDD.md](docs/02_GDD.md) | Game Design Document (zbraně, 7 Titánů, climbing, Titan Form, AI, eventy, ekonomika, monetizace, UI, audio, výkon, live-ops, KPI) |
| [docs/03_DEVELOPMENT_PLAN.md](docs/03_DEVELOPMENT_PLAN.md) | Architektura a 12 fází vývoje v Roblox Studiu |
| [docs/04_PHASE1_MOVEMENT.md](docs/04_PHASE1_MOVEMENT.md) | PHASE 1: spuštění, ovládání, soubory, testování |
| [docs/ART.md](docs/ART.md) | Concept art (Higgsfield) |

## Rychlý start
```bash
rokit install                                        # rojo, selene, stylua, luau-lsp, lune
rojo build default.project.json -o Titanbound.rbxlx  # otevři v Roblox Studiu, Play
# nebo živě: rojo serve + Rojo plugin ve Studiu
```
V Game Settings nastav **Avatar Type: R15**. Detaily jsou v [docs/04_PHASE1_MOVEMENT.md](docs/04_PHASE1_MOVEMENT.md).

## Stav
- ✅ **PHASE 1: Movement Prototype.** Sprint, dash, air dash, slide, wall run, wall jump, mantle, grapple, server validace, Movement Lab s časovkou, touch/gamepad, HUD.
- ⏭️ **PHASE 2: Combat Prototype** (Greatsword a Dual Blades)

## Kvalita
Každý PR projde CI: StyLua, selene, **strict** luau-lsp type-check, Rojo build a runtime smoke testy v Lune.
