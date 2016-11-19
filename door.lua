Door = Object:new()
function Door:init()
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    self.state = ""
    self.dx = 0
    self.dy = 0

    self.time = 0
    self.anim = false
    self.anim_x1 = 0
    self.anim_y1 = 0
    self.anim_x2 = 0
    self.anim_y2 = 0
    self.anim_start = 0
    self.anim_dur = 1
end

function Door:setActive(x,y,w,h, id, state,dx, dy)
    self.x = x
    self.y = y
    self.width = w
    self.height = h
    self.id = id
    self.state = state
    self.dx = dx
    self.dy = dy
    self.static = P.newBody(world, x,y, "static")
    self.shape = P.newRectangleShape(w, h)
    self.fixture = P.newFixture(self.static, self.shape)
    self.fixture:setUserData( "door" )
end

function Door:draw()
    G.setColor(0, 255, 0)
    G.rectangle("fill", self.x - self.width / 2, self.y - self.height / 2, self.width, self.height) 
    G.setColor(255, 255, 255)
end

function Door:update()
  self.time = self.time + 0.016

  if self.anim then
    local t = ( self.time - self.anim_start ) / self.anim_dur
    if t > 1 then
      t = 1
      self.anim = false
    end
    local x = self.anim_x1 * (1 - t) + self.anim_x2 * t
    local y = self.anim_y1 * (1 - t) + self.anim_y2 * t
    self.static:setPosition(x, y)
    self.x = x
    self.y = y
  end
end

function Door:changeState()
    if self.anim then
      return
    end
    if self.state == "closed" then
        self.state = "open"
        self.anim_x1 = self.x
        self.anim_y1 = self.y
        self.anim_x2 = self.anim_x1 + self.dx
        self.anim_y2 = self.anim_y1 + self.dy
        self.anim_start = self.time
        self.anim_dur = 1
        self.anim    = true
    elseif self.state == "open" then
        self.state = "closed"
        self.anim_x1 = self.x
        self.anim_y1 = self.y
        self.anim_x2 = self.anim_x2 - self.dx
        self.anim_y2 = self.anim_y2 - self.dy
        self.anim_start = self.time
        self.anim_dur = 1 
        self.anim    = true
    end
    print("door state: ", self.state)
end
