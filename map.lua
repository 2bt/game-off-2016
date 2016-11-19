local json = require("dkjson")


Map = Object:new()
function Map:init()
	self.img_tileset = G.newImage("data/tileset.png")
	self.quads = makeQuads(self.img_tileset:getWidth(), self.img_tileset:getHeight(), 16)

	self.player = Player()
	self.layers = {}
	self.body_static = P.newBody( world, 0, 0 )
	self.items = {}
	self.terminals = {}
	self.doors = {}
	self.gfxlayers = {}
	self:objects_init()
end

--[[ map.json
	data
		tilesets
			tiles
				*tileid: { terrain: [ #terrains ] }
			terrains
				name
				tile
				properties
		layers [
			data: [ *tileid ]
]]--

function Map:tileset( tileid )
	return self.data.tilesets[1]
end

function Map:__tile_gfxlayer( tileid )
	local tileset = self:tileset( tileid )
	local tileprops = tileset.tiles[ tostring(tileid-1) ]
	if not tileprops or not tileprops.terrain then return "floor" end
	for _, terrain_i in ipairs( tileprops.terrain ) do
		local terrain = tileset.terrains[ terrain_i+1 ]
		if terrain.properties and terrain.properties.wall then
			return "wall"
		end
	end
	return "floor" -- default case
end

function Map:tile_gfxlayer( tileid )
	local cache = self.tile_gfxlayer_cache
	if not cache then
		cache = {}
		self.tile_gfxlayer_cache = cache
	end
	local gfxlayer = cache[ tileid ]
	if not gfxlayer then
		gfxlayer = self:__tile_gfxlayer( tileid )
		cache[ tileid ] = gfxlayer
	end
	return gfxlayer
end

function Map:load_json_map( path )
	local raw = love.filesystem.read( path )
	local data = json.decode(raw)
	self.data = data
	self.w = data.width
	self.h = data.height

	print("Map:load_json_map", path)

	for _, layer in pairs(data.layers) do

		if layer.type == "tilelayer" then
			for index, tileid in ipairs( layer.data ) do
				local gfxlayer = self:tile_gfxlayer( tileid )
				if not self.gfxlayers[ gfxlayer ] then
					self.gfxlayers[ gfxlayer ] = {}
					print( "gfxlayer", gfxlayer )
				end
				table.insert( self.gfxlayers[ gfxlayer ], { index-1, tileid } )
			end


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
					local shape	 = P.newChainShape( false, points )
					local fixture = P.newFixture( self.body_static, shape )
					fixture:setUserData( "wall" )

				else -- rectangle
					local shape	 = P.newRectangleShape( obj.x + obj.width/2, obj.y + obj.height/2, obj.width, obj.height, obj.rotation )
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



function Map:draw( layername )

	local layer = self.gfxlayers[ layername ]
	local w = self.w
	local h = self.h

	-- draw only tiles in view (and view is something too simple)
	local px, py = self.player:pos()
	local min_x = px - 16*11
	local max_x = px + 16*10
	local min_y = py - 16*8
	local max_y = py + 16*7

	local img_tileset = self.img_tileset
	local quads = self.quads
	G.setColor( 255, 255, 255 )
	for _, tile in ipairs( layer ) do
		local index = tile[ 1 ]
		local tileid = tile[ 2 ]
		local x = index % w * 16
		local y = math.floor( index / w ) * 16
		if tileid > 0 and min_x <= x and x <= max_x and min_y <= y and y <= max_y then
			G.draw( img_tileset, quads[ tileid ], x, y )
		end
		G.setColor( 255, 255, 255 )
	end

	-- shadow
	if layername == "floor" then
		local layer = self.gfxlayers.wall
		local w = self.w
		local h = self.h
		G.setColor(0, 0, 0, 70)
		for _, tile in ipairs( layer ) do
			local index = tile[ 1 ]
			local tileid = tile[ 2 ]
			local x = index % w
			local y = math.floor( index / w )
			if tileid > 0 then
				G.rectangle("fill", x * 16 + 3, y * 16 + 3, 16, 16)
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

function Map:playerDead()
    self.player.fixture:setSensor(true)
    self.player.body:setLinearVelocity(0,0)
    self.player.isDead = true
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

