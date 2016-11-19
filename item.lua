Item = Object:new {
	type = "item"
}
function Item:init()
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
end

function Item:setActive( x, y, w ,h )
    self.x = x
    self.y = y
    self.width = w
    self.height = h
    local static = P.newBody(world, x,y, "static")
    local shape = P.newCircleShape(0, 0, 4)
    self.fixture = P.newFixture(static, shape)
    self.fixture:setSensor( true )
    self.fixture:setUserData(self)
    self.static = static
end

function Item:draw()
    G.setColor(255, 0, 0)
    G.circle("fill", self.x, self.y, 6, 6)
    G.setColor(255, 255, 255)
end
