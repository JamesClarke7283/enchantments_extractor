-- Taken from mcl_grindstone/init.lua
local function create_new_item(name_item, meta, wear)
    local new_item = ItemStack(name_item)
    if wear ~= nil then
            new_item:set_wear(wear)
    end
    local new_meta = new_item:get_meta()
    new_meta:set_string("name", meta:get_string("name"))
    tt.reload_itemstack_description(new_item)
    return new_item
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
        "label[0.375,3.75;", minetest.formspec_escape("Output Books:"), "]",
        "label[0.375,5.95;", minetest.formspec_escape("Inventory"), "]",
        
        -- Slot backgrounds for the node's inventory
        mcl_formspec.get_itemslot_bg_v4(0.875, 1.5, 1, 1, 0, "mcl_formspec_itemslot.png^mcl_book_book_empty_slot.png"),
        mcl_formspec.get_itemslot_bg_v4(3.875, 1.5, 1, 1),
        mcl_formspec.get_itemslot_bg_v4(0.375, 4, 8, 1, 0, "mcl_formspec_itemslot.png^mcl_book_book_empty_slot.png"),
        
        -- Slot lists for the node's inventory
        "list[context;input_book;0.875,1.5;1,1;]",
        "list[context;input_enchanted;3.875,1.5;1,1;]",
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
        local form = get_extractor_formspec()
        meta:set_string("formspec", form)
    end,

        -- This function will be called whenever an item is attempted to be put in the node's inventory
        allow_metadata_inventory_put = function(pos, listname, index, stack, player)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
        
            if listname == "input_book" and stack:get_name() == "mcl_books:book" then
                -- Allow any number of books
                return stack:get_count()
            elseif listname == "input_enchanted" then
                if mcl_enchanting.is_enchanted(stack:get_name()) then
                    local input_book_stack = inv:get_stack("input_book", 1)
                    local num_books = input_book_stack:get_count()
                    local enchantments = mcl_enchanting.get_enchantments(stack)
                    local num_enchantments = table.getn(enchantments) -- Get the number of different enchantments
        
                    -- Only allow the enchanted item to be placed if there are enough books
                    if num_books >= num_enchantments then
                        return stack:get_count()
                    else
                        -- Not enough books, do not allow the enchanted item to be placed
                        return 0
                    end
                end
            end
        
            -- Disallow placing items by default
            return 0
        end,        

    -- This function will be called after an item is put in the node's inventory
    -- This function will be called after an item is put in the node's inventory
    on_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "input_enchanted" then
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()

            local input_book_stack = inv:get_stack("input_book", 1)
            local num_books = input_book_stack:get_count()

            local enchantments = mcl_enchanting.get_enchantments(stack)
            local num_enchantments = table.getn(enchantments)

            if num_books >= num_enchantments then
                -- Disenchant the item and decrement the books
                local new_item
                if string.find(stack:get_name(), "book_enchanted") then
                    -- If it's an enchanted book, replace it with a normal book
                    new_item = ItemStack("mcl_books:book")
                else
                    -- For other enchanted items, create a new disenchanted item
                    new_item = create_new_item(stack:get_name(), stack:get_meta(), stack:get_wear())
                end
                inv:set_stack("output_books", 1, new_item)  -- Place the new item in the output slot

                -- Decrement the number of books
                input_book_stack:take_item(num_enchantments)
                inv:set_stack("input_book", 1, input_book_stack)

                -- Remove the enchanted item from the input slot
                inv:set_stack("input_enchanted", 1, nil)
            end
        end
    end,



    _mcl_blast_resistance = 1200,
    _mcl_hardness = 5,
})
