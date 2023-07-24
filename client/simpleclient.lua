local PATH,IP = ...

IP = IP or "127.0.0.1"

package.path = string.format("%s/client/?.lua;%s/skynet/lualib/?.lua", PATH, PATH)
package.cpath = string.format("%s/skynet/luaclib/?.so;%s/lsocket/?.so", PATH, PATH)

local socket = require "simplesocket"
local message = require "simplemessage"

local curTickCount = 0
local timeoutTickCount = 5000
local has_confirm_login = false


message.register(string.format("%s/proto/%s", PATH, "proto"))

message.peer(IP, 5678)
message.connect()

local event = {}

message.bind({}, event)

function event:__error(what, err, req, session)
	print("error", what, err)
end

function event:ping()
	print("ping")
end

function event:signin(req, resp)
	print("signin", req.userid, resp.ok)
	if resp.ok then
		message.request "ping"	-- should error before login
		message.request "login"
	else
		-- signin failed, signup
		message.request("signup", { userid = "alice" })
	end
end

function event:signup(req, resp)
	print("signup", resp.ok)
	if resp.ok then
		message.request("signin", { userid = req.userid })
	else
		error "Can't signup"
	end
end

function event:login(_, resp)
	print("login", resp.resp)
	if resp.resp == true then
		print("received login resp ok")
		--message.request "ping"
		message.request "client_confirm_agent"
	else
		error "Can't login"
	end
end

function event:push(args)
	print("server push", args.text)
end

function event:client_confirm_agent(args)
	print("client_confirm_agent get response ")
	if args.ok then
		has_confirm_login = true
	end
end

function event:client_request_match(args)
	if args.ok then
		print("server received matching request")
	end
end

message.request("login", { user_name = "alice" })

local attemplogincount = 0

while true do
	--[[
	if not has_confirm_login then
		if curTickCount >= timeoutTickCount then
			message.request("client_confirm_agent", {
					msg = tostring(attemplogincount)
			})
			curTickCount = 0
			attemplogincount = attemplogincount + 1
		else
			curTickCount = curTickCount + 1
		end
	end
	]]
	message.update()
	--message.request("sayhello", {msg = "aaaaaa"})
end
