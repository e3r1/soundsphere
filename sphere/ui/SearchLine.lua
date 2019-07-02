local Theme = require("aqua.ui.Theme")
local Observable = require("aqua.util.Observable")
local aquafonts = require("aqua.assets.fonts")
local spherefonts = require("sphere.assets.fonts")
local CS = require("aqua.graphics.CS")

local SearchLine = {}

SearchLine.cs = CS:new({
	bx = 0,
	by = 0,
	rx = 0,
	ry = 0,
	binding = "h",
	baseOne = 720
})

SearchLine.observable = Observable:new()

SearchLine.load = function(self)
	self.textInputFrame = Theme.TextInputFrame:new({
		x = 0.01,
		y = 0.01,
		w = 1,
		h = 0.05,
		rx = 0.02,
		ry = 0.02,
		backgroundColor = {0, 0, 0, 63},
		borderColor = {255, 255, 255, 255},
		textColor = {255, 255, 255, 255},
		lineStyle = "smooth",
		lineWidth = 2,
		cs = self.cs,
		limit = 1,
		textAlign = {x = "left", y = "center"},
		text = "",
		font = aquafonts.getFont(spherefonts.NotoSansRegular, 26),
		enableStencil = true
	})
	
	self.textInputFrame:reload()
end

SearchLine.reload = function(self)
	self.textInputFrame:reload()
end

SearchLine.receive = function(self, event)
	if event.name == "resize" then
		self.cs:reload()
	end
	
	if self.textInputFrame then
		local oldText = self:getText()
		self.textInputFrame:receive(event)
		local newText = self:getText()
		
		if oldText ~= newText then
			self.observable:send({
				name = "search",
				text = newText
			})
		end
	end
end

SearchLine.draw = function(self)
	self.textInputFrame:draw()
end

SearchLine.getText = function(self)
	return self.textInputFrame.textInput.text
end

return SearchLine