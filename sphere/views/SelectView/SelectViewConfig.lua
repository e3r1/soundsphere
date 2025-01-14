local just = require("just")
local spherefonts = require("sphere.assets.fonts")
local time_util = require("time_util")
local loop = require("loop")

local IconButtonImView = require("sphere.imviews.IconButtonImView")
local LabelImView = require("sphere.imviews.LabelImView")
local BackgroundView = require("sphere.views.BackgroundView")
local GaussianBlurView = require("sphere.views.GaussianBlurView")
local UserInfoView = require("sphere.views.UserInfoView")
local LogoImView = require("sphere.imviews.LogoImView")

local Layout = require("sphere.views.SelectView.Layout")

local function drawFrameRect(w, h, _r)
	local r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle("fill", 0, 0, w, h, _r or 36)
	love.graphics.setColor(r, g, b, a)
end

local function Frames(self)
	local w, h = Layout:move("base")
	love.graphics.setColor(1, 1, 1, 0.2)
	love.graphics.rectangle("fill", 0, 0, w, h)

	local w, h = Layout:move("base", "header")
	drawFrameRect(w, h, 0)

	local w, h = Layout:move("base", "footer")
	drawFrameRect(w, h, 0)
end

local function Background(self)
	local w, h = Layout:move("base")

	local graphics = self.game.configModel.configs.settings.graphics
	local dim = graphics.dim.select
	BackgroundView.game = self.game

	GaussianBlurView:draw(graphics.blur.select)
	BackgroundView:draw(w, h, dim, 0.01)
	GaussianBlurView:draw(graphics.blur.select)
end

local function Header(self)
	local w, h = Layout:move("column1", "header")

	local username = self.game.configModel.configs.online.user.name
	local session = self.game.configModel.configs.online.session
	just.row(true)
	if UserInfoView:draw(w, h, username, session and next(session)) then
		self.game.gameView:setModal(require("sphere.views.OnlineView"))
	end
	just.offset(0)

	LogoImView("logo", h, 0.5)
	if IconButtonImView("quit game", "clear", h, 0.5) then
		love.event.quit()
	end
	just.row(false)

	local w, h = Layout:move("column2", "header")

	love.graphics.setFont(spherefonts.get("Noto Sans", 20))
	just.indent(10)
	LabelImView("SessionTime", time_util.format(loop.time - loop.startTime), h)
end

return function(self)
	Background(self)
	Frames(self)
	Header(self)
end
