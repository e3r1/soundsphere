local Class = require("Class")
local thread = require("thread")
local InputMode = require("ncdk.InputMode")

local SelectController = Class:new()

SelectController.load = function(self)
	local noteChartModel = self.game.noteChartModel
	local selectModel = self.game.selectModel
	local previewModel = self.game.previewModel

	self.game:writeConfigs()
	self.game:resetGameplayConfigs()

	noteChartModel:load()
	selectModel:load()
	previewModel:load()

	self:applyModifierMeta()
end

SelectController.applyModifierMeta = function(self)
	local state = {}
	state.timeRate = 1
	state.inputMode = InputMode:new()

	local item = self.game.selectModel.noteChartItem
	if item then
		state.inputMode:setString(item.inputMode)
	end

	self.game.modifierModel:applyMeta(state)
end

SelectController.unload = function(self)
	self.game.noteSkinModel:load()
	self.game:writeConfigs()
end

SelectController.update = function(self, dt)
	self.game.previewModel:update(dt)
	self.game.selectModel:update()

	local graphics = self.game.configModel.configs.settings.graphics
	local flags = graphics.mode.flags
	if graphics.vsyncOnSelect and flags.vsync == 0 then
		flags.vsync = self.game.baseVsync
	end

	local noteChartItem = self.game.selectModel.noteChartItem
	if self.game.selectModel:isChanged() then
		local bgPath, audioPath, previewTime
		if noteChartItem then
			bgPath = noteChartItem:getBackgroundPath()
			audioPath, previewTime = noteChartItem:getAudioPathPreview()
		end
		self.game.backgroundModel:setBackgroundPath(bgPath)
		self.game.previewModel:setAudioPathPreview(audioPath, previewTime)
		self:applyModifierMeta()
	end

	local osudirectModel = self.game.osudirectModel
	if osudirectModel:isChanged() then
		local backgroundUrl = osudirectModel:getBackgroundUrl()
		local previewUrl = osudirectModel:getPreviewUrl()
		self.game.backgroundModel:loadBackgroundDebounce(backgroundUrl)
		self.game.previewModel:loadPreviewDebounce(previewUrl)
	end

	if self.game.modifierModel:isChanged() then
		self.game.multiplayerModel:pushModifiers()
		self:applyModifierMeta()
	end

	local configModel = self.game.configModel
	if #configModel.configs.online.token == 0 then
		return
	end

	local time = love.timer.getTime()
	if not self.startTime or time - self.startTime > 600 then
		self:updateSession()
		self.startTime = time
	end
end

SelectController.updateSession = thread.coro(function(self)
	self.game.onlineModel.authManager:updateSessionAsync()
	self.game.configModel:write("online")
end)

SelectController.openDirectory = function(self)
	local noteChartItem = self.game.selectModel.noteChartItem
	if not noteChartItem then
		return
	end
	local path = noteChartItem.path:match("^(.+)/.-$")

	local realDirectory = love.filesystem.getRealDirectory(path)
	if not realDirectory then
		return
	end

	local realPath
	if self.game.mountModel:isMountPath(realDirectory) then
		realPath = self.game.mountModel:getRealPath(path)
	else
		realPath = realDirectory .. "/" .. path
	end
	love.system.openURL(realPath)
end

SelectController.openWebNotechart = function(self)
	local noteChartItem = self.game.selectModel.noteChartItem
	if not noteChartItem then
		return
	end

	local hash, index = noteChartItem.hash, noteChartItem.index
	self.game.onlineModel.onlineNotechartManager:openWebNotechart(hash, index)
end

SelectController.updateCache = function(self, force)
	local noteChartItem = self.game.selectModel.noteChartItem
	if not noteChartItem then
		return
	end
	local path = noteChartItem.path:match("^(.+)/.-$")
	self.game.cacheModel:startUpdate(path, force)
end

SelectController.updateCacheCollection = function(self, path, force)
	local cacheModel = self.game.cacheModel
	local state = cacheModel.shared.state
	if state == 0 or state == 3 then
		cacheModel:startUpdate(path, force)
	else
		cacheModel:stopUpdate()
	end
end

return SelectController
