G = love.graphics
P = love.physics

print( "# game-off-2016" )
print( "#" )
print( "# hit F2 for draw_debug_physics" )
print( "# hit F3 for draw_debug_ai" )
print()

-- init technical stuff
W = 320
H = 200
G.setDefaultFilter("nearest", "nearest")
canvas = G.newCanvas(W, H)
love.window.setMode(W * 2, H * 2, {resizable = true})
love.mouse.setVisible(false)

lastMap = "data/map.json"

require("helper")
require("enemies")
require("map")
require("player")
require("item")
require("terminal")
require("door")


shadow = {
	canvas = G.newCanvas(W, H),
	shader = G.newShader([[
	vec4 effect( vec4 color, sampler2D tex, vec2 tex_coords, vec2 screen_coords ) {
		return vec4(1.0, 1.0, 1.0, texture2D(tex, tex_coords).a);
	}
	]])
}
function shadow:draw()
	local c = G.getCanvas()
	G.setCanvas( self.canvas )
	G.clear()
	G.setShader( self.shader )
	G.push()
	G.translate(3, 3)

	-- draw everything that casts a shadow
	drawList(map.doors)
	drawList(map.terminals)
	drawList(map.items)
	drawList(map.objects)
	map.player:draw()
	map:draw("walls")


	G.pop()
	G.setShader()
	G.setCanvas(c)

	G.push()
	G.origin()
	G.setColor(0, 0, 0, 100)
	G.draw(self.canvas)
	G.pop()
end




Camera = Object:new()
function Camera:init(trg)
	self.target = trg
end
function Camera:setNextTarget(trg)
	self.nextTarget = trg
	self.tick = 0
end
function Camera:update()
	local x, y = self.target:pos()

	if self.nextTarget then
		local i = self.tick / 30
		local x2, y2 = self.nextTarget:pos()
		x = x * (1 - i) + x2 * i
		y = y * (1 - i) + y2 * i
		self.tick = self.tick + 1
		if self.tick >= 30 then
			self.target = self.nextTarget
			self.nextTarget = nil
		end
	end
	self.x = x
	self.y = y
end





function love.load()
	loadWorld()
end

function loadWorld()
	world = P.newWorld()
	world:setCallbacks(beginContact, endContact, preSolve, postSolve)
	map = Map()
	map:load_json_map( lastMap )
	camera = Camera(map.player)
end


function beginContact(a, b, coll)
	for i = 1, 2 do
		local o1 = a:getUserData()
		local o2 = b:getUserData()

		if o1.type == "item" and o2.type == "player" then -- item picked up
			map:removeItem(o1)
		elseif o1.type == "enemy" and o2.type == "player" then
			map.player:kill()
		end
		a, b = b, a 	-- try the other direction
	end
end

function endContact(a, b, coll)
	for i = 1, 2 do
		-- ...
		a, b = b, a		-- try the other direction
	end
end

function preSolve(a, b, coll)
end

function postSolve(a, b, coll, normalimpulse, tangentimpulse)
end


function love.update(dt)

	-- need to split entity physics update from entity logic update

    if map.player.isDead == true then
        if isDown("return", "kpenter") then
            map:restart()
        end
    end

	map.player:update()

	for _, o in ipairs( map.objects ) do
		o:update()
	end

	for _, door in ipairs(map.doors) do
		door:update()
	end


	world:update( 1 / 60 )

	camera:update()

end


function love.draw()
	G.setCanvas(canvas)
	G.clear(0, 0, 0)

	-- render stuff

	G.translate( W / 2, H / 2 )
	G.translate( math.floor(-camera.x + 0.5), math.floor(-camera.y + 0.5) )

    -- draw stuff
	map:draw("floor")
	shadow:draw()

	drawList(map.doors)
	drawList(map.terminals)
	drawList(map.items)
	map.player:draw()
	drawList(map.objects)
	map:draw("walls")

    if map.player.isDead == true then
		G.setNewFont(30)
		G.setColor(255,10,50)
		G.print("YOU ARE DEAD !!!", map.player.body:getX() -125, map.player.body:getY())
		G.setNewFont()
		G.print("Press ENTER to respawn ...", map.player.body:getX() -60, map.player.body:getY()+40)
    end

	if isDown("f2") then
		draw_debug_physics()
	end


	-- draw canvas independent of resolution
	local w = G.getWidth()
	local h = G.getHeight()
	G.origin()
	if w / h < W / H then
		G.translate(0, (h - w / W * H) * 0.5)
		G.scale(w / W, w / W)
	else
		G.translate((w - h / H * W) * 0.5, 0)
		G.scale(h / H, h / H)
	end
	G.setCanvas()
	if map.player.isDead == false then
	    G.setColor(255, 255, 255)
	end
	G.draw(canvas)
end

function draw_debug_physics()
	G.push()

	local bodies = world:getBodyList()
	for i, body in pairs(bodies) do
		local bx = body:getX()
		local by = body:getY()
		local bangle = body:getAngle()
		local fixtures = body:getFixtureList()

		G.setColor( 255, 192, 192 )
		G.circle( 'fill', bx, by, 3, 6 )
		G.line( bx, by, bx + 8 * math.cos(bangle), by + 8 * math.sin(bangle) )
		G.setColor( 255, 64, 64 )

		for j, fixture in pairs(fixtures) do
			local shape = fixture:getShape()
			local shape_type = shape:getType()

			if shape_type == 'circle' then
				local sx, sy = shape:getPoint()
				local r = shape:getRadius()
				G.circle( 'line', bx + sx, by + sy, r, 10 )

			elseif shape_type == 'chain' then
				G.line( shape:getPoints() )

			elseif shape_type == 'polygon' then
				G.polygon( 'line', shape:getPoints() )

			else
				-- todo
			end
		end
	end

	G.setColor( 255, 255, 255 ) -- reset color for others
	G.pop()
end
