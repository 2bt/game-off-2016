Terminal = Object:new()
function Terminal:init()
    self.x = 0
    self.y = 0
end

function Terminal:setActive(x,y)
    self.x = x
    self.y = y
    local static = P.newBody(world, x,y, "static")
    local shape = P.newRectangleShape(16, 16)
    self.fixture = P.newFixture(static, shape)
    self.fixture:setCategory(3)
    self.static = static
end

function Terminal:draw()
    G.setColor(0, 0, 255)
    G.rectangle("fill", self.x - 8, self.y - 8, 16, 16) 
    G.setColor(255, 255, 255)
    if self.playerAtTerminal == 1 then
        G.print("Press E to hack the terminal", self.x - 50, self.y -30)
    end
end

function Terminal:setPlayerAtTerminal(atTerminal)
    self.playerAtTerminal = atTerminal
end
