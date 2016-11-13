Door = Object:new()
function Door:init()
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
end

function Door:setActive(x,y,w,h, id)
    self.x = x
    self.y = y
    self.width = w
    self.height = h
    self.id = id
    local static = P.newBody(world, x,y, "static")
    local shape = P.newRectangleShape(w, h)
    self.fixture = P.newFixture(static, shape)
    self.static = static
end

function Door:draw()
    G.setColor(0, 255, 0)
    G.rectangle("fill", self.x - self.width / 2, self.y - self.height / 2, self.width, self.height) 
    G.setColor(255, 255, 255)
end
