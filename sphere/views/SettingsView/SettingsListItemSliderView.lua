local viewspackage = (...):match("^(.-%.views%.)")

local ListItemSliderView = require(viewspackage .. "ListItemSliderView")
local SliderView = require(viewspackage .. "SliderView")

local SettingsListItemSliderView = ListItemSliderView:new()

SettingsListItemSliderView.construct = function(self)
	self.sliderView = SliderView:new()
end

SettingsListItemSliderView.getName = function(self)
	return self.item.name
end

SettingsListItemSliderView.getValue = function(self)
	return self.listView.settingsModel:getDisplayValue(self.item)
end

SettingsListItemSliderView.getNormValue = function(self)
	return self.listView.settingsModel:getNormalizedValue(self.item)
end

SettingsListItemSliderView.updateNormValue = function(self, normValue)
	self.listView.navigator:send({
		name = "setSettingValue",
		settingConfig = self.item,
		value = self.listView.settingsModel:fromNormalizedValue(self.item, normValue)
	})
end

SettingsListItemSliderView.increaseValue = function(self, delta)
	self.listView.navigator:increaseSettingValue(self.itemIndex, delta)
end

SettingsListItemSliderView.mousepressed = function(self, event)
	local button = event.args[3]
	if button == 2 then
		self.listView.navigator:resetSetting(self.itemIndex)
	end
end

return SettingsListItemSliderView
