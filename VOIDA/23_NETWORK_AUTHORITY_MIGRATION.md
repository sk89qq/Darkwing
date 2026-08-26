# VOIDA — Network Authority Migration

## SOURCE:
Repository security architecture requires server validation of client-originated actions before execution. The existing weapon controller contains `VoidHunterFireWeapon` and `VoidHunterFireScrambler` RemoteEvents.

## OLD:
Remote handlers accepted client-provided ship/component identifiers and performed validation locally inside the weapon controller. Remote naming and security policy were not centralized.

## NEW:
- Added `ReplicatedStorage/Remotes/RemoteManifest.luau` as the canonical remote contract index.
- `VoidHunterFireWeapon` is classified as ClientToServer / RemoteEvent / OwnedShipWeapon.
- `VoidHunterFireScrambler` is classified as ClientToServer / RemoteEvent / OwnedShipUtility.
- Match-state remotes are classified as server-to-client public state; leaderboard is public match state.
- Existing weapon handlers validate player lifecycle, ship ownership, ship identity, weapon existence, component identity, weapon capability, aim-vector type, request rate, cooldown, and energy before firing.

## TEST:
- Direct inspection of `VoidHunterWeaponController` confirmed ownership validation through `ShipRegistry.IsOwner`.
- Remote handlers apply request rate limiting.
- Weapon type is derived from `ComponentAuthority` + `Components.Types`, not from client-supplied type strings.
- Full runtime security penetration testing is not available in the current environment.

## STATUS:
IMPLEMENTED / PARTIAL

## FUTURE AGENT NOTE:
Treat `RemoteManifest` as the search/index surface for remote contracts. Do not move authority into clients. Client payloads are requests, not trusted gameplay state. Remaining work is to eliminate subsystem-local power/energy mirrors and to centralize remote creation/validation if the source/repo architecture permits it.
