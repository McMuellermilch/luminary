# Luminary — Claude Code Instructions

## Project Overview

**Luminary** is a top-down action-RPG built with Love2D (Lua), inspired by Pokémon and Secret of Mana.
Platform: Mac & PC. The player collects creatures called Lumins and rekindles Beacon Towers to restore light to a dim world.

See `/storybook/` for the full game design document.

---

## Tech Stack

- **Engine**: Love2D 11.x (Lua 5.1)
- **Maps**: Tiled Map Editor → STI (Simple Tiled Implementation)
- **Collision**: bump.lua
- **Animation**: anim8
- **Camera**: STALKER-X
- **Timers / tweening**: hump.timer
- **Events**: hump.signal
- **Save serialization**: Ser
- **UI**: Custom immediate-mode

All third-party libraries live in `/game/lib/`.

---

## Project Structure

```
/game              — Love2D project root (run `love game` from repo root)
  main.lua         — Entry point
  conf.lua         — Love2D config (window size, title, etc.)
  /src
    /core          — Utilities, event bus, math helpers
    /states        — Stack-based state machine + all game states
    /entities      — Base Entity class + component mixins
    /world         — MapManager, camera, warp system
    /combat        — Combat engine, ability system
    /creatures     — Lumin data loader, evolution, party management
    /ui            — HUD, dialogue box, menus, inventory
    /data          — Pure Lua data tables (creatures, items, regions, moves)
    /audio         — MusicManager, SFX wrapper
    /save          — Serialization, save/load slots
  /lib             — Third-party libraries (never modify)
  /assets
    /sprites       — PNG spritesheets (exported from Aseprite)
    /maps          — Tiled .tmx and .tsx files
    /audio
      /music       — .ogg stems per region
      /sfx         — .ogg / .wav sound effects
    /fonts
    /shaders       — GLSL shader files
/storybook         — Game design documents (MD files, not code)
```

---

## Architecture Principles

### State Machine (Stack-Based)
All game states are managed via a stack in `src/states/statemanager.lua`. States are pushed and popped — never replaced directly unless transitioning the full stack. Every state implements:
```lua
function State:enter(params) end
function State:exit() end
function State:update(dt) end
function State:draw() end
function State:keypressed(key) end
```

### Entity System (OOP + Component Mixins)
Base `Entity` class in `src/entities/entity.lua`. Components are mixed in at construction via `entity:addComponent(name, component)`. Do **not** introduce a full ECS framework — the mixin approach is intentional.

### Data vs Code Separation
All game data (creature stats, move lists, region info, item definitions) lives in `src/data/` as plain Lua tables. Game logic code **reads** data but never contains data inline. This keeps content editable without touching logic.

### Event Bus
Cross-module communication goes through `src/core/events.lua` (hump.signal wrapper). Do not create direct dependencies between state modules. Use events for: combat results, capture events, Beacon rekindling, party changes.

---

## Coding Conventions

- **Lua style**: 2-space indentation, snake_case for variables and functions, PascalCase for class names
- **Require paths**: Always use the full path from game root (e.g., `require("src.states.overworld")`)
- **No global state**: All state is owned by the active State object or passed explicitly. No `_G` pollution.
- **Error handling**: Use `assert()` for programmer errors. Graceful fallbacks only at load-time (missing asset = log + placeholder, not crash).
- **Comments**: Only where logic is non-obvious. Data tables should be self-documenting.

---

## Running the Game

```bash
love game
```

Run from the repository root. Requires Love2D 11.x installed.

---

## Phase Completion Workflow

When a phase is finished:
1. Commit all changes with a descriptive commit message referencing the phase
2. Push to `origin/main`
3. Close the corresponding GitHub issue: `gh issue close <number>`
4. **Stop. Do not begin the next phase.** Wait for explicit instruction to continue.

## Never Do

- Do not run Love2D builds. Stop and tell the user to run `love game` themselves.
- Do not modify files in `/game/lib/` (third-party libraries).
- Do not put game data (numbers, strings, creature definitions) directly in logic files.
- Do not use global variables.
- Do not introduce an ECS framework — use the component mixin pattern.
- Do not begin a new phase without being explicitly asked to do so.
