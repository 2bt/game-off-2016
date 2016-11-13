Item = Object:new()
function Item:init()
    self.x = 0
    self.y = 0
end

function Item:setActive( x, y )
    self.x = x
    self.y = y
    local static = P.newBody(world, x,y, "static")
    local shape = P.newCircleShape(0, 0, 4)
    self.fixture = P.newFixture(static, shape)
    self.fixture:setSensor( true )
    self.fixture:setCategory(2)
    self.static = static
end

function Item:draw()
    G.setColor(255, 0, 0)
    G.circle("fill", self.x, self.y, 6, 6) 
    G.setColor(255, 255, 255)
end
