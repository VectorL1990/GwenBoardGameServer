local skynet = require "skynet"
local card_rule = {}

local battle_room

-- character_info should contains
-- name,
-- hp,
-- shield,
-- manual_effects = {
--  exchange_location = {
--    prereqs = {
--      injury = {trigger_val = 1},
--      distance = 2
--    },  
--  },
--  hurt = {
--    prereqs = {
--      distance = 2
--    }
--  }
-- },
-- passive_effects = {
--  retaliation = {
--    prereqs = {
--      being_hurt = {trigger_val = 1},
--      by_special_attribute = {"wound"}
--    },
--    effect_values = {hurt_val = 1}
--  }
-- }


-- effect_info should contains
-- effect_info = {
--   name = "fence_devour",  
--   prereqs = {
--     fence = {fence_nb = 1, distance = 5, max_hp = 5}
--   },
--   effect_values = {}
-- }


-- this table can be used for searching prerequisites for passive effects
-- and also for searching characters to be targets
prerequisite_trigger_func_table = {
  injury = {
    -- if character is hurt already, prerequisite satisfied
    trigger_func = function(room_data, target_grid, effect_info)
      if room_data[target_grid].cur_hp < room_data[target_grid].origin_hp then
        return true
      else
        return false
      end
    end
  },
  being_hurt = {
    -- if character is being hurt and hurt value is larger than prerequisite values
    trigger_func = function(room_data, target_grid, effect_info)
      if effect_info.hurt_values[1] > room_data[target_grid].prereqs.being_hurt.trigger_val then
        return true
      else
        return false
      end
    end
  },
  surround_card_nb = {
    -- this prerequisite requires grid informations surrounded target grid
    -- room_data contains information about distribution info of cards and grids
    -- trigger_grid contains information about which grid being triggered
    trigger_func = function(room_data, trigger_grid, effect_info)
      local grid_x = trigger_grid % room_data.board_w
      local grid_y = trigger_grid // room_data.board_w
      local surround_card_nb = 0
      if (grid_x ~= 0) then
        -- which means grid is left most
        if room_data.grid_card_distribution[tostring(trigger_grid - 1)] then
          -- which means left grid contains an available card
          surround_card_nb  = surround_card_nb + 1
        end
      end
      if (grid_x ~= (room_data.board_w - 1)) then
        if room_data.grid_card_distribution[tostring(trigger_grid + 1)] then
          surround_card_nb = surround_card_nb + 1
        end
      end
      if (grid_y ~= 0) then
        if room_data.grid_card_distribution[tostring(trigger_grid - room_data.board_w)] then
          surround_card_nb  = surround_card_nb + 1
        end
      end
      if (grid_y ~= (room_data.board_h - 1)) then
        if room_data.grid_card_distribution[tostring(trigger_grid + room_data.board_w)] then
          surround_card_nb = surround_card_nb + 1
        end
      end
      if surround_card_nb >= effect_info.prereq_values[0] then
        return true
      else
        return false
      end
    end
  },
  defence,
  by_special_attribute,
  by_special_string,
  by_hp,
  specific_card,
}

effect_calculation_table = {
  increase_hp = {
    calculation = function(room_data, launch_grid, target_grid, effect_info)
      room_data[target_grid].hp = room_data[target_grid].hp + effect_info.hurt_val
    end
  },
  hurt = {
  },
  fence_devour = {
    calculation = function(room_data, launch_grid, target_grid, effect_info)
      room_data[target_grid].dead = true
      room_data[target_grid] = room_data[launch_grid]
      table.remove(room_data, launch_grid)
    end
  },
}

character_info_table = {
  Alice = {
    hp = 5,
    shield = 0,
    default_effects = {
      hurt = {auto = false, hurt_val = 1},
    },
    manual_effects = {
      hurt = {auto = false, hurt_val = 1, cd = 2, available = 2}
    }
  },
  Bob = {
    hp = 4,
    shield = 0,
    manual_effects = {
      fence_devour = {
        auto = false,
        prereqs = {
          fence = {fence_nb = 1, distance = 5, max_hp = 3}
        },
      }
    },
    passive_effects = {
      retaliation = {
        prereqs = {
          being_hurt = {trigger_val = 1}
        },
        effect_values = {hurt_val = 1}
      }
    }
  },
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


function card_rule.get_chararcter_active_effects(character_name)
  for k, v in pairs(character_info_table) do
    if k == character_name then
      return true, character_info_table[character_name].default_effects
    end
  end
  return false, nil
end



-- active_effect_params should contain tables like
-- active_effect_params = {
--   hurt = {2},
--   draw_card = {1, 2}
-- }
-- every table inside should contains informations both include
-- effect type and effect values
-- effect values should be interpreted independently
local function search_passive_effects(character_info, active_effect_name, active_effect_params)
  local passive_effects = character_info_table[character_info.name].passive_effects
  for prereq_name, prereq_values in pairs(passive_effects.prereqs) do
    -- compare active effect params to passive effect params
    -- in order to determine whether passive effects are activated
    local get_correspond_effect = false
    for active_name, active_values in pairs(active_effect_params) do
      if prereq_name == active_name then
        get_correspond_effect = true
        if prerequisite_trigger_func_table[prereq_name].trigger_func(active_values, prereq_values) == false then
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

-- effect_info should contain following informations
-- auto - whether this effect no need to assign targets manually
-- self_target - whether this effect can be assigned to character launching this effect
-- prereq_name - 
------
-- room_data contains character info correspond to each grid
-- character info should contain following informations
-- character_name - name of this card
-- states - string list which contains all states like "spy" "wound"
-- hp
-- shield
function card_rule.calculate_effect(launch_grid, room_data, effect_info)
  if effect_info.auto == true then
    -- search all targets by conditions, which means 
    for grid, character_info in pairs(room_data.grid_card_distribution) do
      -- if this effect can not be assigned to launching character
      -- character who launches this effect can not be target
      if launch_grid == grid then
        if effect_info.self_target == false then
          goto continue
        end
      end
      -- we should filter targets by effect prerequisites
      local all_prereqs_satisfied = true
      for prereq_key, rereq_val in pairs(effect_info.prereqs) do
        if prerequisite_trigger_func_table[prereq_key].trigger_func(room_data, launch_grid, grid, effect_info) == false then
          -- which means this character is not target, skip
          all_prereqs_satisfied = false
          break
        end
      end
      if all_prereqs_satisfied == true then
        effect_calculation_table[effect_info.effect_name].calculation(room_data, launch_grid, grid, effect_info)
      end
      ::continue::
    end
  end
end


return card_rule
