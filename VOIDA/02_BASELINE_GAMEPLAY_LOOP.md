# VOIDA Baseline Gameplay Loop Specification

## 1. Core Loop State Machine

```
   ┌─────────────────────────────────────────────────────────┐
   │                                                         │
   ▼                                                         │
[ 1. LOBBY & PREPARATION ] ──(Countdown / Matchmaking)──►   │
   │                                                         │
   ▼                                                         │
[ 2. SPAWN & SECTOR INGRESS ] ──(Objective Revealed)──►      │
   │                                                         │
   ▼                                                         │
[ 3. CORE ACTION & ENGAGEMENT ] ──(Timer / Boss / Goal)──►   │
   │  - Combat / Encounters                                  │
   │  - Resource Extraction & Pickups                        │
   │  - Dynamic Modifiers / Hazarding Events                 │
   │                                                         │
   ▼                                                         │
[ 4. EXTRACTION / SETTLEMENT ] ──(Results Calculated)──►     │
   │  - XP & Currency Rewards Allocated                      │
   │  - Persistent Leaderboards Updated                      │
   │  - Inventory State Committed to DataStore               │
   │                                                         │
   └─────────────────────────────────────────────────────────┘
```

---

## 2. Configurable Parameter Matrix (Baseline Tunables)

### Timing & Loop Pacing
- **Lobby Duration (`LOBBY_DURATION_SEC`):** `15.0`
- **Round Duration (`ROUND_DURATION_SEC`):** `180.0`
- **Intermission & Settlement (`INTERMISSION_SEC`):** `10.0`
- **Respawn Delay (`RESPAWN_DELAY_SEC`):** `3.5`

### Player Physics & Movement Feel
- **Base WalkSpeed (`BASE_WALKSPEED`):** `16.0` studs/sec
- **Sprint Speed (`SPRINT_WALKSPEED`):** `24.0` studs/sec
- **Jump Height (`JUMP_HEIGHT`):** `7.2` studs
- **Stamina Depletion Rate (`STAMINA_DRAIN_SEC`):** `15.0` / sec (Max 100)
- **Stamina Recharge Delay (`STAMINA_RECOVERY_DELAY`):** `1.2` sec

### Combat & Action Balance
- **Base Player Health (`BASE_MAX_HEALTH`):** `100.0`
- **Global Damage Multiplier (`GLOBAL_DMG_MULT`):** `1.00`
- **Critical Strike Multiplier (`CRIT_MULT`):** `1.50` (15% base chance)
- **Invulnerability Window on Hit (`I_FRAME_DURATION`):** `0.35` sec

---

## 3. Dynamic Baseline Directives Checklist
- [ ] Directives Set Integration (Awaiting user's descriptive set to apply exact overrides)
- [ ] Server State Manager deployment to `ServerScriptService`
- [ ] Network RPC initialization in `ReplicatedStorage`
- [ ] HUD & Client Controller synchronization in `StarterPlayerScripts`
