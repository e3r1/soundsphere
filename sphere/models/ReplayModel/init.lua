local Class			= require("Class")
local Observable	= require("Observable")
local Replay		= require("sphere.models.ReplayModel.Replay")
local md5			= require("md5")
local thread = require("thread")

local ReplayModel = Class:new()

ReplayModel.path = "userdata/replays"

ReplayModel.construct = function(self)
	self.observable = Observable:new()
	self.mode = "record"
end

ReplayModel.load = function(self)
	if self.mode == "record" then
		self.replay = Replay:new()
	elseif self.mode == "replay" then
		self.replay:reset()
	end
	self.replay.timeEngine = self.game.rhythmModel.timeEngine
	self.currentTime = -math.huge
end

ReplayModel.setMode = function(self, mode)
	self.mode = mode
end

ReplayModel.send = function(self, event)
	return self.observable:send(event)
end

ReplayModel.receive = function(self, event)
	if self.mode == "record" and event.virtual then
		self.replay:receive(event)
	end
end

ReplayModel.update = function(self)
	if self.mode == "replay" then
		local replay = self.replay
		local nextEvent = replay:getNextEvent()
		if not nextEvent then
			return
		end

		nextEvent.baseTime = nextEvent.baseTime or nextEvent.time
		nextEvent.time = nextEvent.baseTime + self.game.rhythmModel.timeEngine.inputOffset
		if self.currentTime >= nextEvent.time then
			self:send(nextEvent)
			replay:step()
			return self:update()
		end
	end
end

ReplayModel.saveReplay = function(self)
	local replay = self.replay
	replay.noteChartDataEntry = self.game.noteChartModel.noteChartDataEntry
	replay.inputMode = self.game.noteChartModel.noteChart.inputMode
	replay.modifierTable = self.game.modifierModel.config
	replay.timings = self.timings

	local replayString = replay:toString()
	local replayHash = md5.sumhexa(replayString)

	assert(love.filesystem.write(self.path .. "/" .. replayHash, replayString))

	return replayHash
end

ReplayModel.loadReplay = function(self, content)
	local replay = Replay:new()
	if not content then
		return replay
	end

	return replay:fromString(content)
end

return ReplayModel
