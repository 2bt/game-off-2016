Object = {}
function Object:new(o)
	o = o or {}
	setmetatable(o, self)
	local m = getmetatable(self)
	self.__index = self
	self.__call = m.__call
	self.super = m.__index and m.__index.init
	return o
end
setmetatable(Object, { __call = function(self, ...)
	local o = self:new()
	if o.init then o:init(...) end
	return o
end })


bool = { [true] = 1, [false] = 0 }


function clamp(x, a, b)
	return math.max(a, math.min(x, b))
end



function makeQuads(w, h, s)
	local quads = {}
	for y = 0, h - s, s do
		for x = 0, w - s, s do
			table.insert(quads, love.graphics.newQuad(x, y, s, s, w, h))
		end
	end
	return quads
end


function collision(a, b, axis)
	if a.x >= b.x + b.w
	or a.y >= b.y + b.h
	or a.x + a.w <= b.x
	or a.y + a.h <= b.y then
		return 0
	end

	local dx = b.x + b.w - a.x
	local dx2 = b.x - a.x - a.w

	local dy = b.y + b.h - a.y
	local dy2 = b.y - a.y - a.h

	if axis == "x" then
		return math.abs(dx) < math.abs(dx2) and dx or dx2
	else
		return math.abs(dy) < math.abs(dy2) and dy or dy2
	end
end

local function defaultFilterPredicate(item)
	return not item.alive
end

function updateList(x, removalPredicate)
	removalPredicate = removalPredicate or defaultFilterPredicate
	local i = 1
	for _, b in ipairs(x) do
		b:update()
	end
	for j, b in ipairs(x) do
		x[j] = nil
		if not removalPredicate(b) then
			x[i] = b
			i = i + 1
		end
	end
end


function rayBoxIntersection(ox, oy, dx, dy, box)

	if dx > 0 and ox <= box.x then
		local f = (box.x - ox) / dx
		local y = oy + dy * f
		if box.y <= y and y <= box.y + box.h then
			return f
		end
	elseif dx < 0 and ox >= box.x + box.w then
		local f = (box.x + box.w - ox) / dx
		local y = oy + dy * f
		if box.y <= y and y <= box.y + box.h then
			return f
		end
	end

	if dy > 0 and oy <= box.y then
		local f = (box.y - oy) / dy
		local x = ox + dx * f
		if box.x <= x and x <= box.x + box.w then
			return f
		end
	elseif dy < 0 and oy >= box.y + box.h then
		local f = (box.y + box.h - oy) / dy
		local x = ox + dx * f
		if box.x <= x and x <= box.x + box.w then
			return f
		end
	end

	return false
end


function drawList(list)
	for _, o in ipairs(list) do o:draw() end
end



V = Object:new()
function V:init( x, y )
	self.x = x or 0
	self.y = y or 0
end

function V:__tostring()
	return "V("..tostring(self.x)..", "..tostring(self.y)..")"
end
function V:__concat(other)
	return other..tostring(self)
end

function V:__add(other)
	return V( self.x + other.x, self.y + other.y )
end

function V:add(other)
	self.x = self.x + other.x
	self.y = self.y + other.y
end

function V:__sub(other)
	return V( self.x - other.x, self.y - other.y )
end

function V:sub(other)
	self.x = self.x - other.x
	self.y = self.y - other.y
end

function V:__mul(other)
	return V( self.x * other, self.y * other )
end

function V:mul(other)
	self.x = self.x * other
	self.y = self.y * other
end

function V:__div(other)
	return V( self.x / other, self.y / other )
end

function V:__unm()
	return V( -self.x, -self.y )
end

function V:__pow(other)
	return V( self.x ^ other, self.y ^ other )
end

function V:__eq(other)
	return self.x == other.x and self.y == other.y
end

function V:__lt(other)
	return self:length2() < other:length2()
end

function V:__le(other)
	local a = self:length2()
	local b = other:length2()
	return a < b or a == b
end

function V:length2()
	return self.x^2 + self.y^2
end

function V:length()
	return math.sqrt(self.x^2 + self.y^2)
end

function V:angle()
	return math.atan2(self.x, self.y)
end

function V:distance2(other)
	return (other.x-self.x)^2+(other.y-self.y)^2
end

function V:distance(other)
	return math.sqrt((other.x-self.x)^2+(other.y-self.y)^2)
end

function V:copy()
	return V( self.x, self.y )
end

function V:norm()
	local l = self:length()
	self.x = self.x / l
	self.y = self.y / l
end
