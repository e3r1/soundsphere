local ModifierButton	= require("sphere.screen.select.ModifierMenu.ModifierButton")
local TextButton		= require("sphere.screen.select.ModifierMenu.TextButton")
local SliderButton		= require("sphere.screen.select.ModifierMenu.SliderButton")
local ModifierManager	= require("sphere.screen.gameplay.ModifierManager")

local SequentialModifierButton = ModifierButton:new()

SequentialModifierButton.construct = function(self)
	local Modifier = self.item.Modifier
	local modifier = self.item.modifier
	
	local button
	if Modifier.variableType == "boolean" then
		button = TextButton:new(self)
		button.item = self.item
		button.updateValue = function(self, value) end
		button.removeModifier = function(self)
			ModifierManager.sequence:remove(modifier)
			
			local SequenceList = require("sphere.screen.select.ModifierMenu.SequenceList")
			SequenceList:reloadItems()
		end
	elseif Modifier.variableType == "number" then
		button = SliderButton:new(self)
		button.item = self.item
		button.updateValue = function(self, value)
			modifier[modifier.variableName] = value
			
			SliderButton.updateValue(self, value)
		end
		button.removeModifier = function(self)
			ModifierManager.sequence:remove(modifier)
			
			local SequenceList = require("sphere.screen.select.ModifierMenu.SequenceList")
			SequenceList:reloadItems()
		end
	end

	return button
end

return SequentialModifierButton
