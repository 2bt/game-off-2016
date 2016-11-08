
isDown = love.keyboard.isDown

Player = Object:new()
function Player:init()
  self.x = 0
  self.y = 0
  self.vx = 0
  self.vy = 0
end

function Player:update()
  local s = 4
  self.vx = clamp( self.vx + bool[isDown("right")] - bool[isDown("left")], -s, s )
  self.vy = clamp( self.vy + bool[isDown("down")] - bool[isDown("up")], -s, s )
  if self.vx > 0 then
    self.vx = math.max(0, self.vx - 0.5)
  elseif self.vx < 0 then
    self.vx = math.min(0, self.vx + 0.5)
  end
  if self.vy > 0 then
    self.vy = math.max(0, self.vy - 0.5)
  elseif self.vy < 0 then
    self.vy = math.min(0, self.vy + 0.5)
  end
  self.x = self.x + self.vx
  self.y = self.y + self.vy
end

function Player:draw()
  G.circle( "fill", self.x, self.y, 10 )
end
