local Class = require("Class")

local RectangleView = require("sphere.views.RectangleView")
local ValueView = require("sphere.views.ValueView")
local ImageView = require("sphere.views.ImageView")
local CameraView = require("sphere.views.CameraView")
local ImageAnimationView = require("sphere.views.ImageAnimationView")

local RhythmView = require("sphere.views.RhythmView")
local ProgressView	= require("sphere.views.GameplayView.ProgressView")
local HitErrorView = require("sphere.views.GameplayView.HitErrorView")
local InputView	= require("sphere.views.GameplayView.InputView")
local InputAnimationView	= require("sphere.views.GameplayView.InputAnimationView")
local JudgementView	= require("sphere.views.GameplayView.JudgementView")
local DeltaTimeJudgementView	= require("sphere.views.GameplayView.DeltaTimeJudgementView")
local MatchPlayersView	= require("sphere.views.GameplayView.MatchPlayersView")

local PlayfieldVsrg = Class:new()

PlayfieldVsrg.construct = function(self)
	self.noteskin.playField = self
end

PlayfieldVsrg.newTransform = function(self, width, height, align)
	local transform = {0, 0, 0, {0, 1 / height}, {0, 1 / height}, 0, 0, 0, 0}
	if align == "center" then
		transform[1] = {1 / 2, -width / height / 2}
	elseif align == "right" then
		transform[1] = {1, -width / height}
	end
	return transform
end

PlayfieldVsrg.newNoteskinTransform = function(self)
	local height = self.noteskin.unit
	local align = self.noteskin.align
	local transform = {0, 0, 0, {0, 1 / height}, {0, 1 / height}, 0, 0, 0, 0}
	if align == "center" then
		transform[1] = {1 / 2, 0}
	elseif align == "right" then
		transform[1] = {1, 0}
	end
	if self.noteskin.upscroll then
		transform[5][2] = -transform[5][2]
		transform[7] = height
	end
	return transform
end

PlayfieldVsrg.newLaneCenterTransform = function(self, height)
	local noteskin = self.noteskin
	local align = noteskin.align
	local offset = noteskin.columnsOffset or 0
	local unit = noteskin.unit or 1
	local transform = {0, 0, 0, {0, 1 / height}, {0, 1 / height}, 0, 0, 0, 0}
	if align == "center" then
		transform[1] = {1 / 2, offset / unit}
	elseif align == "right" then
		transform[1] = {1, -noteskin.fullWidth / unit / 2 + offset / unit}
	elseif align == "left" then
		transform[1] = {0, noteskin.fullWidth / unit / 2 + offset / unit}
	end
	return transform
end

PlayfieldVsrg.newFullTransform = function(self, width, height)
	return {0, 0, 0, {1 / width, 0}, {0, 1 / height}, 0, 0, 0, 0}
end

PlayfieldVsrg.add = function(self, ...)
	table.insert(self, ...)
	return ...
end

PlayfieldVsrg.enableCamera = function(self)
	return self:add(CameraView:new({
		draw_start = true,
	}))
end

PlayfieldVsrg.disableCamera = function(self)
	return self:add(CameraView:new({
		draw_end = true,
	}))
end

PlayfieldVsrg.addRhythmView = function(self, object)
	if not object.transform then
		object.transform = self:newNoteskinTransform()
	end
	return self:add(RhythmView:new(object))
end

PlayfieldVsrg.addImageView = function(self, object)
	return self:add(ImageView:new(object))
end

PlayfieldVsrg.addNotes = function(self, object)
	return self:addRhythmView(object or {})
end

PlayfieldVsrg.addLightings = function(self, object)
	object = object or {}
	object.mode = "lighting"
	return self:addRhythmView(object)
end

PlayfieldVsrg.addBga = function(self, object)
	object = object or {}
	object.mode = "bga"
	return self:addRhythmView(object)
end

PlayfieldVsrg.addProgressBar = function(self, object)
	object = object or {}
	if not getmetatable(object) then
		object = ProgressView:new(object)
	end
	object.getMin = function(self) return self.game.rhythmModel.timeEngine.minTime end
	object.getMax = function(self) return self.game.rhythmModel.timeEngine.maxTime end
	object.getStart = function(self) return self.game.rhythmModel.timeEngine.startTime end
	object.getCurrent = function(self) return self.game.rhythmModel.timeEngine.currentTime end
	return self:add(object)
end

PlayfieldVsrg.addHpBar = function(self, object)
	object = object or {}
	if not getmetatable(object) then
		object = ProgressView:new(object)
	end
	object.getMax = function(self) return self.game.rhythmModel.scoreEngine.scoreSystem.hp.max end
	object.getCurrent = function(self)
		local hp = self.game.rhythmModel.scoreEngine.scoreSystem.hp
		return hp:getCurrent()
	end
	return self:add(object)
end

PlayfieldVsrg.addValueView = function(self, object)
	object = object or {}
	return self:add(ValueView:new(object))
end

PlayfieldVsrg.addScore = function(self, object)
	object = object or {}
	if not getmetatable(object) then
		object = ValueView:new(object)
	end
	object.key = "game.rhythmModel.scoreEngine.scoreSystem.normalscore.score"
	object.value = function(self)
		local erfunc = require("libchart.erfunc")
		local ratingHitTimingWindow = self.game.configModel.configs.settings.gameplay.ratingHitTimingWindow
		local normalscore = self.game.rhythmModel.scoreEngine.scoreSystem.normalscore
		return ("%d"):format(
			erfunc.erf(ratingHitTimingWindow / ((normalscore.accuracyAdjusted or math.huge) * math.sqrt(2))) * 10000
		)
	end
	object.color = object.color or {1, 1, 1, 1}
	return self:add(object)
end

PlayfieldVsrg.addAccuracy = function(self, object)
	object = object or {}
	if not getmetatable(object) then
		object = ValueView:new(object)
	end
	object.key = "game.rhythmModel.scoreEngine.scoreSystem.normalscore.accuracyAdjusted"
	object.format = object.format or "%0.2f"
	object.multiplier = 1000
	object.color = object.color or {1, 1, 1, 1}
	return self:add(object)
end

PlayfieldVsrg.addCombo = function(self, object)
	object = object or {}
	if not getmetatable(object) then
		object = ValueView:new(object)
	end
	object.key = "game.rhythmModel.scoreEngine.scoreSystem.base.combo"
	object.format = object.format or "%d"
	object.color = object.color or {1, 1, 1, 1}
	return self:add(object)
end

PlayfieldVsrg.addJudgement = function(self, object)
	local judgements = {}
	if not object.transform then
		object.transform = self:newLaneCenterTransform(1080)
	end
	for _, judgement in ipairs(object.judgements) do
		local config = ImageAnimationView:new({
			x = object.x, y = object.y,
			w = object.w, h = object.h,
			sx = object.sx or object.scale, sy = object.sy or object.scale,
			ox = object.ox, oy = object.oy,
			transform = object.transform,
			image = judgement[2],
			range = judgement[3],
			quad = judgement[4],
			rate = judgement.rate or object.rate,
		})
		judgements[judgement[1]] = config
		self:add(config)
	end
	local key = "game.rhythmModel.scoreEngine.scoreSystem.judgement.counters"
	if object.key then
		key = key .. "." .. object.key
	end
	return self:add(JudgementView:new({
		key = key,
		judgements = judgements
	}))
end

PlayfieldVsrg.addDeltaTimeJudgement = function(self, object)
	local judgements = {}
	if not object.transform then
		object.transform = self:newLaneCenterTransform(1080)
	end
	for i, judgement in ipairs(object.judgements) do
		if type(judgement) == "string" then
			judgement = {judgement}
		end
		if type(judgement) == "table" then
			local config = ImageAnimationView:new({
				x = object.x, y = object.y,
				w = object.w, h = object.h,
				sx = object.sx or object.scale, sy = object.sy or object.scale,
				ox = object.ox, oy = object.oy,
				transform = object.transform,
				image = judgement[1],
				range = judgement[2],
				quad = judgement[3],
				rate = judgement.rate or object.rate,
			})
			judgements[i] = config
			self:add(config)
		else
			judgements[i] = judgement
		end
	end
	return self:add(DeltaTimeJudgementView:new({
		judgements = judgements
	}))
end

PlayfieldVsrg.addKeyImages = function(self, object)
	local noteskin = self.noteskin
	if not object.transform then
		object.transform = self:newNoteskinTransform()
	end
	for i = 1, noteskin.inputsCount do
		local pressed
		local released
		if object.pressed and object.pressed[i] then
			pressed = ImageView:new({
				x = noteskin.columns[i],
				y = noteskin.unit - object.padding,
				w = noteskin.width[i],
				h = object.h,
				sy = object.sy,
				oy = 1,
				transform = object.transform,
				image = object.pressed[i],
			})
		end
		if object.released and object.released[i] then
			released = ImageView:new({
				x = noteskin.columns[i],
				y = noteskin.unit - object.padding,
				w = noteskin.width[i],
				h = object.h,
				sy = object.sy,
				oy = 1,
				transform = object.transform,
				image = object.released[i],
			})
		end
		local inputType, inputIndex = noteskin.inputs[i]:match("^(.-)(%d+)$")
		local key = InputView:new({
			inputType = inputType, inputIndex = tonumber(inputIndex),
			pressed = pressed,
			released = released,
		})
		self:add(pressed)
		self:add(released)
		self:add(key)
	end
end

PlayfieldVsrg.addStaticKeyImages = function(self, object)
	local noteskin = self.noteskin
	if not object.transform then
		object.transform = self:newNoteskinTransform()
	end
	for i = 1, noteskin.inputsCount do
		if object.image and object.image[i] then
			local image = ImageView:new({
				x = noteskin.columns[i],
				y = noteskin.unit - object.padding,
				w = noteskin.width[i],
				h = object.h,
				sy = object.sy,
				oy = 1,
				transform = object.transform,
				image = object.image[i],
			})
			self:add(image)
		end
	end
end

PlayfieldVsrg.addKeyImageAnimations = function(self, object)
	local noteskin = self.noteskin
	if not object.transform then
		object.transform = self:newNoteskinTransform()
	end
	for i = 1, noteskin.inputsCount do
		local pressed, hold, released
		if object.pressed and object.pressed[i] then
			pressed = ImageAnimationView:new({
				x = noteskin.columns[i],
				y = noteskin.unit - object.padding,
				w = noteskin.width[i],
				h = object.h,
				sy = object.sy,
				oy = 1,
				transform = object.transform,
				image = object.pressed[i][1],
				range = object.pressed[i][2],
				quad = object.pressed[i][3],
				rate = object.rate,
			})
		end
		if object.hold and object.hold[i] then
			hold = ImageAnimationView:new({
				x = noteskin.columns[i],
				y = noteskin.unit - object.padding,
				w = noteskin.width[i],
				h = object.h,
				sy = object.sy,
				oy = 1,
				transform = object.transform,
				image = object.hold[i][1],
				range = object.hold[i][2],
				quad = object.hold[i][3],
				rate = object.rate,
			})
		end
		if object.released and object.released[i] then
			released = ImageAnimationView:new({
				x = noteskin.columns[i],
				y = noteskin.unit - object.padding,
				w = noteskin.width[i],
				h = object.h,
				sy = object.sy,
				oy = 1,
				transform = object.transform,
				image = object.released[i][1],
				range = object.released[i][2],
				quad = object.released[i][3],
				rate = object.rate,
			})
		end
		local inputType, inputIndex = noteskin.inputs[i]:match("^(.-)(%d+)$")
		local key = InputAnimationView:new({
			inputType = inputType, inputIndex = tonumber(inputIndex),
			pressed = pressed,
			hold = hold,
			released = released,
		})
		self:add(pressed)
		self:add(hold)
		self:add(released)
		self:add(key)
	end
end

PlayfieldVsrg.addColumnsBackground = function(self, object)
	if not object then
		return
	end
	if not object.transform then
		object.transform = self:newNoteskinTransform()
	end
	local noteskin = self.noteskin
	local inputs = noteskin.inputsCount
	local rectangles = {}
	for i = 1, inputs do
		local color = object.color[i]
		if type(object.color[1]) == "number" then
			color = object.color
		end
		table.insert(rectangles, {
			color = color,
			mode = "fill",
			lineStyle = "rough",
			lineWidth = 1,
			x = noteskin.columns[i],
			y = 0,
			w = noteskin.width[i],
			h = 480,
			rx = 0,
			ry = 0
		})
	end
	return self:add(RectangleView:new({
		transform = object.transform,
		rectangles = rectangles
	}))
end

local function getGuidelineX(bw, noteskin, i, inputs)
	if bw < 0 then
		if i <= inputs then
			return noteskin.columns[i]
		else
			return noteskin.columns[inputs] + noteskin.width[inputs] + noteskin.space[i]
		end
	elseif bw > 0 then
		if i <= inputs then
			return noteskin.columns[i] - noteskin.space[i]
		else
			return noteskin.columns[inputs] + noteskin.width[inputs]
		end
	end
end

PlayfieldVsrg.addGuidelines = function(self, object)
	if not object then
		return
	end
	if not object.transform then
		object.transform = self:newNoteskinTransform()
	end
	local noteskin = self.noteskin
	local inputs = noteskin.inputsCount
	for i = 1, inputs + 1 do
		local bw = object.w and object.w[i]
		local bh = object.h and object.h[i]
		local by = object.y and object.y[i]

		if bw and bh and by and bw ~= 0 and bh ~= 0 then
			local color = object.color and object.color[i]
			if not color or type(color) == "number" then
				color = object.color
			end

			local lbw = bw
			if object.mode == "symmetric" and i > inputs / 2 + 1 then
				lbw = -bw
			end

			self:add(ImageView:new({
				x = getGuidelineX(bw, noteskin, i, inputs),
				y = by,
				w = lbw,
				h = bh,
				transform = object.transform,
				image = object.image[i],
				color = color,
			}))
			if object.both and noteskin.space[i] ~= 0 then
				local rbw = bw
				if object.mode == "symmetric" and i > inputs / 2 then
					rbw = -bw
				end
				self:add(ImageView:new({
					x = getGuidelineX(-bw, noteskin, i, inputs),
					y = by,
					w = rbw,
					h = bh,
					transform = object.transform,
					image = object.image[i],
					color = color,
				}))
			end
		end
	end
end

local perfectColor = {1, 1, 1, 1}
local notPerfectColor = {1, 0.6, 0.4, 1}
local missColor = {1, 0.2, 0.2, 1}
PlayfieldVsrg.addHitError = function(self, object)
	if not object then
		return
	end
	object.transform = object.transform or self:newLaneCenterTransform(1080)
	object.count = object.count or 1
	object.key = "game.rhythmModel.scoreEngine.scoreSystem.sequence"
	object.value = "misc.deltaTime"
	object.unit = 0.16
	object.color = object.color or function(value, unit)
		if math.abs(value) <= 0.016 then
			return perfectColor
		elseif math.abs(value) > 0.12 then
			return missColor
		end
		return notPerfectColor
	end

	return self:add(HitErrorView:new(object))
end

PlayfieldVsrg.addMatchPlayers = function(self)
	local object = {}
	object.transform = self:newTransform(1920, 1080, "left")
	object.draw = function(self)
		local gfx_util = require("gfx_util")
		love.graphics.replaceTransform(gfx_util.transform(self.transform))
		love.graphics.translate(20, 540)
		MatchPlayersView.game = self.game
		MatchPlayersView:draw()
	end

	return self:add(object)
end

PlayfieldVsrg.addLaneCovers = function(self, covers, x, w)
	if not covers then
		return
	end
	if covers.top.enabled then
		self:addLaneCover({
			x = x,
			w = w,
			position = covers.top.position,
			size = covers.top.size,
			isBottom = false,
		})
	end
	if covers.bottom.enabled then
		self:addLaneCover({
			x = x,
			w = w,
			position = covers.bottom.position,
			size = covers.bottom.size,
			isBottom = true,
		})
	end
end

PlayfieldVsrg.addLaneCover = function(self, object)
	local noteskin = self.noteskin
	local unit = noteskin.unit
	if not unit then
		return
	end

	local gfx_util = require("gfx_util")

	object = object or {}
	object.transform = self:newNoteskinTransform()
	object.mesh = gfx_util.newGradient("vertical", {0, 0, 0, 1}, {0, 0, 0, 0})

	object.position = object.position or unit / 2
	object.size = object.size or 20

	object.x = object.x or noteskin.baseOffset
	object.w = object.w or noteskin.fullWidth

	object.draw = function(self)
		love.graphics.replaceTransform(gfx_util.transform(self.transform))
		love.graphics.translate(object.x, 0)
		love.graphics.setColor(0, 0, 0, 1)

		local p, g = self.position, self.size

		if not self.isBottom then
			love.graphics.rectangle("fill", 0, 0, object.w, p - g)
			love.graphics.draw(self.mesh, 0, p - g, 0, object.w, g)
		else
			love.graphics.draw(self.mesh, 0, p + g, 0, object.w, -g)
			love.graphics.rectangle("fill", 0, p + g, object.w, unit - p + g)
		end
	end

	return self:add(object)
end

return PlayfieldVsrg
