local function get_extractor_formspec()
    -- Define the formspec version and size
    local formspec = {
        "formspec_version[4]",
        "size[11.75,10.425]",
    }

    -- Helper function to add inventory components to the formspec
    local function add_inventory_components(label, bg, list, listring)
        table.insert(formspec, "label" .. label)
        table.insert(formspec, bg)  -- This will add the background right after the label
        table.insert(formspec, "list" .. list)
        table.insert(formspec, "listring" .. listring)
    end

    -- Define labels, backgrounds, lists, and listrings for the UI elements with consistent positioning
    local labels = {
        "[0.375,0.375;" .. minetest.formspec_escape("Enchantment Extractor") .. "]",
        "[0.375,1;" .. minetest.formspec_escape("Input Book:") .. "]",
        "[2.375,1;" .. minetest.formspec_escape("Enchanted Item:") .. "]",
        "[0.375,2.5;" .. minetest.formspec_escape("Output Books:") .. "]",
        "[0.375,4.7;" .. minetest.formspec_escape("Inventory") .. "]",
    }

    local bgs = {
        mcl_formspec.get_itemslot_bg_v4(0.375, 0.75, 1, 1),
        mcl_formspec.get_itemslot_bg_v4(2.375, 0.75, 1, 1),
        mcl_formspec.get_itemslot_bg_v4(0.375, 3, 8, 1),
        mcl_formspec.get_itemslot_bg_v4(0.375, 5.1, 9, 3),
        mcl_formspec.get_itemslot_bg_v4(0.375, 9.05, 9, 1),
    }

    local lists = {
        "[context;input_book;0.375,0.75;1,1;]",
        "[context;input_enchanted;2.375,0.75;1,1;]",
        "[context;output_books;0.375,3;8,1;]",
        "[current_player;main;0.375,5.1;9,3;9]",
        "[current_player;main;0.375,9.05;9,1;]",
    }

    local listrings = {
        "[context;output_books]",
        "[current_player;main]",
        "[context;input_book]",
        "[current_player;main]",
        "[context;input_enchanted]",
        "[current_player;main]",
    }

    -- Add each component group to the formspec
    for i = 1, #labels do
        add_inventory_components(labels[i], bgs[i], lists[i], listrings[i])
    end

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
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        minetest.show_formspec(clicker:get_player_name(), "enchantments_extractor:enchantment_extractor_form", get_extractor_formspec())
    end,
    _mcl_blast_resistance = 1200,
    _mcl_hardness = 5
})