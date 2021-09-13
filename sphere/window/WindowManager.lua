local Class	= require("aqua.util.Class")

local WindowManager = Class:new()

WindowManager.path = "userdata/window.json"

WindowManager.load = function(self)
	self.mode = self.configModel:getConfig("settings").graphics.mode
	local mode = self.mode
	local flags = mode.flags

	local width, height
	if flags.fullscreen then
		width, height = love.window.getDesktopDimensions()
	else
		width, height = mode.window.width, mode.window.height
	end
	love.window.setMode(width, height, mode.flags)
	love.resize(width, height)

	self:setIcon()
	love.window.setTitle("soundsphere")

	self.fullscreen = flags.fullscreen
	self.fullscreentype = flags.fullscreentype
	self.vsync = flags.vsync
end

WindowManager.update = function(self)
	local flags = self.mode.flags
	if self.vsync ~= flags.vsync then
		self.vsync = flags.vsync
		love.window.setVSync(self.vsync)
	end
	if self.fullscreen ~= flags.fullscreen or self.fullscreentype ~= flags.fullscreentype then
		self.fullscreen = flags.fullscreen
		self.fullscreentype = flags.fullscreentype
		self:setFullscreen(self.fullscreen, self.fullscreentype)
	end
end

WindowManager.receive = function(self, event)
	if event.name == "keypressed" and event.args[1] == "f11" then
		local mode = self.mode
		self.fullscreen = not self.fullscreen
		mode.flags.fullscreen = self.fullscreen
		self:setFullscreen(self.fullscreen, mode.flags.fullscreentype)
	end
end

WindowManager.setFullscreen = function(self, fullscreen, fullscreentype)
	local mode = self.mode
	local width, height
	if self.fullscreen then
		width, height = love.window.getDesktopDimensions()
	else
		width, height = mode.window.width, mode.window.height
	end
	love.window.updateMode(width, height, {
		fullscreen = fullscreen,
		fullscreentype = fullscreentype
	})
end

local icon_path = "resources/icon.png"
WindowManager.setIcon = function(self)
	local info = love.filesystem.getInfo(icon_path)
	if info then
		local imageData = love.image.newImageData(icon_path)
		love.window.setIcon(imageData)
	end
end

return WindowManager
