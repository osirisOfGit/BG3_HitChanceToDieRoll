---@diagnostic disable: param-type-mismatch, missing-parameter, undefined-field
Ext.Require("Utilities/Common/_Index.lua")
Ext.Require("Utilities/Networking/Channels.lua")

Logger:ClearLogFile()

local childPath = {}

---@param parent NoesisBaseComponent
local function recursiveFindForHitChance(parent)
	local success, name = pcall(function(...)
		return parent:GetProperty("Name")
	end)

	if success and name == "hitChanceText" then
		return parent
	else
		local success, childrenCount = pcall(function(...)
			return parent.VisualChildrenCount
		end)
		if success and childrenCount then
			for i = 1, childrenCount do
				local node = recursiveFindForHitChance(parent:VisualChild(i))
				if node then
					table.insert(childPath, 1, i)
					return node
				end
			end
		end
	end
end

local haveLogged = false
local tickSub
Channels.FireAway:SetHandler(function(_, _)
	tickSub = Ext.Events.Tick:Subscribe(function(e)
		local parentNode = Ext.UI.GetRoot():Child(1):Child(1)

		-- Noesis nodes have a lifetime that expires every tick, and mods can overwrite the Cursor.xaml
		-- so we can't hardcode a path
		local hitNode
		if next(childPath) then
			for _, visualChildIndex in ipairs(childPath) do
				parentNode = parentNode:VisualChild(visualChildIndex)
			end
			hitNode = parentNode
		else
			hitNode = recursiveFindForHitChance(parentNode)
		end

		if hitNode then
			local dataContext = hitNode:GetProperty("DataContext"):GetAllProperties()

			if dataContext.ActiveTask:GetProperty("RootCastSpell") then
				local hitChanceNode = dataContext.HitChanceDesc:GetAllProperties()

				if hitChanceNode.ShowDescription then
					if (hitNode:GetProperty("Name") == "hitChanceText") then
						if hitChanceNode.TotalHitChance == 100 then
							hitNode:SetProperty("Text", ("DC: %s"):format(tostring(0)))
						else
							local hitChance = math.ceil(hitChanceNode.TotalHitChance / 5) * 5
							hitNode:SetProperty("Text",
								("DC: %s"):format(tostring(hitChance > 0 and math.floor(math.max( 2, (20 - (20 * (hitChance / 100))) + 1)))))
						end
					end
				end
			elseif tickSub then
				Ext.Events.Tick:Unsubscribe(tickSub)
				tickSub = nil
			end
		else
			if not haveLogged then
				haveLogged = true
				Logger:BasicError("Couldn't locate the hitChanceText node? Report to Osirisofinternet with all your mods that affect the UI")
			end
			if tickSub then
				Ext.Events.Tick:Unsubscribe(tickSub)
				tickSub = nil
			end
		end
	end)
end)
