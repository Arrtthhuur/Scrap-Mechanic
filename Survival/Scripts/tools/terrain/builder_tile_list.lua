--builder_tile_list.lua

----------------------------------------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------------------------------------

CREATIVE_TILE_DATA_PATH = "$GAME_DATA/Terrain/Patches/"

----------------------------------------------------------------------------------------------------
-- Data
----------------------------------------------------------------------------------------------------

g_terrainTileList = {}
g_takenIds = {}

----------------------------------------------------------------------------------------------------

function getAvailableId()
	local index = 1
	while g_takenIds[index] do
		index = index + 1
	end
	return index
end

----------------------------------------------------------------------------------------------------

function getOrCreateTileId( path, tileSet )

	--Try to get ID
	for index = 1, #tileSet do
		if tileSet[index]["tilePath"] == path then
			return tileSet[index]["tileId"]
		end
	end
	
	--Try to create ID
	local nextIndex = #tileSet + 1
	tileSet[nextIndex] = { tilePath = {}, tileId = 0 }
	tileSet[nextIndex].tilePath = path
	local id = getAvailableId()
	tileSet[nextIndex].tileId = id
	g_takenIds[id] = true	
	return id	
	
end

----------------------------------------------------------------------------------------------------

function getTileIdPath( id )
	
	for index = 1, #g_terrainTileList do
		if g_terrainTileList[index].tileId == id then
			return g_terrainTileList[index].tilePath
		end
	end

	print("Could not find id:", id)
	return CREATIVE_TILE_DATA_PATH .. "DESERT64_01.TILE" --ERROR
end

----------------------------------------------------------------------------------------------------

function getPathIdFromSet( path, tileSet )
	if tileSet == nil then
		return 0
	end

	for index = 1, #tileSet do
		if tileSet[index]["tilePath"] == path then
			return tileSet[index]["tileId"]
		end
	end
	
	return 0
end
