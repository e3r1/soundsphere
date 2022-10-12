local just = require("just")
local spherefonts		= require("sphere.assets.fonts")
local gfx_util = require("gfx_util")

local BackgroundView = require("sphere.views.BackgroundView")
local ValueView = require("sphere.views.ValueView")
local GaussianBlurView = require("sphere.views.GaussianBlurView")

local PointGraphView = require("sphere.views.GameplayView.PointGraphView")
local ScoreListView	= require("sphere.views.ResultView.ScoreListView")
local ModifierIconGridView = require("sphere.views.SelectView.ModifierIconGridView")
local MatchPlayersView	= require("sphere.views.GameplayView.MatchPlayersView")
local TextCellImView = require("sphere.imviews.TextCellImView")
local BarCellImView = require("sphere.imviews.BarCellImView")
local IconButtonImView = require("sphere.imviews.IconButtonImView")
local TextButtonImView = require("sphere.imviews.TextButtonImView")
local CheckboxImView = require("sphere.imviews.CheckboxImView")
local LabelImView = require("sphere.imviews.LabelImView")
local SpoilerListImView = require("sphere.imviews.SpoilerListImView")
local JudgementBarImView = require("sphere.imviews.JudgementBarImView")
local Format = require("sphere.views.Format")
local ScrollBarImView = require("sphere.imviews.ScrollBarImView")
local RoundedRectangle = require("sphere.views.RoundedRectangle")

local inspect = require("inspect")
local time_util = require("time_util")
local transform = {{1 / 2, -16 / 9 / 2}, 0, 0, {0, 1 / 1080}, {0, 1 / 1080}, 0, 0, 0, 0}
local transformLeft = {0, 0, 0, {0, 1 / 1080}, {0, 1 / 1080}, 0, 0, 0, 0}

local showLoadedScore = function(self)
	local scoreEntry = self.game.rhythmModel.scoreEngine.scoreEntry
	local scoreItem = self.game.selectModel.scoreItem
	if not scoreEntry or not scoreItem then
		return
	end
	return scoreItem.id == scoreEntry.id
end

local function getRect(out, r)
	out.x = r[1]
	out.y = r[2]
	out.w = r[3]
	out.h = r[4]
end

local Layout = require("sphere.views.ResultView.Layout")

local function drawFrameRect(w, h, _r)
	local r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle("fill", 0, 0, w, h, _r or 36)
	love.graphics.setColor(r, g, b, a)
end

local function drawFrameRect2(w, h, _r)
	local r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(0.4, 0.4, 0.4, 0.7)
	RoundedRectangle("fill", 0, 0, w, h, _r or 36)
	love.graphics.setColor(r, g, b, a)
end

local Frames = {draw = function(self)
	local w, h = Layout:move("base")
	love.graphics.setColor(1, 1, 1, 0.2)
	love.graphics.rectangle("fill", 0, 0, w, h)

	w, h = Layout:move("graphs")
	drawFrameRect(w, h)

	love.graphics.setColor(0.1, 0.1, 0.1, 0.8)

	w, h = Layout:move("title_left")
	RoundedRectangle("fill", 0, 0, w, h, 36, false, false, 3)

	w, h = Layout:move("title_sub")
	RoundedRectangle("fill", 0, 0, w, 72, 36, true, true, 2)

	w, h = Layout:move("title_right")
	RoundedRectangle("fill", 0, 0, w, h, 36, false, false, 1)
end}

local BackgroundBlurSwitch = {draw = function(self)
	GaussianBlurView:draw(self.game.configModel.configs.settings.graphics.blur.result)
end}

local Background = {
	draw = function(self)
		love.graphics.replaceTransform(gfx_util.transform(transform))

		local dim = self.game.configModel.configs.settings.graphics.dim.result
		BackgroundView.game = self.game
		BackgroundView:draw(1920, 1080, dim, 0.01)
	end
}

local drawGraph = function(self)
	getRect(self, Layout.graphs)
	local padding = 18 * math.sqrt(2) / 2
	self.x = self.x + padding
	self.y = self.y + padding
	self.w = self.w - padding * 2
	self.h = self.h - padding * 2
	self.__index.draw(self)
end

local ComboGraph = PointGraphView:new({
	transform = transform,
	draw = drawGraph,
	radius = 2,
	color = {1, 1, 0.25, 1},
	background = true,
	backgroundColor = {0, 0, 0, 0.2},
	backgroundRadius = 4,
	getPoints = function(self)
		return self.game.rhythmModel.scoreEngine.scoreSystem.sequence
	end,
	getTime = function(self, point)
		return point.base.currentTime
	end,
	getValue = function(self, point)
		return point.base.combo / point.base.noteCount
	end,
	point = function(time, startTime, endTime, value)
		local x = (time - startTime) / (endTime - startTime)
		local y = 1 - value
		return x, y
	end,
	show = showLoadedScore
})

local perfectColor = {1, 1, 1, 1}
local notPerfectColor = {1, 0.6, 0.4, 1}
local HitGraph = PointGraphView:new({
	transform = transform,
	draw = drawGraph,
	radius = 2,
	color = function(time, startTime, endTime, value)
		if math.abs(value) <= 0.016 then
			return perfectColor
		end
		return notPerfectColor
	end,
	backgroundColor = {0, 0, 0, 0.2},
	backgroundRadius = 6,
	getPoints = function(self)
		return self.game.rhythmModel.scoreEngine.scoreSystem.sequence
	end,
	getTime = function(self, point)
		return point.base.currentTime
	end,
	getValue = function(self, point)
		if point.base.isMiss then
			return
		end
		return point.misc.deltaTime
	end,
	point = function(time, startTime, endTime, value)
		local x = (time - startTime) / (endTime - startTime)
		local y = value / 0.16 / 2 + 0.5
		return x, y
	end,
	show = showLoadedScore
})

local MissGraph = PointGraphView:new({
	transform = transform,
	draw = drawGraph,
	radius = 4,
	color = {1, 0.2, 0.2, 1},
	backgroundColor = {1, 1, 1, 1},
	backgroundRadius = 6,
	getPoints = function(self)
		return self.game.rhythmModel.scoreEngine.scoreSystem.sequence
	end,
	getTime = function(self, point)
		return point.base.currentTime
	end,
	getValue = function(self, point)
		if not point.base.isMiss then
			return
		end
		return point.misc.deltaTime
	end,
	point = function(time, startTime, endTime, value)
		local x = (time - startTime) / (endTime - startTime)
		local y = value / 0.16 / 2 + 0.5
		return x, y
	end,
	show = showLoadedScore
})

local HpGraph = PointGraphView:new({
	transform = transform,
	draw = drawGraph,
	radius = 2,
	color = {0.25, 1, 0.5, 1},
	background = true,
	backgroundColor = {0, 0, 0, 0.2},
	backgroundRadius = 4,
	getPoints = function(self)
		return self.game.rhythmModel.scoreEngine.scoreSystem.sequence
	end,
	getTime = function(self, point)
		return point.base.currentTime
	end,
	getValue = function(self, point)
		local _hp = self.game.rhythmModel.scoreEngine.scoreSystem.hp
		local hp = point.hp
		for _, h in ipairs(hp) do
			if h.value > 0 then
				return h.value / _hp.max
			end
		end
		return 0
	end,
	point = function(time, startTime, endTime, value)
		local x = (time - startTime) / (endTime - startTime)
		local y = 1 - value
		return x, y
	end,
	show = showLoadedScore
})

local ScoreList = ScoreListView:new({
	transform = transform,
	draw = function(self)
		local w, h = Layout:move("column3")
		drawFrameRect(w, h)
		love.graphics.setColor(0.4, 0.4, 0.4, 0.7)
		w, h = Layout:move("column3row1")
		drawFrameRect2(w, h)
		love.graphics.setColor(1, 1, 1, 1)

		local w, h = Layout:move("column3row2")

		ScoreListView.game = self.game
		ScoreListView.screenView = self.screenView
		ScoreListView:draw(w, h)

		love.graphics.setColor(1, 1, 1, 0.8)
		h = h / ScoreListView.rows
		local c = math.floor(ScoreListView.rows / 2)
		love.graphics.polygon("fill",
			0, h * (c + 0.2) + (72 - h) / 2,
			h / 2 * 0.6, h * (c + 0.5) + (72 - h) / 2,
			0, h * (c + 0.8) + (72 - h) / 2
		)
	end,
})

local ScoreScrollBar = {draw = function(self)
	local w, h = Layout:move("column3row2")
	love.graphics.translate(w - 16, 0)

	local list = ScoreList
	local count = #list.items - 1
	local pos = (list.visualItemIndex - 1) / count
	local newScroll = ScrollBarImView("slsb", pos, 16, h, count / list.rows)
	if newScroll then
		list:scroll(math.floor(count * newScroll + 1) - list.itemIndex)
	end
end}

local Title = {draw = function(self)
	local noteChartDataEntry = self.game.noteChartModel.noteChartDataEntry

	local w, h = Layout:move("title_middle")
	drawFrameRect(w, h)
	love.graphics.translate(22, 15)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(spherefonts.get("Noto Sans", 36))

	local artist_title = ("%s — %s"):format(noteChartDataEntry.artist, noteChartDataEntry.title)
	local creator_name = ("%s — %s"):format(noteChartDataEntry.creator, noteChartDataEntry.name)
	just.text(artist_title)
	just.text(creator_name)
end}

local Judgements = {draw = function(self)
	local show = showLoadedScore(self)
	local scoreEngine = self.game.rhythmModel.scoreEngine
	local scoreItem = self.game.selectModel.scoreItem
	local judgement = scoreEngine.scoreSystem.judgement

	if not judgement or not scoreItem then
		return
	end

	local padding = 24

	local w, h = Layout:move("column1")
	drawFrameRect(w, h)
	love.graphics.setColor(0.4, 0.4, 0.4, 0.7)
	w, h = Layout:move("column1row1")
	drawFrameRect2(w, h)
	love.graphics.setColor(1, 1, 1, 1)

	local w, h = Layout:move("column1row2")
	love.graphics.translate(padding, padding)

	w = w - padding * 2

	local counterName = self.game.configModel.configs.select.judgements
	local counters = judgement.counters
	local judgementLists = judgement.judgementLists
	local counter = counters[counterName]

	local base = scoreEngine.scoreSystem.base

	local count = counters.all.count

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(spherefonts.get("Noto Sans", 24))

	local perfect = show and counter.perfect or scoreItem.perfect or 0
	local notPerfect = show and counter["not perfect"] or scoreItem.notPerfect or 0
	local miss = show and base.missCount or scoreItem.missCount or 0

	local interval = 5
	local lineHeight = 40

	if show then
		for _, name in ipairs(judgementLists[counterName]) do
			JudgementBarImView(w, lineHeight, counters[counterName][name] / count, name, counters[counterName][name])
			just.emptyline(interval)
		end
	else
		JudgementBarImView(w, lineHeight, perfect / count, "perfect", perfect)
		just.emptyline(interval)
		JudgementBarImView(w, lineHeight, notPerfect / count, "not perfect", notPerfect)
	end

	Layout:move("column1row2")
	love.graphics.translate(padding, -padding + h - lineHeight)

	JudgementBarImView(w, lineHeight, miss / count, "miss", miss)
end}

local JudgementsDropdown = {
	draw = function(self)
		local w, h = Layout:move("column1row1")
		h = 60

		local size = 1 / 3
		love.graphics.translate(w * (1 - size) - 26, (72 - h) / 2)

		local judgement = self.game.rhythmModel.scoreEngine.scoreSystem.judgement
		if not judgement then
			return
		end

		local items = {}
		for k in pairs(judgement.judgementLists) do
			table.insert(items, k)
		end
		table.sort(items)

		local config = self.game.configModel.configs.select
		local preview = config.judgements
		love.graphics.setFont(spherefonts.get("Noto Sans", 20))
		local i = SpoilerListImView("JudgementsDropdown", w * size, h, items, preview)
		if i then
			config.judgements = items[i]
		end
	end,
}

local JudgementsAccuracy = {
	draw = function(self)
		local show = showLoadedScore(self)
		local scoreEngine = self.game.rhythmModel.scoreEngine
		local scoreItem = self.game.selectModel.scoreItem
		local judgement = scoreEngine.scoreSystem.judgement

		if not show or not judgement or not scoreItem then
			return
		end

		local counterName = self.game.configModel.configs.select.judgements
		local counter = judgement.counters[counterName]
		local judgements = judgement.judgements[counterName]

		if not judgements.accuracy then
			return
		end

		local w, h = Layout:move("column1row1")
		love.graphics.translate(w / 3, 0)
		w = w / 3

		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.setFont(spherefonts.get("Noto Sans Mono", 32))
		LabelImView("j.acc", ("%3.2f%%"):format(judgements.accuracy(counter) * 100), h)
	end,
}

local NotechartInfo = {draw = function(self)
	local erfunc = require("libchart.erfunc")
	local ratingHitTimingWindow = self.game.configModel.configs.settings.gameplay.ratingHitTimingWindow
	local normalscore = self.game.rhythmModel.scoreEngine.scoreSystem.normalscore

	local noteChartItem = self.game.selectModel.noteChartItem
	local scoreItem = self.game.selectModel.scoreItem
	local scoreEngine = self.game.rhythmModel.scoreEngine

	if not scoreItem then
		return
	end

	local topScoreItem = self.game.scoreLibraryModel.items[1]
	if topScoreItem == scoreItem then
		topScoreItem = self.game.scoreLibraryModel.items[2]
	end
	if not topScoreItem then
		topScoreItem = scoreItem
	end

	local scoreEntry = scoreEngine.scoreEntry
	if not scoreEntry then
		return
	end

	local baseTimeRate = self.game.rhythmModel.timeEngine.baseTimeRate

	local show = showLoadedScore(self)

	local baseBpm = noteChartItem.bpm
	local baseLength = noteChartItem.length
	local baseDifficulty = noteChartItem.difficulty
	local baseInputMode = noteChartItem.inputMode

	local bpm = scoreEngine.bpm
	local length = scoreEngine.length
	local difficulty = show and scoreEngine.enps or scoreItem.difficulty
	local inputMode = show and scoreEngine.inputMode or scoreItem.inputMode

	local w, h = Layout:move("title_left")
	love.graphics.translate(22, 15)

	w = w - 44
	local wr = 0.70

	TextCellImView(w * (1 - wr), 55, "right", "notes", noteChartItem.noteCount)
	just.sameline()
	TextCellImView(w * wr, 55, "right", "duration",
		(not show or length == baseLength) and time_util.format(baseLength) or
		("%s→%s"):format(time_util.format(baseLength), time_util.format(length))
	)

	TextCellImView(w * (1 - wr), 55, "right", "level", noteChartItem.level)
	just.sameline()
	TextCellImView(w * wr, 55, "right", "bpm",
		(not show or bpm == baseBpm) and math.floor(baseBpm) or
		("%d→%d"):format(baseBpm, bpm)
	)

	w, h = Layout:move("title_sub")
	love.graphics.translate(0, 8)

	local font = spherefonts.get("Noto Sans Mono", 36)
	font:setFallbacks(spherefonts.get("Noto Sans", 36))
	love.graphics.setFont(font)

	just.indent(36)
	just.text(("%0.2fx"):format(show and baseTimeRate or scoreItem.timeRate))

	local hp = scoreEngine.scoreSystem.hp
	if show and hp then
		just.sameline()
		just.offset(0)

		local _h
		if not hp then
			return
		end
		for _, h in ipairs(hp) do
			if h.value > 0 then
				_h = h
				break
			end
		end

		local text = "fail"
		if _h then
			text = _h.notes .. "hp"
		end
		just.text(text, w - 72, true)
	end

	w, h = Layout:move("middle")
	drawFrameRect(w, h)
	love.graphics.setColor(0.4, 0.4, 0.4, 0.3)
	w, h = Layout:move("middle_sub")
	RoundedRectangle("fill", 0, 0, w, 72, 36, false, false, 2)
	love.graphics.setColor(1, 1, 1, 1)

	local score = not show and scoreItem.score or
		erfunc.erf(ratingHitTimingWindow / (normalscore.accuracyAdjusted * math.sqrt(2))) * 10000
	if score ~= score then
		score = 0
	end
	local accuracyValue = show and normalscore.accuracyAdjusted or scoreItem.accuracy
	local accuracy = Format.accuracy(accuracyValue)

	local rating = scoreItem.rating

	if scoreEntry.id == scoreItem.id then
		local s = erfunc.erf(ratingHitTimingWindow / (normalscore.accuracyAdjusted * math.sqrt(2)))
		rating = s * scoreEngine.enps
	end

	local bestScore = ("%d"):format(topScoreItem.score)
	local bestAccuracy = Format.accuracy(topScoreItem.accuracy)
	local bestRating = Format.difficulty(topScoreItem.rating)

	local deltaScore = score - topScoreItem.score
	local deltaAccuracy = accuracyValue - topScoreItem.accuracy
	local deltaRating = rating - topScoreItem.rating
	if deltaScore >= 0 then
		deltaScore = "+" .. ("%d"):format(deltaScore)
	else
		deltaScore = ("%d"):format(deltaScore)
	end
	if deltaAccuracy >= 0 then
		deltaAccuracy = "+" .. Format.accuracy(deltaAccuracy)
	else
		deltaAccuracy = Format.accuracy(deltaAccuracy)
	end
	if deltaRating >= 0 then
		deltaRating = "+" .. Format.difficulty(deltaRating)
	else
		deltaRating = Format.difficulty(deltaRating)
	end

	w, h = Layout:move("middle")
	love.graphics.translate(42, 5)
	w = w - 42 * 2

	local a, b = 6, 28
	-------------------------------

	love.graphics.setFont(spherefonts.get("Noto Sans", 24))
	just.text("rating")
	just.sameline()
	just.offset(w - 240)

	love.graphics.setFont(spherefonts.get("Noto Sans Mono", 54))
	just.text(" " .. Format.difficulty(rating))
	just.sameline()

	love.graphics.setFont(spherefonts.get("Noto Sans Mono", 24))
	just.indent(10)
	local offset = just.offset()
	love.graphics.translate(0, a)
	just.text(bestRating)
	just.sameline()
	just.offset(offset)
	love.graphics.translate(0, b)
	just.text(deltaRating)
	love.graphics.translate(0, -a - b)

	-------------------------------

	love.graphics.setFont(spherefonts.get("Noto Sans", 24))
	just.text("score")
	just.sameline()
	just.offset(w - 240)

	love.graphics.setFont(spherefonts.get("Noto Sans Mono", 54))
	just.text((" %d"):format(score))
	just.sameline()

	love.graphics.setFont(spherefonts.get("Noto Sans Mono", 24))
	just.indent(10)
	local offset = just.offset()
	love.graphics.translate(0, a)
	just.text(bestScore)
	just.sameline()
	just.offset(offset)
	love.graphics.translate(0, b)
	just.text(deltaScore)
	love.graphics.translate(0, -a - b)

	-------------------------------

	love.graphics.setFont(spherefonts.get("Noto Sans", 24))
	just.text("accuracy")
	just.sameline()
	just.offset(w - 240)

	love.graphics.setFont(spherefonts.get("Noto Sans Mono", 54))
	just.text(accuracy)
	just.sameline()

	love.graphics.setFont(spherefonts.get("Noto Sans Mono", 24))
	just.indent(10)
	local offset = just.offset()
	love.graphics.translate(0, a)
	just.text(bestAccuracy)
	just.sameline()
	just.offset(offset)
	love.graphics.translate(0, b)
	just.text(deltaAccuracy)
	love.graphics.translate(0, -a - b)

	-------------------------------

	local font = spherefonts.get("Noto Sans Mono", 40)
	font:setFallbacks(spherefonts.get("Noto Sans", 40))
	love.graphics.setFont(font)

	local textInputMode = inputMode == baseInputMode and Format.inputMode(baseInputMode) or
		("%s→%s"):format(Format.inputMode(baseInputMode), Format.inputMode(inputMode))
	local textDifficulty = difficulty == baseDifficulty and Format.difficulty(baseDifficulty) or
		("%s→%s"):format(Format.difficulty(baseDifficulty), Format.difficulty(difficulty))

	love.graphics.setFont(spherefonts.get("Noto Sans", 24))
	just.text("input mode")
	just.sameline()
	just.offset(0)

	love.graphics.setFont(spherefonts.get("Noto Sans Mono", 40))
	just.text(textInputMode, w, true)

	love.graphics.setFont(spherefonts.get("Noto Sans", 24))
	just.text("difficulty")
	just.sameline()
	just.offset(0)

	love.graphics.setFont(spherefonts.get("Noto Sans Mono", 40))
	just.text(textDifficulty, w, true)

	w, h = Layout:move("graphs_sup_left")
	love.graphics.setColor(0, 0, 0, 0.8)
	RoundedRectangle("fill", 0, 0, w, h, {36, h / 2, 36, h / 2}, false, true)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.translate(22, 0)

	w = (w - 44) / 5

	just.row(true)

	local mean = show and normalscore.normalscore.mean or scoreItem.mean
	TextCellImView(w, 55, "right", "mean", ("%0.1f"):format(mean * 1000))

	-- local earlylate = show and scoreEngine.scoreSystem.misc.earlylate or scoreItem.earlylate
	-- if earlylate == 0 or earlylate ~= earlylate then
	-- 	earlylate = "undef"
	-- elseif earlylate > 1 then
	-- 	earlylate = ("-%d%%"):format((earlylate - 1) * 100)
	-- elseif earlylate < 1 then
	-- 	earlylate = ("%d%%"):format((1 / earlylate - 1) * 100)
	-- end
	-- TextCellImView(w, 55, "right", "early/late", earlylate)

	TextCellImView(w, 55, "right", "pauses", scoreItem.pausesCount)

	if show then
		local adjustRatio = normalscore.adjustRatio
		adjustRatio = adjustRatio ~= adjustRatio and "nan" or ("%d%%"):format((1 - adjustRatio) * 100)
		TextCellImView(w, 55, "right", "adjust", adjustRatio)

		TextCellImView(w, 55, "right", "spam", scoreEngine.scoreSystem.base.earlyHitCount)
		TextCellImView(w, 55, "right", "max error", ("%d"):format(scoreEngine.scoreSystem.misc.maxDeltaTime * 1000))
	end

	just.row(false)
end}

local ModifierIconGrid = {
	draw = function(self)
		local w, h = Layout:move("middle_sub")
		-- drawFrameRect(w, h)
		love.graphics.translate(36, 0)

		local modifierModel = self.game.modifierModel
		local config = modifierModel.config
		if not showLoadedScore(self) then
			config = modifierModel.config
		end

		ModifierIconGridView.game = self.game
		ModifierIconGridView:draw(config, w - 72, h, h, true)
	end,
}

local BottomScreenMenu = {draw = function(self)
	local w, h = Layout:move("title_right")

	love.graphics.translate(0, 72 / 2)
	if IconButtonImView("back", "clear", 72, 0.618) then
		self.screenView:changeScreen("selectView")
	end

	love.graphics.setFont(spherefonts.get("Noto Sans", 24))

	local scoreItem = self.game.selectModel.scoreItem
	local scoreEngine = self.game.rhythmModel.scoreEngine
	local scoreEntry = scoreEngine.scoreEntry

	w, h = Layout:move("graphs_sup_right")
	love.graphics.setColor(0, 0, 0, 0.8)
	RoundedRectangle("fill", 0, 0, w, h, {h / 2, 36, h / 2, 36}, true, false)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.translate(55, 0)

	just.row(true)
	if TextButtonImView("retry", "retry", 72 * 1.5, h) then
		self.screenView:play("retry")
	end
	if TextButtonImView("replay", "watch replay", 72 * 3, h) then
		self.screenView:play("replay")
	end
	if scoreItem and scoreEntry and scoreItem.id == scoreEntry.id and not scoreItem.file then
		if TextButtonImView("submit", "resubmit", 72 * 2, h) then
			local noteChartModel = self.game.noteChartModel
			self.game.onlineModel.onlineScoreManager:submit(
				noteChartModel.noteChartEntry,
				noteChartModel.noteChartDataEntry,
				scoreItem.replayHash
			)
		end
	end
	just.row(false)
end}

local MatchPlayers = MatchPlayersView:new({
	transform = transformLeft,
	key = "game.multiplayerModel.roomUsers",
	x = 20,
	y = 540,
	font = {"Noto Sans Mono", 24},
})

local InspectScoreSystem = ValueView:new({
	subscreen = "scoreSystemDebug",
	transform = transformLeft,
	key = "game.rhythmModel.scoreEngine.scoreSystem.slice",
	format = function(...)
		return inspect(...)
	end,
	x = 0,
	baseline = 20,
	limit = 1920,
	font = {"Noto Sans Mono", 14},
	align = "left",
	color = {1, 1, 1, 1}
})

local InspectCounters = ValueView:new({
	subscreen = "countersDebug",
	transform = transformLeft,
	key = "game.rhythmModel.scoreEngine.scoreSystem.judgement.counters",
	format = function(...)
		return inspect(...)
	end,
	x = 0,
	baseline = 20,
	limit = 1920,
	font = {"Noto Sans Mono", 14},
	align = "left",
	color = {1, 1, 1, 1}
})

local InspectScoreEntry = ValueView:new({
	subscreen = "scoreEntryDebug",
	transform = transformLeft,
	key = "game.selectModel.scoreItem",
	format = function(...)
		return inspect(...)
	end,
	x = 0,
	baseline = 20,
	limit = 1920,
	font = {"Noto Sans Mono", 14},
	align = "left",
	color = {1, 1, 1, 1}
})

local NoteSkinViewConfig = {
	Layout,
	BackgroundBlurSwitch,
	Background,
	BackgroundBlurSwitch,
	Frames,
	Title,
	NotechartInfo,
	Judgements,
	JudgementsDropdown,
	JudgementsAccuracy,
	ModifierIconGrid,
	ScoreList,
	ScoreScrollBar,
	HitGraph,
	ComboGraph,
	HpGraph,
	MissGraph,
	BottomScreenMenu,
	MatchPlayers,
	InspectScoreSystem,
	InspectCounters,
	InspectScoreEntry,
	require("sphere.views.DebugInfoViewConfig"),
}

return NoteSkinViewConfig
