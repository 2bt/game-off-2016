-- vim: set tabstop=4 shiftwidth=4 noexpandtab

local json = require("dkjson")

-- wall userdata for fixture
local wallUserData = {
	type = "wall"
}


TILE_SIZE = 16

Map = Object:new()
function Map:init()
	self.img_tileset = G.newImage("data/tileset.png")
	self.quads = makeQuads(self.img_tileset:getWidth(), self.img_tileset:getHeight(), TILE_SIZE)

	self.player = Player()
	self.layers = {}
	self.body_static = P.newBody( world, 0, 0 )
	self.items = {}
	self.terminals = {}
	self.doors = {}
    self.objects = {}
	self.px = 0
	self.py = 0
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
			self.layers[ layer.name ] = layer.data


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
					terminal:setActive(
							obj.x + obj.width / 2,
							obj.y + obj.height / 2,
							obj.width,
							obj.height,
							obj.properties.controlID)
					table.insert(self.terminals, terminal)
				end
			end

		elseif layer.name == "doors" then
			for _, obj in ipairs(layer.objects) do
				if obj.name == "door" then
					local door = Door()
					door:setActive(
							obj.x + obj.width / 2,
							obj.y + obj.height / 2,
							obj.width,
							obj.height,
							obj.properties.id,
							obj.properties.state,
							obj.properties.dx,
							obj.properties.dy)
					table.insert(self.doors, door)
				end
			end


		elseif layer.name == "physics_walls" then
			for _, obj in ipairs(layer.objects) do

				if obj.polygon then
					local points = {}
					for _, point in ipairs(obj.polygon) do
						table.insert( points, point.x + obj.x )
						table.insert( points, point.y + obj.y )
					end
					local shape	 = P.newPolygonShape( points )
					local fixture = P.newFixture( self.body_static, shape )
					fixture:setUserData( wallUserData )

				else -- rectangle
					local shape = P.newRectangleShape(
							obj.x + obj.width/2,
							obj.y + obj.height/2,
							obj.width,
							obj.height,
							obj.rotation )
					local fixture = P.newFixture( self.body_static, shape )
					fixture:setUserData( wallUserData )

				end
			end

		elseif layer.type == "objectgroup" then
			for _, o in ipairs( layer.objects ) do

				-- find constructor of enemy
				local constructor = _G[ o.type ]
				if not constructor then
					print("WOOOT! There's no " .. o.type)
				else
					constructor( o )
				end
			end
		end

	end

end


function Map:restart()
	self.player = {}
	self.layers = {}
	self.body_static ={}
	self.items = {}
	self.terminals = {}
	self.doors = {}
    self.objects = {}
    loadWorld()
end


Dummy = Object:new()
function Dummy:init( obj )
	print( "Dummy:init" )
end


function Map:draw( layername )


	-- draw only tiles in view (and view is something too simple)
	local min_x = math.floor(camera.x / TILE_SIZE) - 11
	local max_x = math.floor(camera.x / TILE_SIZE) + 10
	local min_y = math.floor(camera.y / TILE_SIZE) - 8
	local max_y = math.floor(camera.y / TILE_SIZE) + 7

	G.setColor(255, 255, 255)

	local layer = self.layers[ layername ]
	for iy = min_y, max_y do
		for ix = min_x, max_x do

			local tileid = layer[ iy * self.w + ix + 1 ]
			if tileid and tileid > 0 then
				G.draw( self.img_tileset,
						self.quads[ tileid ],
						ix * TILE_SIZE,
						iy * TILE_SIZE )
			end
		end
	end

end

function Map:removeItem(item)
	for i, it in pairs(self.items) do
		if it == item then
			it.fixture:destroy()
			it.static:destroy()
			table.remove(self.items, i)
			return
		end
	end
end
