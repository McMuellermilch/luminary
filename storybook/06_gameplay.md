# Gameplay Design

## Core Loop

The fundamental experience of Luminary in one sentence:

**Arrive in a dim world, make it bright, and collect the creatures that bloom in the light you've created.**

The loop repeats across all seven regions with escalating complexity:

```
Enter dim region
  → Explore, talk to locals, understand the problem
  → Encounter and capture Lumins (in their dark-region state)
  → Navigate dungeon to reach the Beacon Shard
  → Defeat the Umbral Guardian
  → Rekindle the Beacon Tower
  → Watch the world transform
  → New Lumins emerge in lit region
  → Prepare for next region
```

---

## Exploration

### Overworld Movement

Luma moves through top-down tile-based maps in the style of early Pokémon games (smooth movement, grid-aligned). The overworld is designed to reward exploration — shortcuts unlocked after story progress, hidden paths requiring specific Lumin abilities, optional areas with rare Lumins.

**Lumin Field Abilities**: Outside combat, certain bonded Lumins unlock traversal options:
- **Flare Lumins**: Light up dark passages (allows safe navigation in dark-region caves)
- **Tide Lumins**: Allow water traversal (reach island areas, cross flooded zones)
- **Verdant Lumins**: Allow climbing (scale cliff faces, reach canopy areas)
- **Frost Lumins**: Freeze water surfaces temporarily (create bridges)
- **Spark Lumins**: Power old Lightweaver mechanisms (unlock sealed doors)

This encourages keeping a diverse party rather than only using favourites.

### Visual State of the World

Regions have two visual states implemented via shader overlay:

**Dark state**: A desaturation + darkening filter applied over the tilemap render. Not pitch black — the world is visible but muted, grey-tinged, dim. Luma and her Lumins glow slightly, providing a warm pool of light that follows the player.

**Lit state**: The filter is removed (or replaced with a warm, slightly brightened overlay). Full colour saturation. The transition is the game's signature visual moment: a wave of light spreading from the Beacon Tower outward across the map.

The transition is triggered by the rekindling cutscene and should feel like the most satisfying moment in each region.

---

## Combat

### Design Philosophy

Combat is **action-based** (Secret of Mana style), not turn-based. The player controls their active Lumin directly in a combat arena. Enemies are visible on the overworld — touching one begins combat in a small arena overlaid on the current area.

Combat should feel:
- **Responsive**: Attacks connect immediately, with hit-pause frames
- **Strategic but not slow**: Abilities require timing, not turn waiting
- **Emotionally weighted**: Fighting Umbral creatures should feel sad, not triumphant

### Combat Mechanics

**Active Lumin**: The player directly controls one Lumin. Movement is free (WASD/analog stick). The companion Lumin is AI-controlled (or Player 2 in co-op).

**Basic Attack**: Tap attack button. Quick, low-damage hit. Can chain 3 hits before a short recovery.

**Charge Attack**: Hold attack button. The **charge ring** around the Lumin fills over 1-2 seconds. Release for a powerful hit with a knockback effect. Each Lumin type has a unique charged attack.

**Abilities**: 2-3 abilities per Lumin, mapped to face buttons. Abilities have cooldowns (shown as dimming/brightening rings). Examples:
- Flamewing: *Solar Burst* — nova of fire in all directions; *Wing Shield* — brief invincibility
- Gleamfin: *Tidal Pull* — draws enemies toward Gleamfin; *Depth Flash* — blinds enemies temporarily

**Switching**: Player can swap to companion Lumin with a shoulder button (short swap animation, companion becomes active).

**Light Meter**: Luma has a personal Light Meter separate from Lumin HP. It fills as Lumins land hits and depletes when they take damage. When full, Luma can trigger a **Radiance Burst** — all Lumins glow at full power for 10 seconds, dealing bonus damage and briefly healing.

### Enemy Behavior

Umbral enemies have visible AI states in the overworld:
- **Patrol**: Moving along a path, unaware of player
- **Alert**: Has noticed player, approaches
- **Aggressive**: In combat mode

Enemy types reflect the region's Lumin types twisted by shadow. A shadow version of a Gleamfin pulls the player toward danger rather than toward safety. The mirror-nature of shadow enemies is intentional and hints at the world's deeper lore.

### Umbral Guardian Fights

Boss fights follow a 3-phase structure:
1. **Phase 1**: Guardian is tentative — it attacks, but not at full strength. It is learning the player.
2. **Phase 2**: Guardian becomes more aggressive. A new attack pattern introduced. The arena may change (water rises, ground cracks, darkness deepens).
3. **Phase 3**: The Guardian begins to weaken. Its attacks become more desperate. Visual indication — the darkness around it fragments, revealing hints of light inside. The final blow triggers a cutscene.

After the final blow, there is **no explosion, no death cry**. The Guardian simply... dims. Then dissolves, like shadow when a light is switched on. Small motes of light drift upward from where it stood — echoes of the Lumins it might have been.

---

## The Capture System

### Philosophy

Luma never forces a Lumin into a Lantern. The capture mechanic reflects the game's gentle tone: Lumins choose to come with her.

### Mechanics

**Lightglass Lantern**: The standard capture item. Thrown near a Lumin when it is at low health. The Lumin sees the light inside, approaches, and enters voluntarily.

**Trust Meter**: On throw, a small trust meter appears beside the Lumin. It fills based on:
- How low the Lumin's health is (lower = more receptive)
- Whether the region's Beacon is lit (lit = more trusting)
- Whether Luma has interacted with this Lumin type before (familiarity bonus)
- Luma's own Light Meter level (higher = warmer light = more trust)

If trust reaches 100%, the Lumin enters. If not, it retreats and the Lantern is consumed.

**Special Capture Items**:
- *Warmglass Lantern*: Higher base trust, useful in dark regions
- *Duskglass Lantern*: Required for Void Lumins; contains shadow-light
- *Heartglass Lantern*: Rare; has a very high trust bonus; Lumins sometimes approach voluntarily

**Party Size**: Luma carries an active party of 3 Lumins. Additional bonded Lumins are held at **Lighthouses** — rest stops in each region that act as storage and healing points.

---

## Progression

### Lumin Growth

Lumins gain **Resonance** (the game's equivalent of experience) from:
- Combat (primary source)
- Spending time in a newly-relit region (ambient Resonance gain)
- Emotional bonding moments (cutscenes, rest stops)

Resonance builds toward **Attunement Levels** (equivalent of levels). Each Attunement Level increases base stats and may unlock a new ability.

**Evolution**: Occurs at specific Attunement thresholds when in a lit region. Pip evolves at Attunement 12 (Flamewing) and Attunement 30 (Solwing). Evolution is permanent and cannot be reversed.

### Luma's Progression

Luma herself does not have combat stats — she supports through the Light Meter and Radiance Burst. Her progression is:
- **New Lumin Field Abilities** as she bonds with diverse Lumin types
- **Increased Light Meter capacity** (passively grows as story progresses)
- **Lightkeeper Knowledge** — story-gated abilities like reading Lightweaver text, sensing Beacon Shard locations, and communicating more clearly with Void Lumins

### New Game+ Considerations

After completing the game, a New Game+ mode allows starting over with all bonded Lumins retained but Resonance reset. Beacon Towers remain lit (carrying over from the completed game). This allows exploration of early regions in their lit state from the beginning, revealing content that was previously inaccessible.

---

## The Beacon Cycle (What Changes After Rekindling)

Rekindling a Beacon Tower is the central reward of each region. Here is the full list of changes:

**Immediate (cutscene)**:
- Warm light wave animation spreads across all region maps
- Dark-state shader removed, lit-state shader applied
- Region-specific music stem shifts from the dark version to the lit version
- Umbral Guardian dissolves

**Within minutes (exploration)**:
- Hostile dark-region Lumins calm down and become capturable
- New Lumin species emerge (lit-only encounter tables activate)
- Previously blocked paths open (Lumins with field abilities that only work in lit areas now accessible)
- NPCs gather near the Tower, celebrate, begin rebuilding

**Persistent changes**:
- Healing cost at Lighthouses in the region decreases
- Shop inventory expands (traders return)
- New side quests unlock from grateful locals
- Luma can use the relit Beacon to send/receive letters from Elder Cerin (lore delivery)
- Rare Lightglass Lantern variants become available in that region's shops

---

## Save System

**Autosave**: Triggers on every map warp and after every major story moment (Beacon rekindling, Guardian defeat).

**Manual Save**: Available at any **Lighthouse** in the game. Lighthouses are always safe zones — no enemy encounters inside, full Lumin healing available, party management and Lumin storage accessible.

**Three Save Slots**: Allows multiple playthroughs or backup saves.

---

## Co-op

Two-player local co-op available throughout the entire game. Player 2 controls Sable (and Sable's companion Sleet) directly. Sable joins permanently after the Ashfields (Region 2).

In co-op, both players share the Light Meter. Coordinated attacks between both players' active Lumins build it faster. The Radiance Burst triggers for both players simultaneously.

Co-op does not change the story — Sable is always present in cutscenes from Region 2 onward regardless of co-op mode.
