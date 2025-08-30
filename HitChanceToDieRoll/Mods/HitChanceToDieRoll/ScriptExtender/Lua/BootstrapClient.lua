---@diagnostic disable: param-type-mismatch, missing-parameter, undefined-field
Ext.Require("Utilities/Common/_Index.lua")
Ext.Require("Utilities/Networking/Channels.lua")
Ext.Require("Utilities/Client/IMGUI/_Index.lua")

Logger:ClearLogFile()

---@param entity EntityHandle
---@param componentType ExtComponentType
---@param component SpellCastIsCastingComponent
local function onSpellCast(entity, componentType, component)
	if entity.ClientControl and entity.StatusLoseControl == nil then
		Ext.Entity.OnCreateDeferred("SpellCastAnimationRequest", function()
			for _, child in ipairs(Ext.UI.GetRoot():Child(1):Child(1):GetAllProperties().Children) do
				---@cast child UiUIWidget
				if child.XAMLPath == "Pages/CursorText.xaml" then
					---@type number
					local hitChance = child:Child(1):VisualChild(1):Child(1):Child(1):Child(2):GetProperty("Children")[1]:GetProperty("Children")[2]:GetProperty("Child")
						.DataContext:GetProperty("HitChanceDesc"):GetProperty("TotalHitChance")
					
						local textNode = child:VisualChild(1):VisualChild(1):VisualChild(1):VisualChild(1):VisualChild(1):VisualChild(1):VisualChild(2):VisualChild(1):VisualChild(2)
						:VisualChild(1)
						_D(textNode:GetProperty("Name"))

					if (textNode:GetProperty("Name") == "hitChanceText") then
						textNode:SetProperty("Text", ("D%s"):format(tostring(hitChance > 0 and math.floor((20 - (20 * (hitChance / 100))) + 0.5) or 20)))
					end

					break
				end
			end
		end, component.Cast)
	end  
end

Ext.Entity.OnCreateDeferred("SpellCastIsCasting", onSpellCast)
