local json = require("json")

local AliasManager = {}

AliasManager.path = "userdata/aliases.json"

AliasManager.load = function(self)
	if love.filesystem.exists(self.path) then
		local file = io.open(self.path, "r")
		self.data = json.decode(file:read("*all"))
        file:close()
    else
        self.data = {}
	end
end

AliasManager.getAlias = function(self, type, key)
    local data = self.data
    return data[type] and data[type][key] or key
end

return AliasManager
