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

local showPercentage = false
local haveLogged = false
local alreadyChanged = false

local tickSub
Channels.FireAway:SetHandler(function(_, _)
	local isSavingThrow
	if tickSub then
		return
	end
	tickSub = Ext.Events.Tick:Subscribe(function(e)
		local success, error = xpcall(function(...)
			local parentNode = Ext.UI.GetRoot():Child(1):Child(1)

			-- Noesis nodes have a lifetime that expires every tick, and mods can overwrite the Cursor.xaml
			-- so we can't hardcode a path
			local hitNode
			if next(childPath) then
				for _, visualChildIndex in ipairs(childPath) do
					if not parentNode then
						if tickSub then
							Ext.Events.Tick:Unsubscribe(tickSub)
							tickSub = nil
						end
						return
					end
					parentNode = parentNode:VisualChild(visualChildIndex)
				end
				hitNode = parentNode
			else
				hitNode = recursiveFindForHitChance(parentNode)
			end

			if hitNode then
				local dataContext = hitNode:GetProperty("DataContext")

				if dataContext:GetProperty("ActiveTask").PreviewType == "Spell" then
					if dataContext.HitChanceDesc:GetProperty("ShowDescription") then
						if not alreadyChanged then
							alreadyChanged = true

							local totalHitChance = dataContext.HitChanceDesc:GetProperty("TotalHitChance")
							if totalHitChance == 100 then
								if showPercentage then
									hitNode:SetProperty("Text", ("%s%%"):format(tostring(100)))
								else
									hitNode:SetProperty("Text", ("DC: %s"):format(tostring(0)))
								end
							else
								if showPercentage then
									hitNode:SetProperty("Text", ("%s%%"):format(totalHitChance))
								else
									if isSavingThrow == nil and dataContext.ActiveTask.RootCastSpell then
										---@type SpellData
										local spellData = Ext.Stats.Get(dataContext.ActiveTask.RootCastSpell.PrototypeID)
										isSavingThrow = not spellData.SpellRoll.Default:find("Attack%(")
									end

									local dc
									if isSavingThrow then
										dc = math.ceil(20 * (totalHitChance / 100)) + 1
									else
										local hitChance = math.ceil(totalHitChance / 5) * 5
										dc = hitChance > 0 and math.floor(math.max(2, (20 - (20 * (hitChance / 100))) + 1)) or 20
									end
									hitNode:SetProperty("Text", ("DC: %s"):format(dc))
								end
							end
						end
					else
						alreadyChanged = false
					end
				elseif tickSub then
					Ext.Events.Tick:Unsubscribe(tickSub)
					alreadyChanged = false
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
		end, debug.traceback)
		if not success then
			Logger:BasicError("Error occurred during tick processing, report scenario to Osirisofinternet: %s", error)
			if tickSub then
				Ext.Events.Tick:Unsubscribe(tickSub)
				tickSub = nil
			end
		end
	end)
end)

--- Thanks Scribe!
Ext.Events.KeyInput:Subscribe(
---@param e EclLuaKeyInputEvent
	function(e)
		if e.Event == "KeyDown" and e.Repeat == false then
			local lshift, lalt = Ext.Enums.SDLKeyModifier.LShift, Ext.Enums.SDLKeyModifier.LAlt
			if e.Key == "P" and e.Modifiers & lshift == lshift and e.Modifiers & lalt == lalt then
				alreadyChanged = false
				showPercentage = not showPercentage
			end
		end
	end)
