local skynet = require "skynet"
local card_rule = {}

local battle_room

--[[
  there should be a effect triggering tree,
  which can search all passive effects trigger by active effects
]]

trigger_prerequisite_enum = {
  being_hurt = {
    trigger_func = function(active_hurt, threshold)
      if active_hurt[1] > threshold[1] then
        return true
      end
    end
  },
  surround_card_nb,
  defence,
  by_special_attribute,
  by_special_string,
  by_hp,
  specific_card,
}

effect_enum = {
  hurt,
  hurt_specific,
  hurt_up,
  hurt_left,
  hurt_right,
  hurt_down,
  move,
  draw_card,
  change_card,
  add_attribute,
  add_string,
  add_hp
}

character_name_enum = {
  Baster,
  Alice,
  Bob,
}

character_setup_effects_enum = {
  
}

character_active_effects_enum = {
  Baster = {
    hurt_specific = {
      2, -- distance
      1, -- hurt value
    }
  },
  Alice = {
    move = {
      0, -- direction 0 = arbitrary
      1, -- move distance
    }
  },
}

character_passive_effects_enum = {
  Baster = {
    prerequisites = {
      being_hurt = { 
        2 -- if hurt value is larger than this value, activated
      }
    }, 
    effects = {
      hurt_specific = { 
        2, -- distance
        1  -- hurt value
      }
    }
  },
  Alice = {prerequisites = {"surround_card_nb"}, effects = {"hurt_up"}},
  Bob = {prerequisites = {"move"}, effects = {"add_hp"}},
}

function card_rule.get_character_setup_effects(args)
  for k, v in pairs(character_setup_effects_enum) do
    if k == args.name then
        return true, character_setup_effects_enum[args.name]
    end
  end
  return false, {}
end


function card_rule.get_chararcter_active_effects(args)
  for k, v in pairs(character_active_effects_enum) do
    if k == args.name then
      return true, character_active_effects_enum[args.name]
    end
  end
  return false, nil
end


--[[
  active_effect_params should contain tables like
  active_effect_params = {
    hurt = {2},
    draw_card = {1, 2}
  }
  every table inside should contains informations both include
  effect type and effect values
  effect values should be interpreted independently
]]
local function search_passive_effects(character_info, active_effect_name, active_effect_params)
  local passive_effects = character_passive_effects_enum[character_info.name]
  for prereq_name, prereq_values in pairs(passive_effects.prerequisites) do
    -- compare active effect params to passive effect params
    -- in order to determine whether passive effects are activated
    local get_correspond_effect = false
    for active_name, active_values in pairs(active_effect_params) do
      if prereq_name == active_name then
        get_correspond_effect = true
        if trigger_prerequisite_enum[prereq_name].trigger_func(active_values, prereq_values) == false then
          -- which means this prerequisite is not satisfied
          return false
        end
        break
      end
    end
    if get_correspond_effect == false then
      return false
    end
  end
  -- which means prerequisites are all satisfied
  return true
end

local function trigger_prerequisite(launch_grid, target_grid, args)
  -- 1. get corresponding character information in that grid first
  -- 2. tell whether passive effects of that character are activated
  -- 3. if return true which means we should launch all passive effects
end

local function trigger_active_effects(args)
  -- 1. if passive effects are activated, trigger all
  -- 2. update target characters' states
  -- 3. send latest characters' information to clients
  
end

local function attack(board_array2d, 
  launch_grid, 
  target_grid,
  restrict_dis, 
  hurt)
  local offset = math.abs(launch_grid['x'] - target_grid['x']) + math.abs(launch_grid['y'] - target_grid['y'])
  if offset > restrict_dis then
    return false
  end
  local character_id = skynet.call(battle_room, "lua", "get_character", target_grid)
  local hp = skynet.call(battle_room, "lua", "get_character_hp", target_grid)
  hp = hp - hurt
  skynet.call(battle_room, "lua", "set_character_hp", hp)
  return true
end


local function retaliation(board_array2d, 
  apply_grid, 
  apply_type,
  retaliation_param_1)
  -- retaliation_param_1 means hurt value
  

  local x = apply_grid['x']
  local y = apply_grid['y']
  if apply_type == 0 then
    -- which means retaliation only hurts the guy
    -- who attacks this character
    local character_id = skynet.call(battle_room, "lua", "get_grid_character", apply_grid)
    local hp = skynet.call(battle_room, "lua", "get_character_hp", apply_grid)
    hp = hp + retaliation_param_1
    skynet.call(battle_room, "lua", "set_character_hp", character_id, hp)
  elseif apply_type == 1 then
  elseif apply_type == 2 then

  elseif apply_type == 3 then
    local board_w = skynet.call(battle_room, "lua", "get_board_w")
    local board_h = skynet.call(battle_room, "lua", "get_board_h")
    -- hurts up, down, left, right
    for i = -1, 1 do
      for j = -1, 1 do
        if i == 0 or j == 0 then
          -- continue
        else
          if x + i < 0 or x + i > board_w or y + j < 0 or y + j > board_h then
            -- continue
          else
            local tmp_grid = {}
            tmp_grid['x'] = apply_grid['x'] + i
            tmp_grid['y'] = apply_grid['y'] + j
            local character_id = skynet.call(battle_room, "lua", "get_grid_character", tmp_grid)
            local hp = skynet.call(battle_room, "lua", "get_character_hp", character_id)
            hp = hp + retaliation_param_1
            skynet.call(battle_room, "lua", "set_character_hp", character_id, hp)
          end
        end
      end
    end
  end
end

function card_rule.apply_effect(board_array2d)
  
end

return card_rule
