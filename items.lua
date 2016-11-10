Item = Object:new()
function Item:init()
    self.x = 0
    self.y = 0
end

function Item:setActive( x, y )
    self.x = x
    self.y = y
end

function Item:draw()
    G.setColor(255, 0, 0)
    G.rectangle("fill", self.x, self.y, 16, 16) 
    G.setColor(255, 255, 255)
end
