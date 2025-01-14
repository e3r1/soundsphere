local Class				= require("Class")
local NoteHandler		= require("sphere.models.RhythmModel.LogicEngine.NoteHandler")

local LogicEngine = Class:new()

LogicEngine.load = function(self)
	self.sharedLogicalNotes = {}
	self.notesCount = {}

	self:loadNoteHandlers()
end

LogicEngine.update = function(self)
	self:updateNoteHandlers()
end

LogicEngine.unload = function(self)
	self.autoplay = false
	self.promode = false
end

LogicEngine.getEventTime = function(self)
	return self.eventTime or self.rhythmModel.timeEngine.currentTime
end

LogicEngine.receive = function(self, event)
	if not event.virtual or self.promode then
		return
	end

	self.eventTime = event.time
	for _, noteHandler in ipairs(self.noteHandlers) do
		noteHandler:receive(event)
	end
	self.eventTime = nil
end

LogicEngine.getNoteHandler = function(self, inputType, inputIndex)
	return NoteHandler:new({
		inputType = inputType,
		inputIndex = inputIndex,
		logicEngine = self
	})
end

LogicEngine.loadNoteHandlers = function(self)
	self.noteHandlers = {}
	for inputType, inputIndex in self.noteChart:getInputIteraator() do
		local noteHandler = self:getNoteHandler(inputType, inputIndex)
		if noteHandler then
			table.insert(self.noteHandlers, noteHandler)
			noteHandler:load()
		end
	end
end

LogicEngine.updateNoteHandlers = function(self)
	if not self.rhythmModel.timeEngine.timer.isPlaying then
		return
	end
	for _, noteHandler in ipairs(self.noteHandlers) do
		noteHandler:update()
	end
end

return LogicEngine
