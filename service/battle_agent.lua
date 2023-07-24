local skynet = require "skynet"
local service = require "service"
local log = require "log"
local client = require "client"

local agent_cmd = {}
local room
local cli = client.handler()

function agent_cmd.sdf()
  
end

function cli:play_card(args)
  local action_info = {
    -- room should know who triggered an action
    id = args.id,
    -- action type
    action_type = args.action_type,
    card_name = args.card_name,
  }
  skynet.call(room, "lua", "client_action", action_info)
end

service.init {
  command = agent_cmd,
  init = client.init "proto"
}
