--[[
  login_manager is used to deal with login operations, like
  1. load user informations from db
  2. modify or write infomation to db
  3. Search and verify login and signup information from users
  4. 
]]

local skynet = require "skynet"
local service = require "service"
local client = require "client"
local log = require "log"

local login_manager = {}
local users = {}

local online_users = {}

local cli = client.handler()

local login_resp = {resp = true}

test_global_table = {
  test1 = 1,
  test2 = 2,
}

function cli:login(args)
  log("login user_name = %s", args.user_name)
  if online_users[args.user_name] == nil then
    table.insert(online_users, args.user_name)
  end
  self.user_name = args.user_name
  self.exit = true
  return login_resp
end


function login_manager.shakehand(fd)
  log("test global table element: %s", test_global_table["test1"])
  log("get inside login_manager.shakehand")
  local c = client.dispatch {fd = fd}
  log("get out of while loop")
  return c.user_name
end

service.init {
  command = login_manager,
  info = users,
  init = client.init "proto"
}

