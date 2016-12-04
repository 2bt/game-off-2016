B = require('behaviourtree')

b_tree = B:new({
	tree = B.Priority:new({
		nodes = { "look_for_player", "hunt", "patrol", "idle" }
	})
})

B.Task:new({
	name   = "look_for_player",
	run    = function( task, self )
		if self.task_hunt_id then
			return task:fail()
		end
		self:setAnim( "idle" )
		self.body:applyTorque( 10 )
		for id, obj in pairs( self.inSight ) do
			if obj.type == "player" then
				self.task_hunt_id = obj.id
				return task:success()
			end
		end
		task:fail()
	end,
})

B.Task:new({
	name   = "hunt",
	run    = function( task, self )
		if not self.task_hunt_id then
			return task:fail()
		end
		local pos = self.lastSeen[ self.task_hunt_id ]
		if pos and self:updateBehaviourMoveTo( unpack(pos) ) then
			self:setAnim( "walk" )
			return task:success()
		else
			self.task_hunt_id = nil
			return task:fail()
		end
	end,
})

B.Task:new({
	name   = "patrol",
	run    = function( task, self )
		if not self.task_patrol_name then
			return task:fail()
		end
		local patrol_path = map.object_by_name[ self.task_patrol_name ] or {}
		local patrol_polyline = patrol_path and patrol_path.polyline
		if not patrol_polyline or not #patrol_polyline then
			self.task_patrol_name = nil
			return task:fail()
		end
		local pt = patrol_polyline[ self.task_patrol_pos ]
		local x = pt.x + patrol_path.x
		local y = pt.y + patrol_path.y
		if self:updateBehaviourMoveTo( x, y ) then
		elseif self.task_patrol_pos < #patrol_polyline then
			self.task_patrol_pos = self.task_patrol_pos + 1
		else
			self.task_patrol_pos = 1
		end
		self:setAnim( "walk" )
		return task:success()
	end,
})

B.Task:new({
	name   = "idle",
	run    = function( task, self )
		task:success()
	end
})



Droid = Object:new {
	type = "enemy"
}

local my_img = G.newImage("data/droid.png")
local my_anims = {
	img   = my_img,
	quads = makeQuads( my_img:getWidth(), my_img:getHeight(), 16),
	idle  = { duration = 1,   quads = { 1 } },
	walk  = { duration = 0.3, quads = { 2, 3, 1, 4, 5, 1 } },
}


function Droid:init( obj )
	table.insert( map.objects, self )

	self.id     = obj.id
	self.name   = obj.name

	self:initBody( obj )
	self:initSight()
	self:initAnim()
  self:initBehaviour( obj )

	print( "Droid:init "..tostring(self.name) )
end

function Droid:initBody( obj )
	-- makes body and collision shape, used in updateBehaviourMoveTo to move towards a target
	local body    = P.newBody( world, obj.x, obj.y, "dynamic" )
	local radius  = math.max( 8, math.max( obj.width, obj.height ) )
	local shape   = P.newCircleShape( radius )
	local fixture = P.newFixture( body, shape )
	fixture:setUserData(self) -- used in main beginContact
	body:setLinearDamping( 4, 4 )
	body:setAngularDamping( 1 )
	--body:setFixedRotation( true )
	body:setMassData( 0, 0, 1, 10 )
	self.body     = body
	self.radius   = radius
end

function Droid:initAnim()
	-- call setAnim to change animation, call updateAnim in update to advance animation
	self.anims      = my_anims
	self.anim_timer = 0
	self.anim_name  = "idle"
	self.anim       = self.anims[ self.anim_name ]
	self.anim_quad  = self.anim.quads[1]
end

function Droid:initSight()
	-- use sensor shapes
	-- call in main beginContact the sightBeginContact method, based on userData of sensor
	-- in sightBeginContact, fill sightMaybe with other object
	-- in updateSight, rayCast every object in sightMaybe and fill inSight if visible
	-- if object inSight and not visible anymore, save in lastSeen
	self.sightMaybe = {}
	self.inSight = {}
	self.lastSeen = {}
	local sightCallback = {
		self = self,
		beginContact = self.sightBeginContact,
		endContact = self.sightEndContact,
	}
	local r        = self.radius
	local aside1   = 1*r
	local aside2   = 8*r
	local forward1 = 10*r
	local aside3   = 2*r
	local forward2 = 15*r
	local shape1  = P.newPolygonShape( 0, -aside1, forward1, -aside2, forward1, aside2, 0, aside1 )
	local sensor1 = P.newFixture( self.body, shape1, 0 )
	sensor1:setSensor( true )
	sensor1:setUserData( sightCallback )
	local shape2  = P.newPolygonShape( 0, -aside1, forward2, -aside3, forward2, aside3, 0, aside1 )
	local sensor2 = P.newFixture( self.body, shape2, 0 )
	sensor2:setSensor( true )
	sensor2:setSensor( sightCallback )
end

function Droid:initBehaviour( obj )
	self.task_hunt_id = nil
	self.task_patrol_pos = 1
  self.task_patrol_name = obj.properties.task_patrol_name

	self.b_tree = b_tree
end



function Droid:update()
	self.ai_debug = {}
	self:updateSight() -- updated self.inSight { id = obj }
	self:updateBehaviour()
	self:updateAnim() -- updated self.anim*
end



function Droid:updateBehaviour()
	b_tree:run( self )
	if self.name and self.actualTask ~= b_tree.rootNode.actualTask then
		self.actualTask = b_tree.rootNode.actualTask
		local node = b_tree.rootNode.nodes[ self.actualTask ]
		print( self.name, node )
	end
end



function Droid:updateAnim()
	local duration = self.anim.duration
	self.anim_timer = self.anim_timer + 0.01
	if duration ~= 0 and self.anim_timer >= duration then
		self.anim_timer = 0
	end
	if self.anim.duration == 0 then
		self.anim_quad = self.anim.quads[1]
	else
		self.anim_quad = self.anim.quads[1 + math.floor( self.anim_timer / self.anim.duration * #self.anim.quads )]
	end
end

function Droid:setAnim( name )
	self.anim_name = name
	self.anim = self.anims[ self.anim_name ]
	if not self.anim then
		print( "WARNING Droid:setAnim: "..name.." does not exist" )
		self.anim = self.anims[ "idle" ]
		if not self.anim then
			print( "ERROR Droid:setAnim: idle does not exist" )
		end
	end
end

function Droid:draw()
	local x, y = self.body:getPosition()
	G.push()
	G.setColor( 255, 255, 255 )
	G.translate( x, y )
	G.rotate( self.body:getAngle() )
	G.draw( self.anims.img, self.anims.quads[ self.anim_quad ], -self.radius, -self.radius )
	G.pop()
end



function Droid:draw_debug_ai()
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



function Droid:updateBehaviourMoveTo( x, y )
	local a = V( self.body:getPosition() )
	local b = V( x, y )
	local d = b - a
	local vx, vy = self.body:getLinearVelocity()
	if d:length2() > self.radius*self.radius then
		d:norm()
		d:mul( 4 )
		self.body:applyLinearImpulse( d.x, d.y )
		self.body:setAngle( math.atan2( vy, vx ) )
		self:ai_debug_add { "dot", x, y }
		return true
	end
	return false
end



function Droid:pos()
	return self.body:getX(), self.body:getY()
end



function Droid:sightBeginContact( a, b )
	local ud = b:getUserData()
	if not ud then
		return
	elseif ud.id then
		self.sightMaybe[ ud.id ] = ud
	end
end

function Droid:sightEndContact( a, b )
	local ud = b:getUserData()
	if not ud then
		return
	elseif ud.id then
		self.sightMaybe[ ud.id ] = nil
	end
end

function Droid:updateSight()
	for id, o in pairs( self.sightMaybe ) do
		if self:updateSightRayCast( o ) then
			self.inSight[ id ] = o
			if o.pos then
				self.lastSeen[ o.id ] = { o:pos() }
			end
		elseif self.inSight[ id ] then
			self.inSight[ id ] = nil
		end
	end
	for id, o in pairs( self.inSight ) do
		if not self.sightMaybe[ id ] then
			self.inSight[ id ] = nil
		end
	end
end

function Droid:updateSightRayCast( target )
	if not target.pos then return false end

	local x1, y1 = self.body:getPosition()
	local x2, y2 = target:pos()

	self:ai_debug_add { "line", x1, y1, x2, y2 }

	local visible = false
	world:rayCast( x1, y1, x2, y2,
		function( fixture, x, y, xn, yn, fraction )

			self:ai_debug_add { "dot", x, y }

			local obj = fixture:getUserData()
			if not obj then
				return 1
			elseif obj.id == target.id then
				visible = true
				return 1
			elseif obj.type == "wall" or obj.type == "door" then
				visible = false
				return 0
			else
				return 1
			end
		end
	)
	return visible
end

function Droid:ai_debug_add( args )
	if isDown( "f3" ) then
		table.insert( self.ai_debug, args )
	end
end
