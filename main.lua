require("hooks")

require("mime")
require("ltn12")
require("enet")
require("socket")

local pkg = require("aqua.package")
pkg.reset()
pkg.addc("3rd-deps/lib")
pkg.addc("bin/lib")
pkg.add("3rd-deps/lua")
pkg.add("aqua")
pkg.add("ncdk")
pkg.add("chartbase")
pkg.add("libchart")

local ffi = require("ffi")

local source = love.filesystem.getSource()
local sourceBase = love.filesystem.getSourceBaseDirectory()

local root
if source:find("^.+%.love$") then
	print("starting from .love file directly")
	root = sourceBase
else
	print("starting from current directory")
	root = source
end

if jit.os == "Windows" then
	local winapi = require("winapi")
	winapi.putenv("PATH", ("%s;%s"):format(winapi.getenv("PATH"), root .. "/bin/win64"))
	winapi.chdir(root)
	pkg.addc("bin/win64")
elseif jit.os == "Linux" then
	local ldlp = os.getenv("LD_LIBRARY_PATH")
	if not ldlp or not ldlp:find("bin/linux64") then
		ffi.cdef("int setenv(const char *name, const char *value, int overwrite);")
		ffi.C.setenv("LD_LIBRARY_PATH", (ldlp or "") .. ":" .. root .. "/bin/linux64", true)
		os.execute(("%q %q &"):format(arg[-2], arg[1]))
		return os.exit()
	end
	ffi.cdef("int chdir(const char *path);")
	ffi.C.chdir(root)
	pkg.addc("bin/linux64")
end

local utf8validate = require("utf8validate")
local errhand = love.errhand
function love.errhand(msg)
	return errhand(utf8validate(msg))
end

local physfs = require("physfs")
physfs.setWriteDir(root)

if root == sourceBase then
	assert(physfs.mount(root, "/", true))
end

local moddedgame = love.filesystem.getInfo("moddedgame")
if moddedgame and moddedgame.type == "directory" then
	assert(physfs.mount(root .. "/moddedgame", "/", false))
end

require("preloaders.preloadall")

local love_run = require("love_run")
love.load = function() end  -- for compatibility with old conf.lua
local defaultLoop = love.loop or love_run()
function love.run()
	return function()
		return defaultLoop()
	end
end

local thread = require("thread")
thread.coro(function()
	local UpdateController = require("sphere.controllers.UpdateController")
	local updateController = UpdateController:new()
	local needRestart = updateController:updateAsync()
	if needRestart then
		thread.unload()
		thread.waitAsync()
		return love.event.quit("restart")
	end

	require("luamidi")

	setmetatable(_G, {
		__newindex = function(a, b, c)
			print(a, b, c, debug.traceback())
			rawset(a, b, c)
		end
	})

	local GameController = require("sphere.controllers.GameController")
	local game = GameController:new()

	game:load()

	local gameloop = require("gameloop")
	gameloop:init()
	defaultLoop = gameloop.run()
	gameloop:add(game)
end)()
