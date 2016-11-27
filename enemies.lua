
StupidEnemy = Object:new {
	type = "enemy"
}

local my_img = G.newImage("data/round-robot.png")
local my_anims = {
	img   = my_img,
	quads = makeQuads( my_img:getWidth(), my_img:getHeight(), 16),
	idle  = { duration = 1,   quads = { 1 } },
	blink = { duration = 0.3, quads = { 2, 3, 4, 5 } },
}


function StupidEnemy:init( obj )
	table.insert( map.objects, self )

	self.name = obj.name

	local body    = P.newBody( world, obj.x, obj.y, "dynamic" )
	local radius  = math.max( 8, math.max( obj.width, obj.height ) )
	local shape   = P.newCircleShape( radius )
	local fixture = P.newFixture( body, shape )
	fixture:setUserData(self)
	body:setMass( 1 )
	body:setLinearDamping( 4, 4 )
	self.body     = body
	self.radius   = radius
    self.id       = obj.properties.id

	self.ai_target = nil
	self.ai_state  = nil
	self.ai_debug  = {}
    self.isBeingControlled = false

	self.anims      = my_anims
	self.anim_timer = 0
	self.anim_name  = "idle"
	self.anim       = self.anims[ self.anim_name ]
	self.anim_quad  = self.anim.quads[1]

	print( "StupidEnemy:init "..tostring(self.name) )
end

function StupidEnemy:update()

	if not self.isBeingControlled then

        if not self.ai_target then
            self:change_ai_state( "find_target" )
            self:update_find_target()
        else
            self:change_ai_state( "play_target" )
            self:update_play_target()
            self:update_find_target()
        end

    else
        -- this is the input table
        -- let's not use isDown nowhere else
        local input = {
            ix     = bool[isDown("right", "d")] - bool[isDown("left", "a")],
            iy     = bool[isDown("down", "s")] - bool[isDown("up", "w")],
            hack   = isDown("space", "e"),
            run    = isDown("lshift", "rshift"),
			escape = isDown("escape")
        }


        local ix = 0
        local iy = 0
        ix = input.ix * (1 + bool[ input.run ] * 0.5)
        iy = input.iy * (1 + bool[ input.run ] * 0.5)

        local v_max       = 85
        local accel_max   = 8.5
        local diagonal    = 1 / math.sqrt(2)
        -- local diagonal    = 1 -- for double speed on diagonal movement
        if ix ~= 0 and iy ~= 0 then
            v_max           = diagonal * v_max
            accel_max       = diagonal * accel_max
        end
        local vx, vy      = self.body:getLinearVelocity()
        local accel_x     = clamp( ix * v_max - vx , -accel_max, accel_max )
        local accel_y     = clamp( iy * v_max - vy , -accel_max, accel_max )
        local mass        = self.body:getMass()
        self.body:applyLinearImpulse( accel_x * mass, accel_y * mass )

        if ( vx ~= 0 or vy ~= 0 ) and ( ix ~= 0 or iy ~= 0 ) then
            self.ang = math.atan2(vx, -vy)
        end

        if input.escape then
            self.isBeingControlled = false
            map.player.controllingUnit = nil
            camera:setNextTarget(map.player)
        end

	end

	self:updateAnim()
end

function StupidEnemy:updateAnim()
	local duration = self.anim.duration
	self.anim_timer = self.anim_timer + 0.01
	if duration ~= 0 and self.anim_timer >= duration then
		self.anim_timer = 0
		if self.anim_name == "idle" then
			if math.random() < 1.5 then
				self:setAnim( "blink" )
			end
		elseif self.anim_name == "blink" then
			self:setAnim( "idle" )
		else
			self:setAnim( "idle" )
		end
	end
	if self.anim.duration == 0 then
		self.anim_quad = self.anim.quads[1]
	else
		self.anim_quad = self.anim.quads[1 + math.floor( self.anim_timer / self.anim.duration * #self.anim.quads )]
	end
end

function StupidEnemy:setAnim( name )
	self.anim_name = name
	self.anim = self.anims[ self.anim_name ]
end

function StupidEnemy:draw()
	local x, y = self.body:getPosition()
	G.setColor( 255, 255, 255 )
	G.draw( self.anims.img, self.anims.quads[ self.anim_quad ], x - self.radius, y - self.radius )
	if isDown( "f3" ) then
	  self:draw_debug_ai()
  end
end



function StupidEnemy:draw_debug_ai()
  G.setColor( 255, 0, 0 )
  for _, stuff in ipairs( self.ai_debug ) do
    local t, x1, y1, x2, y2  = unpack( stuff )
    if t == "dot" then
      G.circle( "fill", x1, y1, 3 )
    elseif t == "line" then
      G.line( x1, y1, x2, y2 )
    end
  end
end

function StupidEnemy:change_ai_state( state )
	if self.ai_state == state then return end
	self.ai_state = state
	if self.name then
		print( self.name.." ai_state: "..tostring( self.ai_state ) )
	end
end

function StupidEnemy:update_find_target()
	self.ai_debug = {}
	local player = map.player
	if not player then return end
	local x1, y1 = self.body:getPosition()
	local x2, y2 = player:pos()

	if isDown( "f3" ) then
		table.insert( self.ai_debug, { "line", x1, y1, x2, y2 } )
	end

	world:rayCast( x1, y1, x2, y2,
		function( fixture, x, y, xn, yn, fraction )
			if isDown( "f3" ) then
				table.insert( self.ai_debug, { "dot", x, y } )
			end

			local obj = fixture:getUserData()
			if obj.type == "wall" or obj.type == "door" then
				self.ai_target = nil
				return 0
			elseif obj.type == "player" then
				if math.abs(x1-x) < 120 and math.abs(y1-y) < 120 then
    				self.ai_target = player
			    	return 1
			    else
			        self.ai_target = nil
			    end
			end
			return 1
		end
	)
end

function StupidEnemy:update_play_target()
	local a = V( self.body:getPosition() )
	local b = V( self.ai_target:pos() )
	local d = b - a
	d:norm()
	d:mul( 4 )
	self.body:applyLinearImpulse( d.x, d.y )
end


function StupidEnemy:pos()
	return self.body:getX(), self.body:getY()
end

