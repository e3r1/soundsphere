local Class = require("aqua.util.Class")
local aquatimer = require("aqua.timer")
local aquathread = require("aqua.thread")

local SelectModel = Class:new()

SelectModel.construct = function(self)
	self.noteChartSetItemIndex = 1
	self.noteChartItemIndex = 1
	self.scoreItemIndex = 1
	self.pullingNoteChartSet = false
end

SelectModel.debounceTime = 0.5

SelectModel.load = function(self)
	local config = self.gameController.configModel.configs.select
	self.config = config

	self.gameController.searchModel:setSearchFilter(config.searchFilter)
	self.gameController.searchModel:setSearchLamp(config.searchLamp)
	self.gameController.searchModel:setSearchMode(config.searchMode)
	self.gameController.sortModel.name = config.sortFunction
	self.gameController.noteChartSetLibraryModel.collapse = config.collapse

	self.noteChartSetStateCounter = 1
	self.noteChartStateCounter = 1
	self.searchStateCounter = self.gameController.searchModel.stateCounter

	self.collectionItemIndex = self.gameController.collectionModel:getItemIndex(config.collection)
	self.collectionItem = self.gameController.collectionModel.items[self.collectionItemIndex]

	self:coroPullNoteChartSet()
end

SelectModel.debouncePullNoteChartSet = function(self, ...)
	aquatimer.debounce(self, "pullNoteChartSetDebounce", self.debounceTime, self.pullNoteChartSet, self, ...)
end

SelectModel.coroPullNoteChartSet = aquathread.coro(function(self, ...)
	return self:pullNoteChartSet(...)
end)

SelectModel.setSortFunction = function(self, sortFunctionName)
	if self.pullingNoteChartSet then
		return
	end
	local config = self.config
	config.sortFunction = sortFunctionName
	self.sortModel.name = sortFunctionName
	self:debouncePullNoteChartSet()
end

SelectModel.scrollSortFunction = function(self, delta)
	self.gameController.sortModel:increase(delta)
	self:setSortFunction(self.gameController.sortModel.name)
end

SelectModel.changeSearchMode = function(self)
	self.gameController.searchModel:switchSearchMode()
	self.config.searchMode = self.gameController.searchModel.searchMode
end

SelectModel.changeCollapse = function(self)
	if self.pullingNoteChartSet then
		return
	end
	local config = self.config
	config.collapse = not config.collapse
	self.gameController.noteChartSetLibraryModel.collapse = config.collapse
	self:debouncePullNoteChartSet()
end

SelectModel.update = function(self)
	local stateCounter = self.gameController.searchModel.stateCounter
	if self.searchStateCounter == stateCounter or self.pullingNoteChartSet then
		return
	end
	self.config.searchFilter = self.gameController.searchModel.searchFilter
	self.config.searchLamp = self.gameController.searchModel.searchLamp
	self.searchStateCounter = stateCounter
	self:debouncePullNoteChartSet()
end

SelectModel.scrollCollection = function(self, direction, destination)
	if self.pullingNoteChartSet then
		return
	end

	local collectionItems = self.gameController.collectionModel.items

	destination = math.min(math.max(destination or self.collectionItemIndex + direction, 1), #collectionItems)
	if not collectionItems[destination] or self.collectionItemIndex == destination then
		return
	end
	self.collectionItemIndex = destination

	local oldCollectionItem = self.collectionItem

	local collectionItem = collectionItems[self.collectionItemIndex]
	self.collectionItem = collectionItem
	self.config.collection = collectionItem.path

	self:debouncePullNoteChartSet(oldCollectionItem and oldCollectionItem.path == collectionItem.path)
end

SelectModel.scrollRandom = function(self)
	local noteChartSetItems = self.gameController.noteChartSetLibraryModel.items

	local destination = math.random(1, #noteChartSetItems)

	self:scrollNoteChartSet(nil, destination)
end

SelectModel.setConfig = function(self, item)
	self.config.noteChartSetEntryId = item.setId
	self.config.noteChartEntryId = item.noteChartId
	self.config.noteChartDataEntryId = item.noteChartDataId
end

SelectModel.scrollNoteChartSet = function(self, direction, destination)
	local noteChartSetItems = self.gameController.noteChartSetLibraryModel.items

	destination = math.min(math.max(destination or self.noteChartSetItemIndex + direction, 1), #noteChartSetItems)
	if not noteChartSetItems[destination] or self.noteChartSetItemIndex == destination then
		return
	end
	self.noteChartSetItemIndex = destination

	local oldNoteChartSetItem = self.noteChartSetItem

	local noteChartSetItem = noteChartSetItems[self.noteChartSetItemIndex]
	self.noteChartSetItem = noteChartSetItem
	self:setConfig(noteChartSetItem)

	self:pullNoteChart(oldNoteChartSetItem and oldNoteChartSetItem.setId == noteChartSetItem.setId)
end

SelectModel.scrollNoteChart = function(self, direction, destination)
	local noteChartItems = self.gameController.noteChartLibraryModel.items

	direction = direction or destination - self.noteChartItemIndex

	destination = math.min(math.max(destination or self.noteChartItemIndex + direction, 1), #noteChartItems)
	if not noteChartItems[destination] or self.noteChartItemIndex == destination then
		return
	end
	self.noteChartItemIndex = destination

	local noteChartItem = noteChartItems[self.noteChartItemIndex]
	self.noteChartItem = noteChartItem

	self:setConfig(noteChartItem)

	self:pullNoteChartSet(true)
	self:pullScore()
end

SelectModel.scrollScore = function(self, direction, destination)
	local scoreItems = self.gameController.scoreLibraryModel.items

	destination = math.min(math.max(destination or self.scoreItemIndex + direction, 1), #scoreItems)
	if not scoreItems[destination] or self.scoreItemIndex == destination then
		return
	end
	self.scoreItemIndex = destination

	local scoreItem = scoreItems[self.scoreItemIndex]
	self.scoreItem = scoreItem

	self.config.scoreEntryId = scoreItem.id
end

SelectModel.pullNoteChartSet = function(self, noUpdate)
	self.pullingNoteChartSet = true

	if not noUpdate then
		self.gameController.searchModel:setCollection(self.collectionItem)
		self.gameController.noteChartSetLibraryModel:updateItems()
	end

	local noteChartSetItems = self.gameController.noteChartSetLibraryModel.items
	self.noteChartSetItemIndex = self.gameController.noteChartSetLibraryModel:getItemIndex(
		self.config.noteChartDataEntryId,
		self.config.noteChartEntryId,
		self.config.noteChartSetEntryId
	)

	if not noUpdate then
		self.noteChartSetStateCounter = self.noteChartSetStateCounter + 1
	end

	local noteChartSetItem = noteChartSetItems[self.noteChartSetItemIndex]
	self.noteChartSetItem = noteChartSetItem
	if noteChartSetItem then
		self.config.noteChartSetEntryId = noteChartSetItem.setId
		self.pullingNoteChartSet = false
		return self:pullNoteChart(noUpdate)
	end

	self.config.noteChartSetEntryId = 0
	self.config.noteChartEntryId = 0
	self.config.noteChartDataEntryId = 0

	self.noteChartItem = nil
	self.scoreItem = nil

	self.gameController.noteChartLibraryModel:clear()
	self.gameController.scoreLibraryModel:clear()

	self.pullingNoteChartSet = false
end

SelectModel.pullNoteChart = function(self, noUpdate)
	self.gameController.noteChartLibraryModel:setNoteChartSetId(self.config.noteChartSetEntryId)

	local noteChartItems = self.gameController.noteChartLibraryModel.items
	self.noteChartItemIndex = self.gameController.noteChartLibraryModel:getItemIndex(
		self.config.noteChartDataEntryId,
		self.config.noteChartEntryId,
		self.config.noteChartSetEntryId
	)

	if not noUpdate then
		self.noteChartStateCounter = self.noteChartStateCounter + 1
	end

	local noteChartItem = noteChartItems[self.noteChartItemIndex]
	self.noteChartItem = noteChartItem
	if noteChartItem then
		self.config.noteChartEntryId = noteChartItem.noteChartId
		self.config.noteChartDataEntryId = noteChartItem.noteChartDataId
		return self:pullScore(noUpdate)
	end

	self.config.noteChartEntryId = 0
	self.config.noteChartDataEntryId = 0

	self.scoreItem = nil

	self.gameController.scoreLibraryModel:clear()
end

SelectModel.pullScore = function(self, noUpdate)
	local noteChartItems = self.gameController.noteChartLibraryModel.items
	local noteChartItem = noteChartItems[self.noteChartItemIndex]

	if not noteChartItem then
		return
	end

	if not noUpdate then
		self.gameController.scoreLibraryModel:setHash(noteChartItem.hash)
		self.gameController.scoreLibraryModel:setIndex(noteChartItem.index)
		self.gameController.scoreLibraryModel:updateItems()
	end

	local scoreItems = self.gameController.scoreLibraryModel.items
	self.scoreItemIndex = self.gameController.scoreLibraryModel:getItemIndex(self.config.scoreEntryId)

	local scoreItem = scoreItems[self.scoreItemIndex]
	self.scoreItem = scoreItem
	if scoreItem then
		self.config.scoreEntryId = scoreItem.id
	end
end

return SelectModel
