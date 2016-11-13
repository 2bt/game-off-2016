local json = require("dkjson")


Map = Object:new()
function Map:init()

	local raw = love.filesystem.read("data/map.json")
	local data = json.decode(raw)


	self.tileset = G.newImage("data/tileset.png")
	self.quads = makeQuads(self.tileset:getWidth(), self.tileset:getHeight(), 16)
	self.w = data.width
	self.h = data.height


	self.player = Player()
	self.layers = {}
	self.body_static = P.newBody( world, 0, 0 )
	self.items = {}
	self.terminals = {}
	self.doors = {}
	self:objects_init()

	for _, layer in pairs(data.layers) do


		if layer.type == "tilelayer" then

			self.layers[layer.name] = layer.data




		elseif layer.name == "entities" then
			for _, obj in ipairs(layer.objects) do

				if obj.name == "player" then
                    local x = obj.x + obj.width / 2
                    local y = obj.y + obj.height / 2
                    self.player:setPos( x, y )

                elseif obj.name == "item" then
                    local item = Item()
                    item:setActive(obj.x + obj.width / 2, obj.y + obj.height / 2, obj.width, obj.height)
                    table.insert(self.items, item)
				
				elseif obj.name == "terminal" then
				    local terminal = Terminal()
				    terminal:setActive(obj.x + obj.width / 2, obj.y + obj.height / 2, obj.width, obj.height, obj.properties.controlID)
				    table.insert(self.terminals, terminal)
				end

			end

    elseif layer.name == "doors" then
        for _, obj in ipairs(layer.objects) do
            if obj.name == "door" then
                local door = Door()
                door:setActive(obj.x + obj.width / 2, obj.y + obj.height / 2, obj.width, obj.height, obj.properties.id, obj.properties.state, obj.properties.dx, obj.properties.dy)
                table.insert(self.doors, door)
            end
        end


    elseif layer.name == "physics_walls" then
      for _, obj in ipairs(layer.objects) do
        
        if obj.polyline then
          local points = {}
          for _, point in ipairs(obj.polyline) do
            table.insert( points, point.x + obj.x )
            table.insert( points, point.y + obj.y )
          end
          local shape   = P.newChainShape( false, points )
          local fixture = P.newFixture( self.body_static, shape )
          fixture:setUserData( "wall" )

        else -- rectangle
          local shape   = P.newRectangleShape( obj.x + obj.width/2, obj.y + obj.height/2, obj.width, obj.height, obj.rotation )
          local fixture = P.newFixture( self.body_static, shape )
          fixture:setUserData( "wall" )
        
        end
      end

		elseif layer.type == "objectgroup" then
			for _, obj_desc in ipairs( layer.objects ) do
				self:objects_load( obj_desc )
			end
		end

	end

end



function Map:objects_init()
	self.objects = {}
	self.obj_by_name = {}
	self.object_types = {}

	self.object_types[ "dummy" ] = Dummy
	self:objects_register( "stupid_enemy", StupidEnemy )
end

function Map:objects_load( obj_desc )
	local obj_type = self.object_types[ obj_desc.type ]
	if not obj_type then
		print( "objects_load: unkown object type", obj_desc.type )
		return
	end
	local obj = obj_type( obj_desc )
	if not obj then return end
	table.insert( self.objects, obj )
	if obj.name then
		self.obj_by_name[ obj.name ] = obj
	end
end

function Map:objects_register( type_name, constructor )
	if not constructor then
		print( "objects_register: invalid registration of", type_name, "as", constructor )
	end
	self.object_types[ type_name ] = constructor
end

function Map:objects_call( func_name )
	for _, obj in ipairs( self.objects ) do
		if obj[ func_name ] then
			obj[ func_name ]( obj )
		end
	end
end

Dummy = Object:new()
function Dummy:init( obj )
	print( "Dummy:init" )
end




function Map:draw(layername)



	local layer = self.layers[layername or "walls"]
    
    if layername == "walls" then
			G.setColor( 255, 255, 255 )
	    for y = 0, self.h-1 do
		    for x = 0, self.w-1 do

			    local cell = layer[y * self.w + x + 1]
			    if cell > 0 then

				    G.draw(self.tileset, self.quads[cell], x * 16, y * 16)

			    end


		    end
	    end

	-- shadow
	elseif layername == "floor" then

		G.setColor(0, 0, 0, 70)
		local layer = self.layers.walls

		for y = 0, self.h-1 do
			for x = 0, self.w-1 do

				local cell = layer[y * self.w + x + 1]
				if cell > 0 then

					G.rectangle("fill", x * 16 + 3, y * 16 + 3, 16, 16)

				end


			end
		end

		G.setColor(255, 255, 255)
    end
end

function Map:drawItems()
    for _, item in pairs(self.items) do
        item:draw()
    end
end

function Map:drawTerminals()
    for _, terminal in pairs(self.terminals) do
        terminal:draw()
    end
end

function Map:drawDoors()
    for _, door in pairs(self.doors) do
        door:draw()
    end
end

function Map:pickupItem(item)
    for _, i in pairs(self.items) do
        if i.fixture == item then
            i.fixture:destroy()
            i.static:destroy()
            table.remove(self.items, _)
        end
    end
end

function Map:playerAtTerminal(terminal, atTerminal)
    for _, t in pairs(self.terminals) do
        if t.fixture == terminal then
            t:setPlayerAtTerminal(atTerminal)
        end
    end
end

function Map:checkTerminals()
    for _, t in pairs(self.terminals) do

        if t.isUsed == 1 and bool[isDown("e")] == 0 then
            t.isUsed = 0
        end

        if t.playerAtTerminal == 1 and bool[isDown("e")] == 1 and t.isUsed == 0 then
            for _, d in pairs(self.doors) do
                if t.controlID == d.id then
                    d:changeState()
                    t.isUsed = 1
                end
            end
        end
    end
end

    
