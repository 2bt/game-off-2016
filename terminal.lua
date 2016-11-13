Terminal = Object:new()
function Terminal:init()
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
end

function Terminal:setActive(x,y,w,h,controlID)
    self.x = x
    self.y = y
    self.width = w
    self.height = h
    self.controlID = controlID
    local static = P.newBody(world, x,y, "static")
    local shape = P.newRectangleShape(w, h)
    self.fixture = P.newFixture(static, shape)
    self.fixture:setCategory(3)
    self.static = static
end

function Terminal:draw()
    G.setColor(0, 0, 255)
    G.rectangle("fill", self.x - self.width / 2, self.y - self.height / 2, self.width, self.height) 
    G.setColor(255, 255, 255)
    if self.playerAtTerminal == 1 then
        G.print("Press E to hack the terminal", self.x - 50, self.y -30)
    end
end

function Terminal:setPlayerAtTerminal(atTerminal)
    self.playerAtTerminal = atTerminal
end
