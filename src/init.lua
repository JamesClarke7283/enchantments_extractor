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
        inv:set_size("output_books", 9)
        local form = get_extractor_formspec()
        meta:set_string("formspec", form)
    end,
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "input_book" then
            if stack:get_name() == "mcl_books:book" then
                return stack:get_count()
            else
                return 0 -- Disallow other items
            end
        elseif listname == "input_enchanted" then
            -- Here you should check for an "enchanted" group or a specific itemstring
            -- This is a placeholder condition:
            if minetest.get_item_group(stack:get_name(), "enchanted") > 0 then
                return stack:get_count()
            else
                return 0 -- Disallow other items
            end
        elseif listname == "output_books" then
            return 0 -- Disallow placing items manually in output
        end
        return 0 -- Disallow by default for any other lists
    end,
    _mcl_blast_resistance = 1200,
    _mcl_hardness = 5
})