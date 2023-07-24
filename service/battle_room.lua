local skynet = require "skynet"
local service = require "service"
local client = require "client"
local log = require "log"

local battle_room_cmd = {}
local room_players = {}
local room_state = battle_state_enum["default"]
local character_infos = {}
local room_data = {
  room_running = false,
  room_time = 0,
  cur_control_player = 0,
  room_wait_switch_player_time = 0,
  action_confirm_list = {},
  -- key = grid id
  -- value = card info 
  card_grid_distribution = {},
}

battle_const = {
  max_switch_player_time = 10,
}


-- server switches room states ignoring clients' states, 
-- clients will play animations independently, server goes straight
-- to state that waits for client's actions, and start couting
battle_state_enum = {
  default,
  wait_player_action,
  -- optional state, it turns to this state if active effect
  -- requires target assignment
  wait_choose_active_target
}

player_action_type = {
  play_card,
  assign_active_effect_target,
  launch_move,
  launch_special_skill,
  end_round
}

function battle_room_cmd.onready()
  
end

function battle_room_cmd.join_room(fd, userid)

end

function battle_room_cmd.Mainloop()
  -- this is the main loop which drives room running
  -- this function runs in "main thread" of every single room service
  while room_data.room_running do
    local cur_time = os.time()
    local dT = cur_time - room_data.room_time



    -- in main loop server is only responsible for counting whether client is time out
    -- for launching various kinds of actions including
    -- 1. play cards
    -- 2. move a card
    -- 3. launch special skill
    -- if a player is time out, switch controller to another player
    if (room_data.room_wait_switch_player_time >= battle_const.max_switch_player_time) then
      -- which means it's time to switch controller 
      local ok = pcall(battle_room_cmd.player_end_round)
    else
      -- keep counting time
      room_data.room_wait_switch_player_time = room_data.room_wait_switch_player_time + dT
    end
    



    skynet.sleep(10)
  end
end


function battle_room_cmd.player_end_round()
  room_data.cur_control_player = room_data.cur_control_player + 1
  local players_nb = #room_players
  if room_data.cur_control_player >= players_nb then
    room_data.cur_control_player = 0
  end
  room_data.room_wait_switch_player_time = 0
end

--[[
  --
]]
function battle_room_cmd.client_action(action_info)
  if action_info.action_type == player_action_type.play_card then
    -- get card information from card_rule
    -- trigger all active effects of the card
    local character_name = {action_info.card_name}
    local ok, active_effects = card_rule.get_chararcter_active_effects(character_name)
    if ok == false or active_effects == nil then
      -- which means this character contains no active effects
      -- only add hp
    else
      -- go through all active effects
      for i, v in ipairs(active_effects) do
          -- if effect requires client to determine something
          -- send message
      end
    end
  elseif action_info.action_type == player_action_type.assign_active_effect_target then
    -- action info contains information of active effects which requires target assignment
    -- calculate battle states 
    local target = action_info.target_info
  elseif action_info.action_type == player_action_type.launch_move then
    
  elseif action_info.action_type == player_action_type.launch_special_skill then

  elseif action_info.action_type == player_action_type.end_round then
    local ok = pcall(battle_room_cmd.player_end_round)
  end
end

function battle_room_cmd.get_character_in_grid()
  -- return current information character contained
end

function battle_room_cmd.trigger_active_effects(args)
  -- args contain informations including
  -- 1. card name
  -- 2. 
  local gridxy = {args.x, args.y}
  local ok, character = pcall(battle_room_cmd.get_character_in_grid, gridxy)
  -- if pcall failed or character info is empty
  if character == nil then
  else
    -- go through all active effects character contained
    local character_name = character.name
    local ok, active_effects = pcall(card_rule.get_chararcter_active_effects, {character_name})
    local wait_player_assign_target = false
    for i, v in ipairs(active_effects) do
      -- we should consider two cases in this step
      -- if there's no necessary to assign target applying active effect, trigger effect automatically
      -- if it requires player to assign target manually, switch room to another state
      if v.auto == true then
        wait_player_assign_target = true
        break
      end

      --[[
      if v.auto == true then
        local effect_args = { v.effect_info}
        local ok = pcall(card_rule.trigger_active_effects, effect_args)
      else
        wait_player_assign_target = true
      end
      ]]
      
    end
    -- if wait_player_assign_target is true, we should send msg to clients to
    -- ask player to assign target
  end

end




service.init {
  command = battle_room_cmd,
  init = client.init "proto"
}
