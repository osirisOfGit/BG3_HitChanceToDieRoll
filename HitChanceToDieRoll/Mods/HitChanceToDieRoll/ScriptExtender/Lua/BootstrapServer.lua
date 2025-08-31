Ext.Require("Utilities/Common/_Index.lua")
Ext.Require("Utilities/Networking/Channels.lua")
Ext.Require("Utilities/Advanced/_ECSPrinter.lua")

Logger:ClearLogFile()

Ext.Osiris.RegisterListener("StartedPreviewingSpell", 4, "before", function (caster, spell, isMostPowerful, hasMultipleLevels)
	Channels.FireAway:SendToClient(caster, Osi.GetReservedUserID(caster))
end)
