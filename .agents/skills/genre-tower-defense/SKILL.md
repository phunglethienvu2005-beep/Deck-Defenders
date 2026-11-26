---
name: genre-tower-defense
description: Apply tower defense design principles to Deck Defenders in Roblox. Use for Hero roles and placement, enemy paths and waves, combat, Yen, and DDA design.
---

# Tower Defense for Deck Defenders

Local adaptation of the engine-independent ideas in [thedivergentai/game-development-agentic-skills](https://github.com/thedivergentai/game-development-agentic-skills/tree/db004d74c40686ca2f7a35fe067b119a9cda593e/skills/godot-genre-tower-defense).

- Trace the loop from preparation and spending to wave spawn, enemy travel, defense, and rewards. Check that early waves communicate the available choices and later waves test them.
- Keep Hero roles distinct and readable. For targeting changes, define progress along the existing route and a deterministic tie-breaker. Profile real target acquisition costs before changing timing or caching.
- Validate ownership, placement, affordability, Hero limits, and reward eligibility on the server. Ward against counting kills during cleanup or awarding Yen twice.
- Reuse stage and wave configuration. Validate spawn timing, BaseHealth consequences, and the boss phase against the configured stage.
- Compare Fixed and DDA on the same build, stage and baseline. Inspect results and applied multipliers separately from simulation or player-study conclusions.
- Use project Roblox/Luau APIs and existing conventions. Treat new mechanics, balancing changes and non-Roblox references as outside a maintenance request unless explicitly authorized.
