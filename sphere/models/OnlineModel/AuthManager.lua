local Class = require("Class")
local thread	= require("thread")
local inspect = require("inspect")

local AuthManager = Class:new()

AuthManager.checkUserAsync = function(self)
	local webApi = self.webApi
	local api = webApi.api
	local config = self.config

	webApi.token = config.token
	if not config.session.user_id then
		return
	end

	print("GET " .. api.users[config.session.user_id])
	local user = api.users[config.session.user_id]:get()
	config.user = user or {}
end
AuthManager.checkUser = thread.coro(AuthManager.checkUserAsync)

AuthManager.checkSessionAsync = function(self)
	local webApi = self.webApi
	local api = webApi.api
	local config = self.config

	webApi.token = config.token

	print("check session")
	print("GET " .. api.auth.check)
	local response, code, headers = api.auth.check:_get()
	if not response then
		print(code, headers)
		return
	end
	print(inspect(response))
	config.session = response.session or {}
	if not config.session.active then
		config.session = {}
		config.token = ""
	end

	self:checkUserAsync()
end
AuthManager.checkSession = thread.coro(AuthManager.checkSessionAsync)

AuthManager.updateSessionAsync = function(self)
	local webApi = self.webApi
	local api = webApi.api
	local config = self.config

	webApi.token = config.token

	print("update session")
	print("POST " .. api.auth.update)
	local response, code, headers = api.auth.update:_post()
	if not response then
		print(code, headers)
		return
	end

	if code ~= 200 then
		print(code, response.message)
		return
	end

	config.session = response.session
	config.token = response.token

	print("updated")

	self:checkUserAsync()
end
AuthManager.updateSession = thread.coro(AuthManager.updateSessionAsync)

AuthManager.quickGetKeyAsync = function(self)
	local api = self.webApi.api
	local config = self.config
	config.quick_login_key = ""

	print("GET " .. api.auth.quick)
	local response, code, headers = api.auth.quick:_get()
	if not response then
		print(code, headers)
		return
	end

	config.quick_login_key = response.key
	local url = api.html.auth.quick .. "?method=POST&key=" .. response.key
	print(url)
	love.system.openURL(url)
end
AuthManager.quickGetKey = thread.coro(AuthManager.quickGetKeyAsync)

AuthManager.quickGetTokenAsync = function(self)
	local api = self.webApi.api
	local config = self.config
	local key = config.quick_login_key

	print("PUT " .. api.auth.quick .. "?key=" .. key)
	local response, code, headers = api.auth.quick:_put({
		key = key,
	})
	if not response then
		print(code, headers)
		return
	end

	if code ~= 200 then
		print(response.message)
		if code >= 400 and code < 500 then
			self:quickGetKeyAsync()
		end
		return
	end

	config.quick_login_key = ""
	config.token = response.token or ""
	config.session = response.session or {}

	self:checkUserAsync()
end
AuthManager.quickGetToken = thread.coro(AuthManager.quickGetTokenAsync)

AuthManager.quickLogin = function(self)
	print("quick login")
	local config = self.config
	local key = config.quick_login_key

	if key and #key ~= 0 then
		self:quickGetToken()
	else
		self:quickGetKey()
	end
end

AuthManager.loginAsync = function(self, email, password)
	print("login")
	local api = self.webApi.api
	local config = self.config

	print("POST " .. api.auth.login)
	local response, code, headers = api.auth.login:_post({
		email = email,
		password = password,
	})
	if not response then
		print(code, headers)
		return
	end

	if code ~= 200 then
		print(code, response.message)
		return
	end

	config.token = response.token
	config.session = response.session

	self:checkUserAsync()
end
AuthManager.login = thread.coro(AuthManager.loginAsync)

AuthManager.logoutAsync = function(self)
	local webApi = self.webApi
	local api = webApi.api
	local config = self.config

	config.session = {}
	config.user = {}
	config.token = ""

	webApi.token = config.token

	print("POST " .. api.auth.logout)
	api.auth.update:post()
end
AuthManager.logout = thread.coro(AuthManager.logoutAsync)

return AuthManager
