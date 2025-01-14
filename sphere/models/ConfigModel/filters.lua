local function newInputModeScoreFilter(name, inputMode)
	return {
		name = name,
		check = function(score)
			return score.inputMode == inputMode
		end
	}
end

return {
	notechart = {
		{name = "No filter"},
		{name = "4K", string = "4key"},
		{name = "5K", string = "5key"},
		{name = "6K", string = "6key"},
		{name = "7K", string = "7key"},
		{name = "8K", string = "8key"},
		{name = "9K", string = "9key"},
		{name = "10K", string = "10key"},
		-- {
		-- 	name = "4K+10K",
		-- 	condition = 'noteChartDatas.inputMode = "4key" OR noteChartDatas.inputMode = "10key"',
		-- },
	},
	score = {
		{name = "No filter"},
		{name = "FC", check = function(score)
			return score.missCount == 0
		end},
		newInputModeScoreFilter("4K", "4key"),
		newInputModeScoreFilter("5K", "5key"),
		newInputModeScoreFilter("6K", "6key"),
		newInputModeScoreFilter("7K", "7key"),
		newInputModeScoreFilter("8K", "8key"),
		newInputModeScoreFilter("9K", "9key"),
		newInputModeScoreFilter("10K", "10key"),
	}
}
