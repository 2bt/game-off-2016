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
	self.entities = {}
	self.layers = {}
  self.body_static = P.newBody( world, 0, 0 )

	for _, layer in pairs(data.layers) do


		if layer.type == "tilelayer" then

			self.layers[layer.name] = layer.data




		elseif layer.name == "entities" then
			for _, obj in ipairs(layer.objects) do

				if obj.name == "player" then
            local x = obj.x + obj.width / 2
            local y = obj.y + obj.height / 2
            self.player:setPos( x, y )
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

        else -- rectangle
          local shape   = P.newRectangleShape( obj.x + obj.width/2, obj.y + obj.height/2, obj.width, obj.height, obj.rotation )
          local fixture = P.newFixture( self.body_static, shape )
        
        end
      end
    end

	end

end
function Map:draw(layername)



	local layer = self.layers[layername or "walls"]

	for y = 0, self.h-1 do
		for x = 0, self.w-1 do

			local cell = layer[y * self.w + x + 1]
			if cell > 0 then

				G.draw(self.tileset, self.quads[cell], x * 16, y * 16)

			end


		end
	end


	-- shadow
	if layername == "floor" then

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
