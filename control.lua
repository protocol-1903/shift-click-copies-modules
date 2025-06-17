script.on_event(defines.events.on_entity_settings_pasted, function (event)
  local source_prototype = event.source.type == "entity-ghost" and event.source.ghost_prototype or event.source.prototype
  local destination_prototype = event.destination.type == "entity-ghost" and event.destination.ghost_prototype or event.destination.prototype
  local module_inv = source_prototype.type == "mining-drill" and defines.inventory.mining_drill_modules or
      source_prototype.type == "assembling-machine" and defines.inventory.assembling_machine_modules or
      source_prototype.type == "lab" and defines.inventory.lab_modules or
      source_prototype.type == "beacon" and defines.inventory.beacon_modules or
      source_prototype.type == "furnace" and defines.inventory.furnace_modules or
      source_prototype.type == "rocket-silo" and defines.inventory.rocket_silo_modules

  local proxy = event.source.item_request_proxy

  local player = game.players[event.player_index]
  local stacks = {}
  local insert_plan = {}
  local request_plan = {}

  -- only runs if both source and destination module inventories
  if source_prototype.module_inventory_size == 0 or destination_prototype.module_inventory_size == 0 then return end

  if event.source.get_module_inventory() and event.source.get_module_inventory().get_item_count() > 0 then
    for _, stack in pairs(event.source.get_module_inventory().get_contents()) do
      stacks[#stacks+1] = stack
    end
  end

  -- find any proxies that point to this entity
  for _, proxy in pairs(event.source.surface.find_entities_filtered{name = "item-request-proxy", area = event.source.bounding_box}) do
    if proxy.proxy_target == event.source then

      game.print("insert: " .. #proxy.insert_plan)
      game.print("remove: " .. #proxy.removal_plan)

      -- might have one, neither, or both
      for _, list in pairs(proxy.insert_plan) do
        game.print("some insertion", {skip = defines.print_skip.never})
        for _, item in pairs(list.items.in_inventory) do
          -- if the correct inventory
          if item.inventory == module_inv then
            local found = false

            -- find and add it to the correct stack index
            for _, stack in pairs(stacks) do
              -- if the same name and quality
              if stack.name == list.id.name and stack.quality == list.id.quality then
                stack.count = stack.count + 1
                found = true
                break
              end
            end

            if not found then
              stacks[#stacks+1] = {
                name = list.id.name,
                quality = list.id.quality,
                count = 1
              }
            end
          end
        end
      end

      -- remove entities that are in the removal plan
      for _, list in pairs(proxy.removal_plan) do
        game.print("some removal", {skip = defines.print_skip.never})
        for _, item in pairs(list.items.in_inventory) do
          -- if the correct inventory
          if item.inventory == module_inv then
            for _, stack in pairs(stacks) do
              -- if the same name and quality
              if stack.name == list.id.name and (stack.quality == list.id.quality or (stack.quality == "normal" and list.id.quality == nil)) then
                stack.count = stack.count - 1
                break
              end
            end
          end
        end
      end
    end
  end

  -- remove empty stacks
  for index, stack in pairs(stacks) do
    if stack.count == 0 then
      stacks[index] = nil
    end
  end

  -- remove items if required
  if table_size(stacks) == 0 then return end
  
  -- attempt to insert from player if it is not a ghost and player is not remote view
  if event.destination.get_module_inventory() and player.controller_type ~= defines.controllers.remote then
    -- if destination has modules, remove


    -- attempt to insert new modules
    for index, stack in pairs(stacks) do
      if player.get_main_inventory().get_item_count(stack) > 0 then
        local removed = player.get_main_inventory().remove(stack)
        event.destination.get_module_inventory().insert{
          name = stack.name,
          quality = stack.quality,
          count = removed
        }
        if stack.count == removed then
          stacks[index] = nil
        end
      end
    end
  end

  local new_request = {}
  for _, stack in pairs(stacks) do
    
  end

  -- if event.destination.type ~= "entity-ghost" then
  --   -- for each request (different item types count as different requests)
  --   for p, plan in pairs(insert_plans) do
  --     -- if target inventory is valid
  --     if event.source.get_module_inventory().index == plan.items.in_inventory[1].inventory then
  --       -- amount to insert or amount in players inventory, whichever is greater
  --       local insert = inventory.get_item_count{name = plan.id.name, quality = plan.id.quality} >= #plan.items.in_inventory and #plan.items.in_inventory or inventory.get_item_count{name = plan.id.name, quality = plan.id.quality}
  --       -- if player has items in inventory
  --       if insert > 0 then
  --         -- add to module inventory and remove from player
  --         event.destination.get_module_inventory().insert{name = plan.id.name, quality = plan.id.quality, count = insert}
  --         inventory.remove({name = plan.id.name, quality = plan.id.quality, count = insert})
  --       end
  --     end
  --   end
  -- end
  -- local stack = event.destination.type ~= "entity-ghost" and event.entity.get_module_inventory().get_item_count() or 0
  -- -- add missing modules to a new list
  -- for p, plan in pairs(proxy.insert_plan) do
  --   -- if target inventory is valid
  --   if plan.items.in_inventory[1].inventory == module_inv then
  --     -- if amount in module slots is less than requested
  --     if event.destination.get_module_inventory().get_item_count{name = plan.id.name, quality = plan.id.quality} < #plan.items.in_inventory then
  --       new_requests[#new_requests+1] = {
  --         id = {
  --           name = plan.id.name,
  --           quality = plan.id.quality
  --         },
  --         items = {in_inventory = {}}
  --       }
  --       for i=1, #plan.items.in_inventory - event.destination.get_module_inventory().get_item_count{name = plan.id.name, quality = plan.id.quality}, 1 do
  --         new_requests[#new_requests].items.in_inventory[#new_requests[#new_requests].items.in_inventory+1] = {
  --           inventory = event.destination.get_module_inventory().index,
  --           stack = stack
  --         }
  --         stack = stack + 1
  --       end
  --     end
  --   else
  --     new_requests[#new_requests+1] = plan
  --   end
  -- end
  -- if proxy.proxy_target.get_module_inventory().get_item_count() ~= 0 then
  --   proxy.destroy()
  --   if #new_requests > 0 then
  --     event.entity.surface.create_entity{
  --       name = "item-request-proxy",
  --       position = event.entity.position,
  --       force = event.entity.force,
  --       target = event.entity,
  --       modules = new_requests
  --     }
  --   end
  -- end
end)