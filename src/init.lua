-- Taken from mcl_grindstone/init.lua
local function create_new_item(name_item, meta, wear)
    local new_item = ItemStack(string.gsub(name_item, "_enchanted", ""))
    if wear ~= nil then
            new_item:set_wear(wear)
    end
    local new_meta = new_item:get_meta()
    new_meta:set_string("name", meta:get_string("name"))
    tt.reload_itemstack_description(new_item)
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
            
            -- Check if the 'output_item' slot is empty
            if listname == "input_enchanted" and inv:is_empty("output_item") then
                -- Check if the enchanted item is indeed enchanted
                if mcl_enchanting.is_enchanted(stack:get_name()) then
                    local enchantments = mcl_enchanting.get_enchantments(stack)
                    local num_enchantments = count_keys(enchantments)
                    
                    -- Check if there are enough books and enough space in 'output_books'
                    local num_books = inv:get_stack("input_book", 1):get_count()
                    local available_slots = #inv:get_list("output_books") 
                    minetest.log("action", "Available slots: " .. available_slots)
                    -- Iterate over the ItemStacks in inv:get_list("output_books") to check the number of slots used, use itemstack:get_count() to get the number of items in the stack
                    for _, itemstack in ipairs(inv:get_list("output_books")) do
                        available_slots = available_slots - itemstack:get_count()
                        minetest.log("action", "Available slots: " .. available_slots)
                    end

                    -- Allow putting the item only if there are enough books and enough space
                    if num_books >= num_enchantments and num_enchantments > 0 and available_slots >= num_enchantments then
                        return stack:get_count()
                    end
                end
            end
            
            -- For 'input_book', allow any number of books
            if listname == "input_book" and stack:get_name() == "mcl_books:book" then
                return stack:get_count()
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
                input_book_stack:take_item(num_enchantments)
                inv:set_stack("input_book", 1, input_book_stack)
    
                -- Create a new disenchanted item
                local new_item
                if string.find(stack:get_name(), "book_enchanted") then
                    new_item = ItemStack("mcl_books:book")
                else
                    new_item = create_new_item(stack:get_name(), stack:get_meta(), stack:get_wear())
                end
                inv:set_stack("output_item", 1, new_item)
    
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
