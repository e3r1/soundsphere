local JustConfig = require("sphere.JustConfig")
local imgui = require("sphere.imgui")
local round = require("math_util").round

local config = JustConfig:new()

config.data = --[[data]] {
	autosave = false,
	HitPosition = 240,
	ScorePosition = 240,
	ComboPosition = 240,
	OverallDifficulty = 5,
	HitErrorPosition = 465,
	UpsideDown = false,
	Barline = true,
} --[[/data]]

function config:draw(w, h)
	local data = self.data

	imgui.setSize(w, h, w / 2, 55)
	data.HitPosition = imgui.slider1("HitPosition", data.HitPosition, "%d", 240, 480, 1, "Hit Position")
	data.ScorePosition = imgui.slider1("ScorePosition", data.ScorePosition, "%d", 0, 480, 1, "Score Position")
	data.ComboPosition = imgui.slider1("ComboPosition", data.ComboPosition, "%d", 0, 480, 1, "Combo Position")
	data.OverallDifficulty = imgui.slider1("OverallDifficulty", data.OverallDifficulty, "%d", 0, 10, 1, "Overall Difficulty")
	data.HitErrorPosition = imgui.slider1("HitErrorPosition", data.HitErrorPosition, "%d", 0, 480, 1, "Hit Error Position")
	data.UpsideDown = imgui.checkbox("UpsideDown", data.UpsideDown, "Upside Down")
	data.Barline = imgui.checkbox("Barline", data.Barline, "Barline")

	imgui.separator()
	self:drawAfter()
end

return config
