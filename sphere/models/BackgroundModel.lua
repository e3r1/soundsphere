local Class = require("Class")
local thread = require("thread")
local gfx_util = require("gfx_util")
local flux				= require("flux")
local delay				= require("delay")

local BackgroundModel = Class:new()

BackgroundModel.alpha = 0

BackgroundModel.load = function(self)
	self.config = self.game.configModel.configs.select
	self.noteChartDataEntryId = 0
	self.path = ""

	self.emptyImage = gfx_util.newPixel(0.25, 0.25, 0.25, 1)
	self.images = {self.emptyImage}
end

BackgroundModel.setBackgroundPath = function(self, path)
	if self.path ~= path then
		self.path = path
		self:loadBackgroundDebounce()
	end
end

BackgroundModel.update = function(self, dt)
	if #self.images > 1 then
		if self.alpha == 1 then
			table.remove(self.images, 1)
			self.alpha = 0
		elseif self.alpha == 0 then
			flux.to(self, 0.25, {alpha = 1}):ease("quadinout")
		end
	end
end

BackgroundModel.setBackground = function(self, image)
	local layer = math.min(#self.images + 1, 3)
	self.images[layer] = image
	if layer == 2 then
		self.alpha = 0
	end
end

BackgroundModel.loadBackgroundDebounce = function(self, path)
	self.path = path or self.path
	delay.debounce(self, "loadDebounce", 0.1, self.loadBackground, self)
end

BackgroundModel.loadBackground = function(self)
	local path = self.path
	if not path then
		return self:setBackground(self.emptyImage)
	end

	if not path:find("^http") then
		local info = love.filesystem.getInfo(path)
		if not info or info.type == "directory" then
			self:setBackground(self.emptyImage)
			return
		end
	end

	local image
	if path:find("%.ojn$") then
		image = self:loadImage(path, "ojn")
	elseif path:find("^http") then
		image = self:loadImage(path, "http")
	elseif path:find("%.mid$") then
		image = self:loadImage("resources/midi/background.jpg")
	else
		image = self:loadImage(path)
	end

	if path ~= self.path then
		return self:loadBackground()
	end

	if image then
		return self:setBackground(image)
	end

	self:setBackground(self.emptyImage)
end

local loadImage = thread.async(function(path)
	require("love.filesystem")
	require("love.image")

	local info = love.filesystem.getInfo(path)
	if not info then
		return
	end

	local status, imageData = pcall(love.image.newImageData, path)
	if status then
		return imageData
	end
end)

local loadOJN = thread.async(function(path)
	require("love.filesystem")
	require("love.image")
	local OJN = require("o2jam.OJN")

	local content = love.filesystem.read(path)
	if not content then
		return
	end

	local ojn = OJN:new(content)
	if ojn.cover == "" then
		return
	end

	local fileData = love.filesystem.newFileData(ojn.cover, "cover")
	local status, imageData = pcall(love.image.newImageData, fileData)
	if status then
		return imageData
	end
end)

local loadHttp = thread.async(function(url)
	local https = require("ssl.https")
	local body = https.request(url)
	if not body then
		return
	end

	require("love.filesystem")
	require("love.image")
	local fileData = love.filesystem.newFileData(body, "cover")
	local status, imageData = pcall(love.image.newImageData, fileData)
	if status then
		return imageData
	end
end)

BackgroundModel.loadImage = function(self, path, type)
	local imageData
	if type == "ojn" then
		imageData = loadOJN(path)
	elseif type == "http" then
		imageData = loadHttp(path)
	else
		imageData = loadImage(path)
	end
	if not imageData then
		return
	end
	return love.graphics.newImage(imageData)
end

return BackgroundModel
