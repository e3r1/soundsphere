local ScoreSystem = require("sphere.models.RhythmModel.ScoreEngine.ScoreSystem")

local MiscScoreSystem = ScoreSystem:new()

MiscScoreSystem.name = "misc"

MiscScoreSystem.construct = function(self)
	self.ratio = 0
	self.maxDeltaTime = 0
	self.deltaTime = 0
	self.earlylate = 0
end

MiscScoreSystem.hit = function(self, event)
	local deltaTime = event.deltaTime
	self.deltaTime = deltaTime
	if math.abs(deltaTime) > math.abs(self.maxDeltaTime) then
		self.maxDeltaTime = deltaTime
	end

	local counters = self.container.judgement.counters

	self.ratio = (counters.soundsphere.perfect or 0) / (counters.all.count or 1)
	self.earlylate = (counters.earlylate.early or 0) / (counters.earlylate.late or 1)
end

MiscScoreSystem.miss = function(self, event)
	self.deltaTime = event.deltaTime
end

MiscScoreSystem.early = function(self)
	self.deltaTime = -math.huge
end

MiscScoreSystem.notes = {
	ShortNote = {
		clear = {
			passed = "hit",
			missed = "miss",
			clear = "early",
		},
	},
	LongNote = {
		clear = {
			startPassedPressed = "hit",
			startMissed = "miss",
			startMissedPressed = "miss",
			clear = "early",
		},
		startPassedPressed = {
			startMissed = nil,
			endMissed = "miss",
			endPassed = "hit",
		},
		startMissedPressed = {
			endMissedPassed = "hit",
			startMissed = nil,
			endMissed = "miss",
		},
		startMissed = {
			startMissedPressed = nil,
			endMissed = "miss",
		},
	},
}

return MiscScoreSystem
