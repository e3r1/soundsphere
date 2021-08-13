local json = require("json")
local safeload = require("aqua.util.safeload")
local TomlNoteSkinLoader = require("sphere.models.NoteSkinModel.TomlNoteSkinLoader")

local NoteSkinLoader = {}

NoteSkinLoader.data = {}
NoteSkinLoader.path = "userdata/skins"

NoteSkinLoader.load = function(self, noteSkin)
	if noteSkin.type == "toml:simple-v3" then
		return self:loadTomlSimpleLatest(noteSkin)
	elseif noteSkin.type == "json:full-v3" then
		return self:loadJsonFullLatest(noteSkin)
	elseif noteSkin.type == "lua" then
		return self:loadLuaFullLatest(noteSkin)
	end
end

NoteSkinLoader.loadTomlSimpleLatest = function(self, noteSkin)
	return TomlNoteSkinLoader:new():load(noteSkin)
end

NoteSkinLoader.loadJsonFullLatest = function(self, noteSkin)
	local contents = love.filesystem.read(noteSkin.directoryPath .. "/" .. noteSkin.path)
	noteSkin.data = json.decode(contents)

	local playfieldPath = noteSkin.data.playfield
	contents = love.filesystem.read(noteSkin.directoryPath .. "/" .. playfieldPath)
	if playfieldPath:sub(-4, -1) == "json" then
		noteSkin.playField = json.decode(contents)
	elseif playfieldPath:sub(-3, -1) == "lua" then
		noteSkin.playField = assert(loadstring(contents))()
	else
		noteSkin.playField = {}
	end

	contents = love.filesystem.read(noteSkin.directoryPath .. "/" .. noteSkin.data.env)
	noteSkin.env = {}
	noteSkin.env.math = math
	safeload(contents, noteSkin.env)()

	noteSkin.notes = noteSkin.data.notes or {}
end

NoteSkinLoader.loadLuaFullLatest = function(self, noteSkin)
	local path = noteSkin.directoryPath .. "/" .. noteSkin.path
	local contents = love.filesystem.read(path)
	local object = assert(load(contents))(path)

	for k, v in pairs(object) do
		noteSkin[k] = v
	end

	-- if type(object.playfield) == "string" then
	-- 	contents = love.filesystem.read(noteSkin.directoryPath .. "/" .. object.playfield)
	-- 	if object.playfield:sub(-4, -1) == "json" then
	-- 		noteSkin.playField = json.decode(contents)
	-- 	elseif object.playfield:sub(-3, -1) == "lua" then
	-- 		noteSkin.playField = assert(loadstring(contents))()
	-- 	end
	-- end
end

return NoteSkinLoader
