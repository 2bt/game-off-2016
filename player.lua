
isDown = love.keyboard.isDown

Player = Object:new()
function Player:init()
	self.x = 0
	self.y = 0
	self.vx = 0
	self.vy = 0
	self.ang = 0

	local body		= P.newBody( world, 0, 0, "dynamic" )
	body:setFixedRotation( true )
	local radius	= 6
	local shape		= P.newCircleShape( 0, 0, radius )
	local density = 1
	local fixture = P.newFixture( body, shape, density )
	self.body			= body
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

	local ix = bool[isDown("right")] - bool[isDown("left")]
	local iy = bool[isDown("down")] - bool[isDown("up")]

	local accel = 0.1

	self.vx = self.vx + ix * accel
	self.vy = self.vy + iy * accel

	if ix == 0 then
		if self.vx > 0 then
			self.vx = math.max(0, self.vx - accel)
		elseif self.vx < 0 then
			self.vx = math.min(0, self.vx + accel)
		end
	end
	if iy == 0 then
		if self.vy > 0 then
			self.vy = math.max(0, self.vy - accel)
		elseif self.vy < 0 then
			self.vy = math.min(0, self.vy + accel)
		end
	end

	-- limit speed
	local speed = 1
	self.vx = clamp(self.vx, -speed, speed)
	self.vy = clamp(self.vy, -speed, speed)


	self.x = self.x + self.vx
	self.y = self.y + self.vy

	if self.vx ~= 0 or self.vy ~= 0 then
		self.ang = math.atan2(self.vx, -self.vy)
	end

	local body = self.body
	body:applyLinearImpulse( ix * 2.3, iy * 2.3 )
	local vx, vy = body:getLinearVelocity()
	local speed = 60
	vx = clamp(vx, -speed, speed)
	vy = clamp(vy, -speed, speed)
	if ix == 0 then
		vx = vx * 0.8
	end
	if iy == 0 then
		vy = vy * 0.8
	end
	body:setLinearVelocity( vx, vy )

	-- she will glide to the side with this code
	--[[
	if ix ~= 0 or iy ~= 0 then
		body:setLinearDamping( 0 )
	else
		body:setLinearDamping( 15 )
	end
	]]--
end

function Player:draw()


	-- transform rectangle
	G.push()
	G.translate(self.x, self.y)
	G.rotate(self.ang)
	G.setColor( 255, 255, 255 )
	G.rectangle( "fill", -5, -3, 10, 6 )
	G.pop()

	G.push()
	local x, y = self:pos()
	G.translate(x, y)
	G.rotate(self.ang)
	G.setColor( 255, 192, 192 )
	G.rectangle( "fill", -5, -3, 10, 6 )
	G.pop()

	G.setColor( 255, 255, 255 ) -- reset for others
end
