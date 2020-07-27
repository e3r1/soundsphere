local FileManager			= require("sphere.filesystem.FileManager")
local ShortGraphicalNote	= require("sphere.views.RhythmView.ShortGraphicalNote")
local LongGraphicalNote		= require("sphere.views.RhythmView.LongGraphicalNote")
local ImageNote				= require("sphere.views.RhythmView.ImageNote")
local VideoNote				= require("sphere.views.RhythmView.VideoNote")

local GraphicalNoteFactory = {}

GraphicalNoteFactory.getNote = function(self, graphicalNoteModel)
	local graphicalNote = {graphicalNoteModel = graphicalNoteModel}
	local noteData = graphicalNoteModel.startNoteData
	graphicalNote.startNoteData = noteData

	if noteData.noteType == "ShortNote" then
		graphicalNote.noteType = "ShortNote"
		return ShortGraphicalNote:new(graphicalNote)
	elseif noteData.noteType == "LongNoteStart" then
		-- graphicalNote.noteType = "LongNote"
		-- return LongGraphicalNote:new(graphicalNote)
		graphicalNote.noteType = "ShortNote"
		return ShortGraphicalNote:new(graphicalNote)
	elseif noteData.noteType == "LaserNoteStart" then
		graphicalNote.noteType = "LongNote"
		return LongGraphicalNote:new(graphicalNote)
	elseif noteData.noteType == "LineNoteStart" then
		graphicalNote.noteType = "LongNote"
	elseif noteData.noteType == "LineNoteStart" then
		-- graphicalNote.noteType = "LongNote"
		-- return LongGraphicalNote:new(graphicalNote)
		graphicalNote.noteType = "ShortNote"
		return ShortGraphicalNote:new(graphicalNote)
	elseif noteData.noteType == "SoundNote" then
		graphicalNote.noteType = "SoundNote"
		return ShortGraphicalNote:new(graphicalNote)
	elseif noteData.noteType == "ImageNote" then
		local fileType
		local images = noteData.images[1] and noteData.images[1][1]
		if images then
			fileType = FileManager:getType(images)
		end
		if fileType == "image" then
			graphicalNote.noteType = "ImageNote"
			return ImageNote:new(graphicalNote)
		elseif fileType == "video" then
			graphicalNote.noteType = "VideoNote"
			return VideoNote:new(graphicalNote)
		end
	end
end

return GraphicalNoteFactory
