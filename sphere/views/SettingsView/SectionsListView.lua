local viewspackage = (...):match("^(.-%.views%.)")

local CoordinateManager = require("aqua.graphics.CoordinateManager")
local ListView = require(viewspackage .. "ListView")
local SectionsListItemView = require(viewspackage .. "SettingsView.SectionsListItemView")

local SectionsListView = ListView:new()

SectionsListView.construct = function(self)
	ListView.construct(self)
	self.itemView = SectionsListItemView:new()
	self.itemView.listView = self
	self.cs = CoordinateManager:getCS(0.5, 0, 0, 0, "h")
end

SectionsListView.reloadItems = function(self)
	self.state.items = self.settingsModel.sections
end

SectionsListView.getItemIndex = function(self)
	return self.navigator.sectionItemIndex
end

SectionsListView.scrollUp = function(self)
	self.navigator:scrollSections("up")
end

SectionsListView.scrollDown = function(self)
	self.navigator:scrollSections("down")
end

return SectionsListView
