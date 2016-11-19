Terminal = Object:new {
	type = "terminal",
	img  = G.newImage("data/terminal.png"),
	anim = { 1, 2, 1, 2, 1, 2, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 10, 11, 10, 11, 10, 11, 10, 11 }
}
Terminal.quads = makeQuads( Terminal.img:getWidth(), Terminal.img:getHeight(), 16)
function Terminal:init()
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
	-- TODO: resolve id during map construction
	self.target = nil
	self.tick = 0
end

function Terminal:update()
	self.tick = self.tick + 1
end

function Terminal:setActive(x, y, w, h, controlID)
    self.x = x
    self.y = y
    self.width = w
    self.height = h
    self.controlID = controlID
    local static = P.newBody(world, x,y, "static")
    local shape = P.newRectangleShape(w, h)
    self.fixture = P.newFixture(static, shape)
    self.fixture:setUserData(self)
    self.static = static
end



-- TODO: make this interface work
function Terminal:hack()
	self.progress = self.progress + 1
	if self.progress > 40 then
		-- ...
	end

end


function Terminal:draw()
    G.setColor(0, 0, 255)
    G.rectangle("fill", self.x - self.width / 2, self.y - self.height / 2, self.width, self.height)
    G.setColor(255, 255, 255)

	local frame = self.anim[ math.floor(self.tick * 0.1) % #self.anim + 1 ]
	G.draw(self.img, self.quads[ frame ], self.x, self.y, 0, 1, 1, 8, 8)
end
