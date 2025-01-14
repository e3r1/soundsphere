local just = require("just")
local Class = require("Class")
local FadeTransition = require("sphere.views.FadeTransition")
local FrameTimeView = require("sphere.views.FrameTimeView")
local AsyncTasksView = require("sphere.views.AsyncTasksView")
local TextTooltipImView = require("sphere.imviews.TextTooltipImView")
local ContextMenuImView = require("sphere.imviews.ContextMenuImView")

local GameView = Class:new()

GameView.construct = function(self)
	self.fadeTransition = FadeTransition:new()
	self.frameTimeView = FrameTimeView:new()
end

GameView.load = function(self)
	self.frameTimeView.game = self.game

	self.frameTimeView:load()

	self:setView(self.game.selectView)
end

GameView._setView = function(self, view)
	if self.view then
		self.view:unload()
	end
	view.prevView = self.view
	self.view = view
	self.view:load()
end

GameView.setView = function(self, view, noTransition)
	if self.isChangingScreen then
		return
	end
	self.isChangingScreen = true
	view.gameView = self
	if noTransition then
		self.isChangingScreen = false
		return self:_setView(view)
	end
	self.fadeTransition:transitIn(function()
		self:_setView(view)
		self.fadeTransition:transitOut()
		self.isChangingScreen = false
	end)
end

GameView.unload = function(self)
	if not self.view then
		return
	end
	self.view:unload()
end

GameView.update = function(self, dt)
	self.fadeTransition:update(dt)
	if not self.view then
		return
	end
	self.view:update(dt)
end

GameView.draw = function(self)
	if not self.view then
		return
	end
	self.fadeTransition:drawBefore()
	self.view:draw()

	if self.modal and self.modal(self) then
		self.modal = nil
	end
	if self.contextMenu and ContextMenuImView(self.contextMenuWidth) then
		if ContextMenuImView(self.contextMenu()) then
			self.contextMenu = nil
		end
	end
	if self.tooltip then
		TextTooltipImView(self.tooltip)
		self.tooltip = nil
	end

	self.fadeTransition:drawAfter()
	self.frameTimeView:draw()

	local settings = self.game.configModel.configs.settings
	local showTasks = settings.miscellaneous.showTasks

	if showTasks then
		AsyncTasksView()
	end
end

GameView.receive = function(self, event)
	self.frameTimeView:receive(event)
	if not self.view then
		return
	end
	self.view:receive(event)
end

GameView.setContextMenu = function(self, f, width)
	self.contextMenu = f
	self.contextMenuWidth = width
end

GameView.setModal = function(self, f)
	local _f = self.modal
	if not _f then
		self.modal = f
		return
	end
	if not _f() then
		return
	end
	self.modal = f
	if _f == f then
		self.modal = nil
	end
end

return GameView
