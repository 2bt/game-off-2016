
isDown = love.keyboard.isDown

Player = Object:new()
function Player:init()
	self.x = 0
	self.y = 0
	self.vx = 0
	self.vy = 0
	self.ang = 0
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

end

function Player:draw()


	-- transform rectangle
	G.push()
	G.translate(self.x, self.y)
	G.rotate(self.ang)
	G.rectangle( "fill", -5, -3, 10, 6 )
	G.pop()
end
