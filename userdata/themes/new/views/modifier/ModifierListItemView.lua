
local Node = require("aqua.util.Node")
local aquafonts			= require("aqua.assets.fonts")
local spherefonts		= require("sphere.assets.fonts")

local ModifierListItemView = Node:new()

ModifierListItemView.init = function(self)
	self:on("draw", self.draw)

	self.fontName = aquafonts.getFont(spherefonts.NotoSansRegular, 24)
end

ModifierListItemView.draw = function(self)
	local listView = self.listView

	local itemIndex = self.index + listView.selectedItem - math.ceil(listView.itemCount / 2)
	if not listView.items[itemIndex] then
		return
	end

	local cs = listView.cs

	local x = cs:X(listView.x, true)
	local y = cs:Y(listView.y, true)
	local w = cs:X(listView.w)
	local h = cs:Y(listView.h)

	local index = self.index
	local Modifier = listView.items[itemIndex]

	local deltaItemIndex = math.abs(itemIndex - listView.selectedItem)
	if listView.isSelected then
		love.graphics.setColor(1, 1, 1,
			deltaItemIndex == 0 and 1 or 0.66
		)
	else
		love.graphics.setColor(1, 1, 1,
			deltaItemIndex == 0 and 1 or 0.33
		)
	end

	love.graphics.setFont(self.fontName)
	love.graphics.printf(
		Modifier.name,
		x,
		y + (index - 1) * h / listView.itemCount,
		w / cs.one * 1080,
		"left",
		0,
		cs.one / 1080,
		cs.one / 1080,
		-cs:X(120 / cs.one),
		-cs:Y(18 / cs.one)
	)
end

return ModifierListItemView
