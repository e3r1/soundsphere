local ScoreSystem = require("sphere.models.RhythmModel.ScoreEngine.ScoreSystem")

local JudgementScoreSystem = ScoreSystem:new()

JudgementScoreSystem.name = "judgement"

JudgementScoreSystem.judgements = {
	all = {"count"},
	earlylate = {"early", 0, "late"},
	soundsphere = {
		{"early not perfect", "not perfect"},
		-0.016,
		"perfect",
		0.016,
		{"late not perfect", "not perfect"}
	},
}

JudgementScoreSystem.judgementLists = {
	soundsphere = {
		"perfect",
		"not perfect",
	},
}

local function osuAccuracy(c)
	local total = c["0"] + c["50"] + c["100"] + c["200"] + c["300"] + c["300g"]
	return (c["50"] * 50 + c["100"] * 100 + c["200"] * 200 + (c["300"] + c["300g"]) * 300) / (total * 300)
end
for od = 0, 10 do
	local _3od = 3 * od
	local _300g = 16
	local _300 = 64 - _3od
	local _200 = 97 - _3od
	local _100 = 127 - _3od
	local _50 = 151 - _3od
	local _0 = 188 - _3od
	local judgements = {
		accuracy = osuAccuracy,
		-_0,
		"0",
		-_50,
		"50",
		-_100,
		"100",
		-_200,
		"200",
		-_300,
		"300",
		-_300g,
		"300g",
		_300g,
		"300",
		_300,
		"200",
		_200,
		"100",
		_100,
		"50",
		_50,
		"0"
	}
	for i = 1, #judgements do
		if type(judgements[i]) == "number" then
			judgements[i] = judgements[i] / 1000
		end
	end
	JudgementScoreSystem.judgements["osuOD" .. od] = judgements
	JudgementScoreSystem.judgementLists["osuOD" .. od] = {
		"300g",
		"300",
		"200",
		"100",
		"50",
		"0",
	}
end

JudgementScoreSystem.load = function(self)
	self.counter = 0

	for name, judgements in pairs(self.scoreEngine.judgements) do
		self.judgements[name] = judgements
	end

	self.counters = {}
	local counters = self.counters
	for name, judgements in pairs(self.judgements) do
		counters[name] = counters[name] or {}
		for i, judgement in ipairs(judgements) do
			if type(judgement) ~= "number" then
				if type(judgement) == "string" then
					counters[name][judgement] = 0
				elseif type(judgement) == "table" then
					for _, j in ipairs(judgement) do
						counters[name][j] = 0
					end
				end
			end
		end
	end
end

JudgementScoreSystem.getJudgement = function(_, judgements, deltaTime)
	for i, v in ipairs(judgements) do
		if type(v) ~= "number" then
			local prev = judgements[i - 1] or -math.huge
			local next = judgements[i + 1] or math.huge
			if deltaTime >= prev and deltaTime < next then
				return v
			end
		end
	end
end

JudgementScoreSystem.hit = function(self, event)
	local counters = self.counters
	for name, judgements in pairs(self.judgements) do
		local judgement = self:getJudgement(judgements, event.deltaTime)
		if judgement then
			if type(judgement) == "string" then
				counters[name][judgement] = counters[name][judgement] + 1
			elseif type(judgement) == "table" then
				for _, j in ipairs(judgement) do
					counters[name][j] = counters[name][j] + 1
				end
			end
		end
	end

	self.counter = self.counter + 1
end

JudgementScoreSystem.notes = {
	ShortNote = {
		clear = {
			passed = "hit",
			missed = "hit",
			clear = nil,
		},
	},
	LongNote = {
		clear = {
			startPassedPressed = "hit",
			startMissed = "hit",
			startMissedPressed = "hit",
			clear = nil,
		},
		startPassedPressed = {
			startMissed = nil,
			endMissed = "hit",
			endPassed = "hit",
		},
		startMissedPressed = {
			endMissedPassed = "hit",
			startMissed = nil,
			endMissed = "hit",
		},
		startMissed = {
			startMissedPressed = nil,
			endMissed = "hit",
		},
	},
}

return JudgementScoreSystem
