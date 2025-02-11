Loads JSON to create typed classes with inheritence

Example Dir Structure
/game/                     # 🔥 Root directory for all game-related content
│── /entities/             # 🔥 All in-game entities (Characters, Objects, Items, Abilities)
│   │── /characters/       # Player, NPCs, Enemies, Bosses
│   │   │── /player/       # Player-specific logic & scenes
│   │   │── /enemies/      # Standard enemies
│   │   │── /bosses/       # High-tier enemies
│   │   │── /npcs/         # Non-combat NPCs & companions
│   │   │── /companions/   # AI-controlled allies
│   │── /world_objects/    # Interactable objects in the world
│   │   │── /interactable/ # Chests, levers, doors
│   │   │── /destructible/ # Breakable barrels, crates
│   │   │── /static/       # Objects with no interaction (decor)
│   │── /abilities/        # Melee, Ranged, Spells, Utility
│   │   │── /melee/        # Swords, Axes, Daggers
│   │   │── /ranged/       # Bows, Guns
│   │   │── /spells/       # Offensive, Defensive, Buffs
│   │   │── /utility/      # Dash, Teleport, Heals
│   │── /items/            # Weapons, Armor, Potions
│   │   │── /weapons/      # Melee & Ranged Weapons
│   │   │── /armor/        # Helmets, Chestplates, Shields
│   │   │── /consumables/  # Potions, Scrolls, Food
│   │   │── /crafting/     # Materials, Components
│   │── /projectiles/      # Arrows, Fireballs, Bullets
│   │── /status_effects/   # Buffs, Debuffs, Poisons
│── /gameplay/             # 🔥 Game mechanics & logic
│   │── /combat/           # Attack, Damage, Hit Detection
│   │── /quests/           # Quest System & Objectives
│   │── /loot/             # Loot Tables, Drops
│   │── /ai/               # Enemy AI, Pathfinding, Behavior Trees
│   │── /multiplayer/      # Networking & Multiplayer Systems
│── /world/                # 🔥 Levels, Maps, Environment
│   │── /maps/             # Overworld, Dungeons
│   │── /tilesets/         # Sprites & Tilemaps
│   │── /regions/          # Towns, Zones, Dungeons
│   │── /spawners/         # Enemy, Loot, NPC Spawn Points
│── /ui/                   # 🔥 UI Elements (Menus, HUD, Inventory)
│   │── /hud/              # Health, Mana, Buffs
│   │── /inventory/        # Player Equipment & Items
│   │── /menus/            # Main Menu, Settings, Pause
│   │── /dialogs/          # NPC Dialog Boxes
│── /assets/               # 🔥 All art, sound, animations, effects
│   │── /sprites/          # 2D Sprites & Animations
│   │── /models/           # 3D Models (if applicable)
│   │── /audio/            # Sound FX, Music, Voice
│   │── /effects/          # Particle Effects, Shaders
│── /scripts/              # 🔥 Global helper scripts & utilities
│   │── JSONLoader.gd      # Loads JSON files into objects
│   │── GameManager.gd     # Controls game state & logic
│   │── CombatSystem.gd    # Damage, Hit Detection, AI
│   │── SaveLoad.gd        # Save & Load System
│── /data/                 # 🔥 JSON Config & Data Files
│   │── /characters.json   # Player & NPC Stats
│   │── /items.json        # Item stats & properties
│   │── /abilities.json    # Spells & Skills
│   │── /quests.json       # Quest Information
│── /networking/           # 🔥 Multiplayer & Online Features
│   │── Server.gd          # Server-side logic
│   │── Client.gd          # Client-side networking
│   │── SyncManager.gd     # Handles multiplayer sync
│── /core/                 # 🔥 Engine-Level Scripts (Autoloads, Constants)
│   │── Main.gd            # Main game loop
│   │── Constants.gd       # Global game constants
│   │── InputManager.gd    # Controls Input Handling
│   │── EventBus.gd        # Global Event Handling
