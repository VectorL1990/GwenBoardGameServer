local skynet = require "skynet"
local service = require "service"
local proxy = require "socket_proxy"
local client = require "client"
local log = require "log"

local agent = {}
local data = {user_name = {}}
local cli = client.handler()

function cli:ping()
	log "ping"
end

function cli:client_confirm_agent(args)
	log("confirm client assign to agent %s", args.msg)
	return {ok = true}
end

function cli:client_request_match()
	log("client ask for matching")
	skynet.call(service.lobby, "lua", "player_ask_matching", data.fd, data.user_name)
	return {ok = true}
end

local function init_agent(fd, user_name)
	data.user_name = user_name
	data.fd = fd
	--log("agent subscribe fd %s", fd)
	--proxy.subscribe(fd)
	local ok, error = pcall(client.dispatch, {fd = fd})
end

function agent.assign(fd, user_name)
	skynet.fork(init_agent, fd, user_name)
end

service.init {
	command = agent,
	info = data,
	require = {
		"lobby",
		"login_manager",
	},
	init = client.init "proto",
}

