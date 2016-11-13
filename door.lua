Door = Object:new()
function Door:init()
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    self.state = ""
    self.dx = 0
    self.dy = 0
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
end

function Door:draw()
    G.setColor(0, 255, 0)
    G.rectangle("fill", self.x - self.width / 2, self.y - self.height / 2, self.width, self.height) 
    G.setColor(255, 255, 255)
end

function Door:changeState()
    if self.state == "closed" then
        self.x = self.x + self.dx
        self.y = self.y + self.dy
        self.fixture:destroy()
        self.state = "open"
    elseif self.state == "open" then
        self.x = self.x - self.dx
        self.y = self.y - self.dy
        self.fixture = P.newFixture(self.static, self.shape)
        self.state = "closed"
    end
end
