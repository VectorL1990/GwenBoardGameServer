local skynet = require "skynet"
local service = require "service"
local log = require "log"

local lobby = {}
local users = {}
local rooms = {wait_rooms = {}, run_rooms = {}}
local wait_simple_match_user = {}
-- which contains all names which currently waiting for matching
local cur_match_room = {}

function lobby.new_user(fd, user_name)
  log("get inside lobbly.new_user")
  local agent = users[user_name]
  if not agent then
    agent = skynet.newservice "agent"
    users[user_name] = agent
  end
  skynet.call(agent, "lua", "assign", fd, user_name)
end

function lobby.player_ask_matching(fd, user_name)
  log("player ask matching fd: %s, user_name: %s", fd, user_name)
  table.insert(wait_simple_match_user, user_name)
end

function lobby.simple_match(user_name)
  if cur_match_room["room_id"] == nil then
    --[[
        which means current matching room is not full,
        add player to current matching room and remove
        player from wait for matching list
      ]]
    local uid = os.time() .. "-" .. math.random(1000, 9999)
    cur_match_room["room_id"] = uid
    cur_match_room["player_1"] = ""
    cur_match_room["player_2"] = ""
  else
    if cur_match_room["player_1"] == nil then
      cur_match_room["player_1"] = user_name
    else
      --[[
        which means current matching room is full,
        add this room to running rooms and the empty
        current matching room
      ]] 
      cur_match_room["player_2"] = user_name
      local room = skynet.newserivce "battle_room"
      rooms["run_rooms"][cur_match_room["room_id"]] = room
      skynet.call(room, "lua", "join_room")
      cur_match_room = {}
    end
  end
  table.remove(wait_simple_match_user, user_name)
end


service.init {
  command = lobby,
  info = users,
}
