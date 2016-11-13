G = love.graphics
P = love.physics

print( "# game-off-2016" )
print( "#" )
print( "# hit F2 for draw_debug_physics" )
print()

-- init technical stuff
W = 320
H = 200
G.setDefaultFilter("nearest", "nearest")
canvas = G.newCanvas(W, H)
love.window.setMode(W * 2, H * 2, {resizable = true})
love.mouse.setVisible(false)

require("helper")
require("map")
require("player")
require("item")
require("terminal")
require("door")

function love.load()
    world = P.newWorld()
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)
    map = Map()
end

function beginContact(a, b, coll)
    -- a
    if (a:getCategory() == 2) then -- item picked up
        map:pickupItem(a)
    elseif (a:getCategory() == 3) then -- terminal entered
        map:playerAtTerminal(a, 1)
    end
    -- b
    if (b:getCategory() == 2) then -- item picked up
        map:pickupItem(b)
    elseif (b:getCategory() == 3) then -- terminal entered
        map:playerAtTerminal(b, 1)
    end
end
 
function endContact(a, b, coll)
    -- a
    if (a:getCategory() == 3) then -- terminal left
        map:playerAtTerminal(a, 0)
    end
    -- b
    if (b:getCategory() == 3) then -- terminal left
        map:playerAtTerminal(b, 0)
    end
end
 
function preSolve(a, b, coll)
end
 
function postSolve(a, b, coll, normalimpulse, tangentimpulse)
end


function love.update(dt)

	-- need to split entity physics update from entity logic update
	map.player:update()

	for i, door in ipairs(map.doors) do
		door:update()
	end

	world:update( 1 / 60 )
    -- check terminals for hacking
	map:checkTerminals()

end

t = 0

function love.draw()
	G.setCanvas(canvas)
	G.clear(0, 0, 0)

	-- render stuff
	t = t + 1
	local p = map.player
	local px, py = p:pos()

	G.translate( W / 2, H / 2 )
	G.translate( math.floor(-px + 0.5), math.floor(-py + 0.5) )
    
    -- draw stuff
	map:draw("floor")
	p:draw()
	map:draw("walls")
	map:drawItems()
	map:drawTerminals()
	map:drawDoors()

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
