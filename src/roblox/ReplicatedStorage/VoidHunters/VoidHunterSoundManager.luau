--!strict
-- Canonical runtime compatibility shim.
--
-- The former VoidHunters sound manager contained unverified prototype asset IDs
-- and volumes. The active weapon controller still exposes a presentation hook,
-- so keep that hook inert until forensic audio assets are source-verified.
-- This module intentionally owns no gameplay state and performs no audio I/O.

local SoundManager = {}

function SoundManager.PlayWeapon(_weaponType: string, _position: Vector3)
	-- Intentionally silent: unverified prototype audio must not become runtime truth.
end

return SoundManager
