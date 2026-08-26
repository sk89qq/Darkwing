# VOIDA Network RPC Manifest & Remote Communication Contract

## 1. RemoteEvents (`game.ReplicatedStorage.VOIDA_Network.Events`)

| Identifier | Sender | Receiver | Payload Signature | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `StateUpdate` | Server | All Clients | `{ state: string, timer: number, sectorId: string }` | Synchronizes round stage, countdown, and active sector rules. |
| `PlayerAction` | Client | Server | `{ actionType: string, targetId: string?, timestamp: number }` | Relays player inputs (ability cast, dodge, interact) for server validation. |
| `CombatFeed` | Server | All Clients | `{ attacker: string, victim: string, damage: number, isCrit: boolean }` | Displays visual floating numbers, hit-markers, and kill-feed alerts. |
| `Notification` | Server | Target Client | `{ message: string, alertType: "info" \| "warning" \| "reward", duration: number }` | Pushes toast notifications to the player HUD. |

---

## 2. RemoteFunctions (`game.ReplicatedStorage.VOIDA_Network.Functions`)

| Identifier | Caller | Callee | Request Params | Return Signature | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RequestPlayerData` | Client | Server | `()` | `{ coins: number, level: number, inventory: table, stats: table }` | Fetches full initial player profile on join/respawn. |
| `PurchaseItem` | Client | Server | `{ itemId: string, quantity: number }` | `{ success: boolean, newBalance: number, error: string? }` | Validates and executes economy transactions securely on server. |
