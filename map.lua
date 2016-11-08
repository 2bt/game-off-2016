local json = require("dkjson")



Map = Object:new()
function Map:init()


	local raw = love.filesystem.read("data/map.json")
	local data = json.decode(raw)


	for i, layer in pairs(data.layers) do
		print(layer.name, layer.type)

	end

end


