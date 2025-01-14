local Layout = require("sphere.views.GameplayView.Layout")
local Background = require("sphere.views.GameplayView.Background")
local Foreground = require("sphere.views.GameplayView.Foreground")
local PauseSubscreen = require("sphere.views.GameplayView.PauseSubscreen")
local ScreenView = require("sphere.views.ScreenView")
local SequenceView = require("sphere.views.SequenceView")
local just = require("just")

local GameplayView = ScreenView:new()

GameplayView.construct = function(self)
	self.sequenceView = SequenceView:new()
end

GameplayView.load = function(self)
	self.game.rhythmModel.observable:add(self.sequenceView)
	self.game.gameplayController:load()

	local noteSkin = self.game.rhythmModel.graphicEngine.noteSkin
	self.viewConfig = noteSkin.playField

	self.subscreen = ""
	self.failed = false

	local sequenceView = self.sequenceView

	sequenceView.game = self.game
	sequenceView.screenView = self
	sequenceView:setSequenceConfig(self.viewConfig)
	sequenceView:load()
end

GameplayView.unload = function(self)
	self.game.gameplayController:unload()
	self.game.rhythmModel.observable:remove(self.sequenceView)
	self.sequenceView:unload()
end

GameplayView.retry = function(self)
	self.game.gameplayController:retry()
	self.sequenceView:unload()
	self.sequenceView:load()
end

GameplayView.draw = function(self)
	just.container("screen container", true)
	self:keypressed()
	self:keyreleased()

	Layout:draw()
	Background(self)
	self.sequenceView:draw()
	Foreground(self)
	if self.subscreen == "pause" then
		PauseSubscreen(self)
	end
	just.container()

	local state = self.game.rhythmModel.pauseManager.state
	local multiplayerModel = self.game.multiplayerModel
	local isPlaying = multiplayerModel.room and multiplayerModel.isPlaying
	if
		not love.window.hasFocus() and
		state == "play" and
		not self.game.rhythmModel.logicEngine.autoplay and
		not isPlaying and
		self.game.rhythmModel.inputManager.mode ~= "internal"
	then
		self.game.gameplayController:pause()
	end
end

GameplayView.update = function(self, dt)
	self.game.gameplayController:update(dt)

	local state = self.game.rhythmModel.pauseManager.state
	if state == "play" then
		self.subscreen = ""
	elseif state == "pause" then
		self.subscreen = "pause"
	end

	if self.game.rhythmModel.pauseManager.needRetry then
		self.failed = false
		self:retry()
	end

	local timeEngine = self.game.rhythmModel.timeEngine
	if timeEngine.currentTime >= timeEngine.maxTime + 1 then
		self:quit()
	end

	local actionOnFail = self.game.configModel.configs.settings.gameplay.actionOnFail
	local failed = self.game.rhythmModel.scoreEngine.scoreSystem.hp:isFailed()
	if failed and not self.failed then
		if actionOnFail == "pause" then
			self.game.gameplayController:changePlayState("pause")
			self.failed = true
		elseif actionOnFail == "quit" then
			self:quit()
		end
	end

	local multiplayerModel = self.game.multiplayerModel
	if multiplayerModel.room and not multiplayerModel.isPlaying then
		self:quit()
	end

	self.sequenceView:update(dt)
end

GameplayView.receive = function(self, event)
	self.game.gameplayController:receive(event)
	self.sequenceView:receive(event)
end

GameplayView.quit = function(self)
	if self.game.gameplayController:hasResult() then
		return self:changeScreen("resultView")
	elseif self.game.multiplayerModel.room then
		return self:changeScreen("multiplayerView")
	end
	return self:changeScreen("selectView")
end

GameplayView.keypressed = function(self)
	local input = self.game.configModel.configs.settings.input
	local timeController = self.game.timeController

	local kp = just.keypressed
	if kp(input.skipIntro) then timeController:skipIntro()
	elseif kp(input.offset.decrease) then timeController:increaseLocalOffset(-0.001)
	elseif kp(input.offset.increase) then timeController:increaseLocalOffset(0.001)
	elseif kp(input.timeRate.decrease) then timeController:increaseTimeRate(-0.05)
	elseif kp(input.timeRate.increase) then timeController:increaseTimeRate(0.05)
	-- elseif scancode == input.timeRate.invert then timeController:invertTimeRate()
	elseif kp(input.playSpeed.decrease) then timeController:increasePlaySpeed(-0.05)
	elseif kp(input.playSpeed.increase) then timeController:increasePlaySpeed(0.05)
	elseif kp(input.playSpeed.invert) then timeController:invertPlaySpeed()
	end

	local gameplayController = self.game.gameplayController

	local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
	local state = self.game.rhythmModel.pauseManager.state
	if state == "play" then
		if kp(input.pause) and not shift then gameplayController:changePlayState("pause")
		elseif kp(input.pause) and shift then self:quit()
		elseif kp(input.quickRestart) then gameplayController:changePlayState("retry")
		end
	elseif state == "pause" then
		if kp(input.pause) and not shift then gameplayController:changePlayState("play")
		elseif kp(input.pause) and shift then self:quit()
		elseif kp(input.quickRestart) then gameplayController:changePlayState("retry")
		end
	elseif state == "pause-play" and kp(input.pause) then
		gameplayController:changePlayState("pause")
	end
end

GameplayView.keyreleased = function(self)
	local state = self.game.rhythmModel.pauseManager.state
	local input = self.game.configModel.configs.settings.input
	local gameplayController = self.game.gameplayController

	local kr = just.keyreleased
	if state == "play-pause" and kr(input.pause) then
		gameplayController:changePlayState("play")
	elseif state == "pause-retry" and kr(input.quickRestart) then
		gameplayController:changePlayState("pause")
	elseif state == "play-retry" and kr(input.quickRestart) then
		gameplayController:changePlayState("play")
	end
end

return GameplayView
