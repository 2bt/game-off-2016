
isDown = love.keyboard.isDown

Player = Object:new()
function Player:init()
	self.timer = 0
	self.anim_img = 1
	self.ang = 0

	local body    = P.newBody( world, 0, 0, "dynamic" )
	local radius  = 6
	local shape   = P.newCircleShape( 0, 0, radius )
	local fixture = P.newFixture( body, shape )
	body:setFixedRotation( true )
	--body:setMass( 1 ) -- not necessary right now
	fixture:setUserData( "player" )
	self.body     = body

end

function Player:setPos( x, y )
	self.body:setX( x )
	self.body:setY( y )
	self.x = x
	self.y = y
end

function Player:pos()
	return self.body:getX(), self.body:getY()
end

function Player:update()
	-- need to split entity physics update from entity logic update

	local ix = (math.max(bool[isDown("right")], bool[isDown("d")])
	    - math.max(bool[isDown("left")], bool[isDown("a")]) )
	    * (1 + bool[isDown("lshift")]*0.5)
	local iy = (math.max(bool[isDown("down")], bool[isDown("s")])
	    - math.max(bool[isDown("up")], bool[isDown("w")]) )
	    * (1 + bool[isDown("lshift")]*0.5)

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

	if ( vx ~= 0 or vy ~= 0 ) and ( ix ~= 0 or iy ~= 0 ) then
		self.ang = math.atan2(vx, -vy)
	end



	self.timer = self.timer + 0.016



	if ix ~= 0 or iy ~= 0 then
		self.anim_img = 2 + math.floor( ( self.timer / 0.2 ) % 2 )
	else
		self.anim_imt = 1
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
	G.setColor( 255, 192, 192 )
	G.draw( spritesheet, spritequads.dude[ self.anim_img ], -8, -8 )
	G.pop()

	G.setColor( 255, 255, 255 ) -- reset for others
end
