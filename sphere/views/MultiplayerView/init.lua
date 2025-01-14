local ScreenView = require("sphere.views.ScreenView")
local just = require("just")

local Layout = require("sphere.views.MultiplayerView.Layout")
local MultiplayerViewConfig = require("sphere.views.MultiplayerView.MultiplayerViewConfig")

local MultiplayerView = ScreenView:new()

MultiplayerView.load = function(self)
	self.game.selectModel:setChanged()
end

MultiplayerView.draw = function(self)
	just.container("screen container", true)
	Layout:draw()
	MultiplayerViewConfig(self)
	just.container()
end

MultiplayerView.update = function(self, dt)
	self.game.selectController:update(dt)

	local multiplayerModel = self.game.multiplayerModel
	if not multiplayerModel.room then
		self:changeScreen("selectView")
	elseif multiplayerModel.isPlaying then
		self:changeScreen("gameplayView")
	end
end

return MultiplayerView
