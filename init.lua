
-- bell_positions are saved through server restart
-- bells ring every hour
-- they ring as many times as a bell ought to

bell = {};

bell.RING_INTERVAL = 3600; --60*60; -- ring each hour

bell.BELL_SAVE_FILE = minetest.get_worldpath().."/bell_positions.data";

local bell_positions = {};


bell.save_bell_positions = function( player )
  
   str = minetest.serialize( ({ bell_data = bell_positions}) );

   local file, err = io.open( bell.BELL_SAVE_FILE, "wb");
   if (err ~= nil) then
      if( player ) then
         minetest.chat_send_player(player:get_player_name(), "Error: Could not save bell data");
      end
      return
   end
   file:write( str );
   file:flush();
   file:close();
   --minetest.chat_send_all("Wrote data to savefile "..tostring( bell.BELL_SAVE_FILE ));
end


bell.restore_bell_data = function()

   local bell_position_table;

   local file, err = io.open(bell.BELL_SAVE_FILE, "rb");
   if (err ~= nil) then
      print("Error: Could not open bell data savefile (ignore this message on first start)");
      return
   end
   local str = file:read();
   file:close();
   
   local bell_positions_table = minetest.deserialize( str );
   if( bell_positions_table and bell_positions_table.bell_data ) then
     bell_positions = bell_positions_table.bell_data;
     print("[bell] Read positions of bells from savefile.");
   end
end
   

-- actually ring the bell
bell.ring_bell_once = function()

   for i,v in ipairs( bell_positions ) do
-- print("Ringing bell at "..tostring( minetest.pos_to_string( v )));
      minetest.sound_play( "bell_bell",
        { pos = v, gain = 1.5, max_hear_distance = 300,});
   end
end



bell.ring_bell = function()

   -- figure out if this is the right time to ring
   local sekunde = tonumber( os.date( "%S"));
   local minute  = tonumber( os.date( "%M"));
   local stunde  = tonumber( os.date( "%I")); -- in 12h-format (a bell that rings 24x at once would not survive long...)
   local delay   = bell.RING_INTERVAL;
 
   --print("[bells]It is now H:"..tostring( stunde ).." M:"..tostring(minute).." S:"..tostring( sekunde ));

   --local datum = os.date( "Stunde:%l Minute:%M Sekunde:%S");
   --print('[bells] ringing bells at '..tostring( datum ))

   delay = bell.RING_INTERVAL - sekunde - (minute*60);

   -- make sure the bell rings the next hour
   minetest.after( delay, bell.ring_bell );

   -- if no bells are around then don't ring
   if( bell_positions == nil or #bell_positions < 1 ) then
      return;
   end

   if( sekunde > 10 ) then
--      print("[bells] Too late. Waiting for "..tostring( delay ).." seconds.");
      return;
   end

   -- ring the bell for each hour once
   for i=1,stunde do
     minetest.after( (i-1)*5,  bell.ring_bell_once );
   end

end

-- first call (after the server has been started)
minetest.after( 10, bell.ring_bell );
-- read data about bell positions
bell.restore_bell_data();


minetest.register_node("bell:bell", {
    description = "bell",
    node_placement_prediction = "",
	tiles = {"bell_bell.png"},
	paramtype = "light",
	is_ground_content = true,
    inventory_image = 'bell_bell.png',
    wield_image = 'bell_bell.png',
    stack_max = 1,
	drawtype = "plantlike",
    on_punch = function (pos,node,puncher)
        minetest.sound_play( "bell_bell",
           { pos = pos, gain = 1.5, max_hear_distance = 300,});
	minetest.chat_send_all(puncher:get_player_name().." has rung the bell!")
	end,

    after_place_node = function(pos, placer)
       if( placer ~= nil ) then
          minetest.chat_send_all(placer:get_player_name().." has placed a new bell at "..tostring( minetest.pos_to_string( pos )));
       end
       -- remember that there is a bell at that position
       table.insert( bell_positions, pos );
       bell.save_bell_positions( placer );
    end,

    after_dig_node = function(pos, oldnode, oldmetadata, digger)
       if( digger ~= nil ) then
          minetest.chat_send_all(digger:get_player_name().." has removed the bell at "..tostring( minetest.pos_to_string( pos )));
       end

       local found = 0;
       -- actually remove the bell from the list
       for i,v in ipairs( bell_positions ) do
          if( v ~= nil and v.x == pos.x and v.y == pos.y and v.z == pos.z ) then
             found = i;
          end
       end
       -- actually remove the bell
       if( found > 0 ) then
          table.remove( bell_positions, found );
          bell.save_bell_positions( digger );
       end
    end,
 
    groups = {cracky=2},
})


minetest.register_node("bell:bell_small", {
    description = "small bell",
    node_placement_prediction = "",
	tiles = {"bell_bell.png"},
	paramtype = "light",
	is_ground_content = true,
    inventory_image = 'bell_bell.png',
    wield_image = 'bell_bell.png',
    stack_max = 1,
	drawtype = "plantlike",
    on_punch = function (pos,node,puncher)
        minetest.sound_play( "bell_small",
           { pos = pos, gain = 1.5, max_hear_distance = 60,});
	end,
    groups = {cracky=2},
})


minetest.register_craft({
	output = "bell:bell_small",
	recipe = {
		{"",                  "default:goldblock", ""                 },
		{"default:goldblock", "default:goldblock", "default:goldblock"},
		{"default:goldblock", "",                  "default:goldblock"},
	},
})
