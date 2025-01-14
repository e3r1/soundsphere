local Class = require("Class")
local CacheDatabase = require("sphere.models.CacheModel.CacheDatabase")

local TimeController = Class:new()

TimeController.skipIntro = function(self)
	local rhythmModel = self.game.rhythmModel
	local timeEngine = rhythmModel.timeEngine
	if not timeEngine.timer.isPlaying then
		return
	end
	timeEngine:skipIntro()
end

TimeController.updateOffsets = function(self)
	local rhythmModel = self.game.rhythmModel
	local noteChartDataEntry = self.game.noteChartModel.noteChartDataEntry
	local config = self.game.configModel.configs.settings

	local localOffset = noteChartDataEntry.localOffset or 0
	local baseTimeRate = rhythmModel.timeEngine:getBaseTimeRate()
	local inputOffset = config.gameplay.offset.input + localOffset
	local visualOffset = config.gameplay.offset.visual + localOffset
	if config.gameplay.offsetScale.input then
		inputOffset = inputOffset * baseTimeRate
	end
	if config.gameplay.offsetScale.visual then
		visualOffset = visualOffset * baseTimeRate
	end
	rhythmModel:setInputOffset(inputOffset)
	rhythmModel:setVisualOffset(visualOffset)
end

TimeController.increaseTimeRate = function(self, delta)
	if self.game.multiplayerModel.isPlaying then return end
	local rhythmModel = self.game.rhythmModel
	local timeEngine = rhythmModel.timeEngine
	timeEngine:increaseTimeRate(delta)
	rhythmModel.prohibitSavingScore = true
	self.game.notificationModel:notify("rate: " .. timeEngine.timeRate)
end

-- TimeController.invertTimeRate = function(self)
-- 	if self.game.multiplayerModel.isPlaying then return end
-- 	local rhythmModel = self.game.rhythmModel
-- 	local timeEngine = rhythmModel.timeEngine
-- 	timeEngine:setTimeRate(-timeEngine.timeRate)
-- 	rhythmModel.prohibitSavingScore = true
-- 	self.game.notificationModel:notify("rate: " .. timeEngine.timeRate)
-- end

TimeController.increasePlaySpeed = function(self, delta)
	local gameplay = self.game.configModel.configs.settings.gameplay
	local rhythmModel = self.game.rhythmModel
	local graphicEngine = rhythmModel.graphicEngine
	graphicEngine:increaseVisualTimeRate(delta)
	gameplay.speed = graphicEngine.targetVisualTimeRate
	self.game.notificationModel:notify("scroll speed: " .. graphicEngine.targetVisualTimeRate)
end

TimeController.invertPlaySpeed = function(self)
	local rhythmModel = self.game.rhythmModel
	local graphicEngine = rhythmModel.graphicEngine
	graphicEngine.targetVisualTimeRate = -graphicEngine.targetVisualTimeRate
	graphicEngine:setVisualTimeRate(graphicEngine.targetVisualTimeRate)
	self.game.notificationModel:notify("scroll speed: " .. graphicEngine.targetVisualTimeRate)
end

TimeController.increaseLocalOffset = function(self, delta)
	local noteChartDataEntry = self.game.noteChartModel.noteChartDataEntry
	noteChartDataEntry.localOffset = (noteChartDataEntry.localOffset or 0) + delta
	CacheDatabase:updateNoteChartDataEntry(noteChartDataEntry)
	self.game.notificationModel:notify("local offset: " .. noteChartDataEntry.localOffset * 1000 .. "ms")
	self:updateOffsets()
end

return TimeController
