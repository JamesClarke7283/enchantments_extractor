-- Taken from mcl_grindstone/init.lua
local function create_new_item(name_item, meta, wear)
    if not name_item then
        minetest.log("error", "[enchantments_extractor] create_new_item was given a nil name_item")
        return nil
    end

    -- Create the new ItemStack, stripping "_enchanted" from the name
    local base_name = string.gsub(name_item, "_enchanted", "")
    local new_item = ItemStack(base_name)
    if not new_item or new_item:is_empty() then
        minetest.log("error", "[enchantments_extractor] Failed to create new ItemStack for: " .. base_name)
        return nil
    end

    -- Set wear if provided
    if wear then
        new_item:set_wear(wear)
    end

    -- Set metadata if provided
    local new_meta = new_item:get_meta()
    new_meta:set_string("name", meta and meta:get_string("name") or "")

    -- Check if the item definition exists and if tt.reload_itemstack_description is available before calling
    local def = minetest.registered_items[base_name]
    if def and tt and tt.reload_itemstack_description then
        -- Only call reload_itemstack_description if _mcl_generate_description or snippets are to be applied
        if def._mcl_generate_description or (tt.snippets and tt.snippets.should_change(base_name, def)) then
            tt.reload_itemstack_description(new_item)
        end
    else
        minetest.log("error", "[enchantments_extractor] Cannot reload item description: Definition or function not found for item: " .. base_name)
    end

    return new_item
end



local function count_keys(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end



local function get_extractor_formspec()
    -- Define the formspec version and size
    local formspec = {
        "formspec_version[4]",
        "size[11.75,11.425]",
        
        -- Labels
        "label[0.375,0.375;", minetest.formspec_escape("Enchantment Extractor"), "]",
        "label[0.875,1.25;", minetest.formspec_escape("Input Book:"), "]",
        "label[3.875,1.25;", minetest.formspec_escape("Enchanted Item:"), "]",
        "label[6.875,1.25;", minetest.formspec_escape("Output Item:"), "]",
        "label[0.375,3.75;", minetest.formspec_escape("Output Books:"), "]",
        "label[0.375,5.95;", minetest.formspec_escape("Inventory"), "]",
        
        -- Slot backgrounds for the node's inventory
        mcl_formspec.get_itemslot_bg_v4(0.875, 1.5, 1, 1, 0, "mcl_formspec_itemslot.png^mcl_book_book_empty_slot.png"),
        mcl_formspec.get_itemslot_bg_v4(3.875, 1.5, 1, 1),
        mcl_formspec.get_itemslot_bg_v4(6.875, 1.5, 1, 1), -- Background for Output Item slot
        mcl_formspec.get_itemslot_bg_v4(0.375, 4, 8, 1, 0, "mcl_formspec_itemslot.png^mcl_book_book_empty_slot.png"),
        
        -- Slot lists for the node's inventory
        "list[context;input_book;0.875,1.5;1,1;]",
        "list[context;input_enchanted;3.875,1.5;1,1;]",
        "list[context;output_item;6.875,1.5;1,1;]", -- Slot for Output Item
        "list[context;output_books;0.375,4;8,1;]",
        
        -- Slot backgrounds for the player's inventory
        mcl_formspec.get_itemslot_bg_v4(0.375, 6.2, 9, 3),
        mcl_formspec.get_itemslot_bg_v4(0.375, 10.15, 9, 1),
        
        -- Slot lists for the player's inventory
        "list[current_player;main;0.375,6.2;9,3;9]",
        "list[current_player;main;0.375,10.15;9,1;]",
        
        -- Listrings to allow moving items between lists
        "listring[context;output_books]",
        "listring[current_player;main]",
        "listring[context;input_book]",
        "listring[current_player;main]",
        "listring[context;input_enchanted]",
        "listring[current_player;main]",
    }

    -- Return the concatenated formspec string
    return table.concat(formspec)
end





minetest.register_node("enchantments_extractor:enchantment_extractor", {
    description = "Enchantment Extractor",
    tiles = {
        "mcl_enchanting_table_top.png",
        "mcl_enchanting_table_bottom.png",
        "mcl_enchanting_table_side.png",
        "mcl_enchanting_table_side.png",
        "mcl_enchanting_table_side.png",
        "mcl_enchanting_table_side.png"
    },
    groups = {cracky = 3, pickaxey = 2},

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("input_book", 1)
        inv:set_size("input_enchanted", 1)
        inv:set_size("output_books", 8)
        inv:set_size("output_item", 1)
        local form = get_extractor_formspec()
        meta:set_string("formspec", form)
    end,

        -- This function will be called whenever an item is attempted to be put in the node's inventory
        allow_metadata_inventory_put = function(pos, listname, index, stack, player)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
        
            -- For 'input_book', allow any number of books
            if listname == "input_book" and stack:get_name() == "mcl_books:book" then
                return stack:get_count()
            elseif listname == "input_enchanted" then
                if mcl_enchanting.is_enchanted(stack:get_name()) then
                    local enchantments = mcl_enchanting.get_enchantments(stack)
                    local num_enchantments = count_keys(enchantments)
                    local num_books = inv:get_stack("input_book", 1):get_count()
                    minetest.log("action", "num_enchantments: " .. num_enchantments)
                    minetest.log("action", "num_books: " .. num_books)
        
                    -- Check available slots in 'output_books'
                    local output_books_list = inv:get_list("output_books")
                    local available_slots = 0

                    -- Count the number of empty slots
                    for _, itemstack in ipairs(output_books_list) do
                        if itemstack:is_empty() then
                            available_slots = available_slots + 1
                        end
                    end
        
                    -- Check space and consistency in 'output_item' slot
                    local output_item_stack = inv:get_stack("output_item", 1)
                    local space_in_output_item = output_item_stack:get_stack_max() - output_item_stack:get_count()
                    -- add a or statement to see if the input slot contains "book_enchanted" and the output slot contains "book"
                    local is_same_item = output_item_stack:is_empty() or (stack:get_name() == output_item_stack:get_name())
                    
                    -- Special case for enchanted books
                    if stack:get_name() == "mcl_enchanting:book_enchanted" and output_item_stack:get_name() == "mcl_books:book" then
                        is_same_item = true  -- Enchanted books become normal books after disenchantment
                    end
                    
                    minetest.log("action", "space_in_output_item: " .. space_in_output_item)
                    minetest.log("action", "is_same_item: " .. tostring(is_same_item))
                    minetest.log("action", "output_item_stack: " .. output_item_stack:get_name())
        
                    -- Allow putting the item if there are enough books, space in 'output_books', space in 'output_item', and the item types match
                    if num_books >= num_enchantments and num_enchantments > 0 and available_slots >= num_enchantments and space_in_output_item > 0 and is_same_item then
                        return stack:get_count()
                    end
                end
            end
        
            -- By default, don't allow putting items
            return 0
        end,
        

    -- This function will be called after an item is put in the node's inventory
    on_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "input_enchanted" then
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
    
            local input_book_stack = inv:get_stack("input_book", 1)
            local num_books = input_book_stack:get_count()
    
            local enchantments = mcl_enchanting.get_enchantments(stack)
            local num_enchantments = count_keys(enchantments)
    
            if num_books >= num_enchantments then
                -- Decrement the number of books
                if num_enchantments > 1 and stack:get_name() == "mcl_enchanting:book_enchanted" then
                    input_book_stack:take_item(num_enchantments - 1)
                    inv:set_stack("input_book", 1, input_book_stack)
                end
    
                -- Create a new disenchanted item
                local new_item
                if string.find(stack:get_name(), "book_enchanted") then
                    new_item = ItemStack("mcl_books:book")
                else
                    new_item = create_new_item(stack:get_name(), stack:get_meta(), stack:get_wear())
                end
                if not string.find(stack:get_name(), "book_enchanted") then
                    inv:set_stack("output_item", 1, new_item)
                end
                -- Create and add enchanted books for each enchantment
                for enchantment, level in pairs(enchantments) do
                    local enchanted_book = ItemStack("mcl_books:book")
                    mcl_enchanting.enchant(enchanted_book, enchantment, level)
                    inv:add_item("output_books", enchanted_book)
                end
    
                -- Remove the enchanted item from the input slot
                inv:set_stack("input_enchanted", 1, nil)
            end
        end
    end,
    _mcl_blast_resistance = 1200,
    _mcl_hardness = 5,
})

minetest.register_craft({
    output = 'enchantments_extractor:enchantment_extractor',
    recipe = {
        {'', 'mcl_enchanting:table', ''},
        {'mcl_core:emeraldblock', 'mcl_core:obsidian', 'mcl_core:emeraldblock'},
        {'mcl_core:obsidian', 'mcl_core:obsidian', 'mcl_core:obsidian'}
    }
})
