
isDown = love.keyboard.isDown

local dude_img = G.newImage("data/dude.png")
local q   = makeQuads( dude_img:getWidth(), dude_img:getHeight(), 16)
local dude_quads = {
	q[1], q[2], q[1], q[3], -- idle, walk...
	q[4], q[5] -- hack
}

Player = Object:new {
	type = "player"
}
function Player:init()
	self.timer = 0
	self.frame = 1
	self.ang = 0

	local body    = P.newBody( world, 0, 0, "dynamic" )
	local radius  = 6
	local shape   = P.newCircleShape( 0, 0, radius )
	local fixture = P.newFixture( body, shape )
	body:setFixedRotation( true )
	--body:setMass( 1 ) -- not necessary right now
	fixture:setUserData(self)
	self.body     = body
	self.fixture  = fixture
    self.isDead   = false
    self.isControlling = false

	self.terminal = nil
	self.hacking_progress = 0
end

function Player:setPos( x, y )
	self.body:setX( x )
	self.body:setY( y )
end

function Player:pos()
	return self.body:getX(), self.body:getY()
end

function Player:kill()
    self.fixture:setSensor(true)
    self.body:setLinearVelocity(0,0)
    self.isDead = true
end


function Player:update()
	-- need to split entity physics update from entity logic update
	-- this is the input table
	-- let's not use isDown nowhere else

	if self.isDead then return end

	local input = {
		ix   = bool[isDown("right", "d")] - bool[isDown("left", "a")],
		iy   = bool[isDown("down", "s")] - bool[isDown("up", "w")],
		hack = isDown("space", "e"),
		run  = isDown("lshift", "rshift"),
	}

    if self.controllingUnit then
		-- TODO
--        self.controllingUnit:control(input)
		input = {
			ix = 0,
			iy = 0,
			run = false,
			hack = false
		}
    end


	local ix = 0
	local iy = 0


	if input.hack then

		if not self.terminal and not self.old_hack then
			-- find touching terminal
			for _, contact in pairs(self.fixture:getBody():getContactList()) do
				for _, f in ipairs({ contact:getFixtures() }) do
					local obj = f:getUserData()
					if obj.type == "terminal" then
						self.terminal = obj

						local cx, cy = contact:getPositions() -- ignore the 2nd point
						if cx then
							local px, py = self:pos()
							self.ang = math.atan2(cx - px, py - cy)
						end

						break
					end
					if self.terminal then break end
				end
			end
		end


		if self.terminal and self.old_hack then
			-- TODO: progress bar
			self.hacking_progress = self.hacking_progress + 1
			if self.hacking_progress > 50 then
				self.hacking_progress = 0

				-- FIXME: move this into the terminal
				input.hack = false
				for _, d in pairs(map.doors) do
					if self.terminal.controlID == d.id then
						d:changeState()
					end
				end
				for _, o in pairs(map.objects) do
					if self.terminal.controlID == o.id then
						-- TODO: take over robot
						self.controllingUnit = o
						o.isBeingControlled = true
						camera:setNextTarget(o)
						break
					end
				end

			end
		end

	else
		self.terminal = nil

		ix = input.ix * (1 + bool[ input.run ] * 0.5)
		iy = input.iy * (1 + bool[ input.run ] * 0.5)
	end


	self.old_hack = input.hack

	local v_max       = 85
	local accel_max   = 8.5
	local diagonal    = 1 / math.sqrt(2)
	-- local diagonal    = 1 -- for double speed on diagonal movement
	if ix ~= 0 and iy ~= 0 then
		v_max           = diagonal * v_max
		accel_max       = diagonal * accel_max
	end
	local vx, vy      = self.body:getLinearVelocity()
	local accel_x     = clamp( ix * v_max - vx , -accel_max, accel_max )
	local accel_y     = clamp( iy * v_max - vy , -accel_max, accel_max )
	local mass        = self.body:getMass()
	self.body:applyLinearImpulse( accel_x * mass, accel_y * mass )


	-- find the right angle
	if vx^2 + vy^2 > 1.5 then
		self.ang = math.atan2(vx, -vy)
	elseif ix^2 + iy^2 > 0 then
		self.ang = math.atan2(ix, -iy)
	end


	self.timer = self.timer + 0.016

	-- animation

	if ix ~= 0 or iy ~= 0 then
		self.frame = 1 + math.floor( ( self.timer / 0.1 ) % 4 )
	else
		self.frame = 1
	end
	if input.hack then
		self.frame = 5 + math.floor( ( self.timer / 0.1 ) % 2 )
	end

	--if vx ~= 0 or vy ~= 0 or accel_x ~= 0 or accel_y ~= 0 then
	--	print( vx, vy )
	--	print( accel_x, accel_y )
	--	print()
	--end
end


function Player:draw()

	G.push()
	local x, y = self:pos()
	G.translate(x, y)
	G.rotate(self.ang)
	G.setColor( 255, 255, 255 )
	G.draw( dude_img, dude_quads[ self.frame ], -8, -8 )
	--G.setColor( 255, 192, 192 )
	--G.rectangle( "fill", -5, -3, 10, 6 )
	G.pop()

	G.setColor( 255, 255, 255 ) -- reset for others
end

