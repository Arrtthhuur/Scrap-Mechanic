--terrain_builder.lua

dofile("terrain_builder_celldata.lua")
dofile("builder_tile_list.lua")
dofile("terrain_utility.lua")

----------------------------------------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------------------------------------

local FENCE_MIN_CELL = -12
local FENCE_MAX_CELL = 11
	
local DESERT_FADE_START = ( FENCE_MAX_CELL - 0.2 ) * CELL_SIZE
local DESERT_FADE_END = ( FENCE_MAX_CELL ) * CELL_SIZE
local DESERT_FADE_RANGE = DESERT_FADE_END - DESERT_FADE_START

----------------------------------------------------------------------------------------------------
-- Save Data
----------------------------------------------------------------------------------------------------

g_saveStates = {}
g_maxNumSaves = 21
g_saveStateIndex = 0

----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Initialization
----------------------------------------------------------------------------------------------------

function init( tileRootPath, tileDatabasePath )

end

----------------------------------------------------------------------------------------------------

function create( xMin, xMax, yMin, yMax, seed )
	g_cellData.bounds.xMin = xMin
	g_cellData.bounds.xMax = xMax
	g_cellData.bounds.yMin = yMin
	g_cellData.bounds.yMax = yMax
	g_cellData.seed = seed
	initializeCellData( xMin, xMax, yMin, yMax )
	saveState()
end

----------------------------------------------------------------------------------------------------

function load()
	
end

----------------------------------------------------------------------------------------------------

function saveState()
	g_saveStateIndex = g_saveStateIndex + 1	
	if g_saveStateIndex > g_maxNumSaves then
		g_saveStates[g_saveStateIndex] = getTerrainCellData()
		table.remove(g_saveStates, 1)
		g_saveStateIndex = g_maxNumSaves		
	else
		g_saveStates[g_saveStateIndex] = getTerrainCellData()
	end
end

----------------------------------------------------------------------------------------------------

function loadState()
	g_saveStateIndex = g_saveStateIndex - 1
	if g_saveStateIndex < 1 then		
		g_saveStateIndex = 1
	else	
		removeAllTiles()		
		loadTerrain( g_saveStates[g_saveStateIndex] )	
	end
end

----------------------------------------------------------------------------------------------------

function saveWorld( worldFile )
	local terrainCellData = getTerrainCellData()
	
	--Save terrain as world builder json
	sm.json.save(terrainCellData, worldFile)
end

----------------------------------------------------------------------------------------------------

function loadWorld( worldFile )
	removeAllTiles()
	local terrainData = sm.json.open( worldFile )	
	loadTerrain( terrainData )
	saveState()
end

----------------------------------------------------------------------------------------------------

function loadTerrain( terrainData )

	if terrainData.cellData == nil then
		return
	end
	
	local cellData = terrainData.cellData	
	for index = 1, #cellData do		
		local id = getOrCreateTileId( cellData[index].path, g_terrainTileList )
		local cellX = cellData[index].x
		local cellY = cellData[index].y
		local offsetX = cellData[index].offsetX
		local offsetY = cellData[index].offsetY
		local rotation = cellData[index].rotation
		setCell( cellX, cellY, offsetX, offsetY, id, rotation )
	end
end

----------------------------------------------------------------------------------------------------

function getTerrainCellData()

	local cellDataTable = {}
	local yMin = g_cellData.bounds.yMin
	local yMax = g_cellData.bounds.yMax
	local xMin = g_cellData.bounds.xMin
	local xMax = g_cellData.bounds.xMax
	
	for cellY = yMin, yMax do
		for cellX = xMin, xMax do			
			local id = g_cellData.tileId[cellY][cellX]
			if id > 0 then			
				local tileOffsetX = g_cellData.tileOffsetX[cellY][cellX]
				local tileOffsetY = g_cellData.tileOffsetY[cellY][cellX]
				local rotation = g_cellData.rotation[cellY][cellX]
				local path = getTilePath( id )		
				table.insert(cellDataTable, {rotation = rotation, offsetY = tileOffsetY, offsetX = tileOffsetX, y = cellY, x = cellX, path = path})

				--local tileUuid = sm.terrainTile.getTileUuid( path )
				--local creatorId = sm.terrainTile.getCreatorId( path )
				--table.insert(cellDataTable, {rotation = rotation, offsetY = tileOffsetY, offsetX = tileOffsetX, y = cellY, x = cellX, path = path, tileUuid = tileUuid, creatorId = creatorId})
			end
		end
	end		

	local terrainTable = { cellData = cellDataTable }	
	return terrainTable
	
end

----------------------------------------------------------------------------------------------------
-- Generator API Getters
----------------------------------------------------------------------------------------------------

function getHeightAt( x, y, lod )
	local cellX, cellY = getCell( x, y )
	local id, tileCellOffsetX, tileCellOffsetY = getCellTileIdAndOffset( cellX, cellY )

	local lx = x - cellX * CELL_SIZE
	local ly = y - cellY * CELL_SIZE
	
	local rx, ry = inverseRotateLocal( cellX, cellY, lx, ly )

	local height = sm.terrainTile.getHeightAt( id, tileCellOffsetX, tileCellOffsetY, lod, rx, ry )

	return height
end

----------------------------------------------------------------------------------------------------

function getColorAt( x, y, lod )
	local cellX, cellY = getCell( x, y )
	local id, tileCellOffsetX, tileCellOffsetY = getCellTileIdAndOffset( cellX, cellY )
	
	local rx, ry = inverseRotateLocal( cellX, cellY, x - cellX * CELL_SIZE, y - cellY * CELL_SIZE )
	
	local r, g, b = sm.terrainTile.getColorAt( id, tileCellOffsetX, tileCellOffsetY, lod, rx, ry )

	local noise = sm.noise.octaveNoise2d( x / 8, y / 8, 5, 45 )
	local brightness = noise * 0.25 + 0.75
	local color = { r, g, b }

	local desertColor = { 255 / 255, 171 / 255, 111 / 255 }
	
	local maxDist = math.max( math.abs(x), math.abs(y) )
	if maxDist >= DESERT_FADE_END then
		color[1] = desertColor[1]
		color[2] = desertColor[2]
		color[3] = desertColor[3]
	else
		if maxDist > DESERT_FADE_START then
			local fade = ( maxDist - DESERT_FADE_START ) / DESERT_FADE_RANGE
			color[1] = color[1] + ( desertColor[1] - color[1] ) * fade
			color[2] = color[2] + ( desertColor[2] - color[2] ) * fade
			color[3] = color[3] + ( desertColor[3] - color[3] ) * fade
		end
	end

	return color[1] * brightness, color[2] * brightness, color[3] * brightness
end

----------------------------------------------------------------------------------------------------

function getMaterialAt( x, y, lod )
	local cellX, cellY = getCell( x, y )
	local id, tileCellOffsetX, tileCellOffsetY = getCellTileIdAndOffset( cellX, cellY )
	
	local rx, ry = inverseRotateLocal(cellX, cellY, x - cellX * CELL_SIZE, y - cellY * CELL_SIZE)
	
	local maxDist = math.max( math.abs(x), math.abs(y) )

	local mat1, mat2, mat3, mat4, mat5, mat6, mat7, mat8 = sm.terrainTile.getMaterialAt( id, tileCellOffsetX, tileCellOffsetY, lod, rx, ry )
	
	local maxDist = math.max( math.abs(x), math.abs(y) )
	if maxDist >= DESERT_FADE_END then
		mat1 = 1.0
	elseif maxDist > DESERT_FADE_START then
		local fade = ( maxDist - DESERT_FADE_START ) / DESERT_FADE_RANGE
		mat1 = mat1 + ( 1.0 - mat1 ) * fade
	end
	
	return mat1, mat2, mat3, mat4, mat5, mat6, mat7, mat8
end

----------------------------------------------------------------------------------------------------

function getClutterIdxAt( x, y )
	local cellX = math.floor( x / ( CELL_SIZE * 2 ) )
	local cellY = math.floor( y / ( CELL_SIZE * 2 ) )
	local maxDist = math.max( math.abs(x), math.abs(y) ) / 2
	local id, tileCellOffsetX, tileCellOffsetY = getCellTileIdAndOffset( cellX, cellY )
	
	local rx, ry = inverseRotateLocal( cellX, cellY, x * 0.5 - cellX * CELL_SIZE, y * 0.5 - cellY * CELL_SIZE )

	local clutterIdx = sm.terrainTile.getClutterIdxAt( id, tileCellOffsetX, tileCellOffsetY, rx * 2, ry * 2 )
	return clutterIdx
end

----------------------------------------------------------------------------------------------------

function getAssetsForCell( cellX, cellY, lod )
	local id, tileCellOffsetX, tileCellOffsetY = getCellTileIdAndOffset( cellX, cellY )
	if id ~= 0 then
		local assets = sm.terrainTile.getAssetsForCell( id, tileCellOffsetX, tileCellOffsetY, lod )

		for i,asset in ipairs(assets) do
			local rx, ry = rotateLocal( cellX, cellY, asset.pos.x, asset.pos.y )

			local x = cellX * CELL_SIZE + rx
			local y = cellY * CELL_SIZE + ry

			asset.pos = sm.vec3.new( rx, ry, asset.pos.z )
			asset.rot = getRotationStepQuat( cellX, cellY ) * asset.rot
		end

		return assets
	end
	return {}
end

----------------------------------------------------------------------------------------------------
-- World Builder Functions
----------------------------------------------------------------------------------------------------

function getTileOrigin( x, y )
	local cellX, cellY = getCell( x, y )
	local originCellX, originCellY = findTileOrigin( cellX, cellY )
	return originCellX * CELL_SIZE, originCellY * CELL_SIZE	
end

----------------------------------------------------------------------------------------------------

function removeTile( x, y )
	local cellX, cellY = getCell( x, y )
	local id = g_cellData.tileId[cellY][cellX]
	local size = sm.terrainTile.getSize( getTilePath( id ) )	
	local originX, originY = findTileOrigin(cellX, cellY)
	setTile( originX, originY, size, 0, 0 )
end

----------------------------------------------------------------------------------------------------

function rotateTile( x, y, deltaRotation )
	local cellX, cellY = getCell( x, y )
	local id = g_cellData.tileId[cellY][cellX]
	local size = sm.terrainTile.getSize( getTilePath( id ) )	
	local originX, originY = findTileOrigin(cellX, cellY)
	local rotation = g_cellData.rotation[cellY][cellX]
	
	local rotationStep = rotation + deltaRotation
	rotationStep = math.fmod(rotationStep, 4)
	if rotationStep < 0 then
		rotationStep = rotationStep + 4
	end

	setTile( originX, originY, size, id, rotationStep )
	saveState()
end

----------------------------------------------------------------------------------------------------

function findTileOrigin(cellX, cellY)
	
	local tileCornerX = cellX
	local tileCornerY = cellY
	
	local id = g_cellData.tileId[cellY][cellX]
	if id == 0 then
		return tileCornerX, tileCornerY
	end	
	
	local size = sm.terrainTile.getSize( getTilePath( id ) )
	local rotation = g_cellData.rotation[cellY][cellX]
	local tileOffsetX = g_cellData.tileOffsetX[cellY][cellX]
	local tileOffsetY = g_cellData.tileOffsetY[cellY][cellX]

	if rotation == 1 then
		tileCornerX = cellX + tileOffsetY  - (size - 1)
		tileCornerY = cellY - tileOffsetX 
	elseif rotation == 2 then
		tileCornerX = cellX + tileOffsetX - (size - 1)
		tileCornerY = cellY + tileOffsetY - (size - 1)
	elseif rotation == 3 then
		tileCornerX = cellX - tileOffsetY 
		tileCornerY = cellY + tileOffsetX - (size - 1)
	else
		tileCornerX = cellX - tileOffsetX 
		tileCornerY = cellY - tileOffsetY 
	end
	return tileCornerX, tileCornerY
	
end

----------------------------------------------------------------------------------------------------

function isTileWhole(cellX, cellY)

	if not insideTileMapBounds(cellX, cellY) then
		return false
	end	
	
	local id = g_cellData.tileId[cellY][cellX]	
	if id == 0 then 
		return false
	end
	
	local size = sm.terrainTile.getSize( getTilePath( id ) )
	local originX, originY = findTileOrigin(cellX, cellY)
	
	for cellOffsetY = 0, size - 1 do
		for cellOffsetX = 0, size - 1 do
			if not insideTileMapBounds(originX + cellOffsetX, originY + cellOffsetY) then
				return false
			end
			
			local offsetId = g_cellData.tileId[originY + cellOffsetY][originX + cellOffsetX]
			local offsetOriginX, offsetOriginY = findTileOrigin(originX + cellOffsetX, originY + cellOffsetY)						
			if id ~= offsetId or originX ~= offsetOriginX or originY ~= offsetOriginY then
				return false
			end			
		end		
	end
	
	return true
end

----------------------------------------------------------------------------------------------------

function canGrabTile(x, y)
	local xCoord, yCoord = getCell(x, y)
	if isTileWhole(xCoord, yCoord) then
		return true
	end	
	return false	
end

----------------------------------------------------------------------------------------------------

function moveTile(startX, startY, x, y, freePlacement)
	local cellX, cellY = getCell( startX, startY )
	local releasedCellX, releasedCellY = getCell(x, y)		
	local id = g_cellData.tileId[cellY][cellX]	
	local size = sm.terrainTile.getSize( getTilePath( id ) )	
	local rotation = g_cellData.rotation[cellY][cellX]

	local validMove = canMove( startX, startY, x, y, freePlacement )
		
	if validMove then	
		removeTile(startX, startY)
		setTile( releasedCellX, releasedCellY, size, id, rotation )
		saveState()
	end	
	
	return validMove
end

----------------------------------------------------------------------------------------------------
function canMove( startX, startY, x, y, freePlacement )
	local cellX, cellY = getCell( startX, startY )
	local releasedCellX, releasedCellY = getCell(x, y)		
	local id = g_cellData.tileId[cellY][cellX]
	if id ~= 0 then
		local size = sm.terrainTile.getSize( getTilePath( id ) )	
		
		local grabbedCellX, grabbedCellY = findTileOrigin(cellX, cellY)	
		local xMin = grabbedCellX
		local xMax = grabbedCellX + (size - 1)
		local yMin = grabbedCellY
		local yMax = grabbedCellY + (size - 1)
		
		local canPlace = true
		if not freePlacement then
			for cellOffsetY = 0, size - 1 do
				for cellOffsetX = 0, size - 1 do								
					--if cell is outside of previously occupied location
					if 	(releasedCellX + cellOffsetX) > xMax or 
						(releasedCellX + cellOffsetX) < xMin or 
						(releasedCellY + cellOffsetY) > yMax or 
						(releasedCellY + cellOffsetY) < yMin then
						
						--check if area is free					
						if not insideTileMapBounds(releasedCellX + cellOffsetX, releasedCellY + cellOffsetY) then
							canPlace = false
						else
							local cellId = g_cellData.tileId[releasedCellY + cellOffsetY][releasedCellX + cellOffsetX]
							if cellId ~= 0 then
								canPlace = false
							end
						end
					end
				end
			end
		end
		
		return canPlace
	end
	return false
end
----------------------------------------------------------------------------------------------------

function setTileAt( x, y, rotation, tilePath, freePlacement )
	local tileSize = sm.terrainTile.getSize( tilePath )
	local xCoord, yCoord = getCell(x, y)
	
	if not freePlacement then
		if not isAreaFree(x, y, tileSize) then
			return
		end
	end

	local id = getOrCreateTileId( tilePath, g_terrainTileList )
	setTile( xCoord, yCoord, tileSize, id, rotation )
	saveState()
end

----------------------------------------------------------------------------------------------------

function isAreaFree( x, y, size)
	local cellX, cellY = getCell( x, y )
	for cellOffsetY = 0, size - 1 do
		for cellOffsetX = 0, size - 1 do
			local isInsideBounds = insideTileMapBounds(cellX + cellOffsetX, cellY + cellOffsetY)
			if isInsideBounds then
				local id = g_cellData.tileId[cellY + cellOffsetY][cellX + cellOffsetX]
				if id ~= 0 then
					return false
				end
			else
				return false
			end
		end		
	end
	return true
end

----------------------------------------------------------------------------------------------------

function clearWorld()
	removeAllTiles()
	saveState()
end

----------------------------------------------------------------------------------------------------

function removeAllTiles()

	local yMin = g_cellData.bounds.yMin
	local yMax = g_cellData.bounds.yMax
	local xMin = g_cellData.bounds.xMin
	local xMax = g_cellData.bounds.xMax
	
	for cellY = yMin, yMax do
		for cellX = xMin, xMax do
			setCell( cellX, cellY, 0, 0, 0, 0 )
		end
	end	
end

----------------------------------------------------------------------------------------------------

function removeTiles(x, y, size, freePlacement)
	local xCoord, yCoord = getCell(x, y)
	if freePlacement then
		setTile( xCoord, yCoord, size, 0, 0 )
	else		
		for cellOffsetY = 0, size - 1 do
			for cellOffsetX = 0, size - 1 do
				local id = getCellTileId( xCoord + cellOffsetX, yCoord + cellOffsetY )
				if id ~= 0 then
					local foundCellSize = sm.terrainTile.getSize( getTilePath( id ) )
					if isTileWhole(xCoord + cellOffsetX, yCoord + cellOffsetY) then
						local originX, originY = findTileOrigin(xCoord + cellOffsetX, yCoord + cellOffsetY)
						setTile( originX, originY, foundCellSize, 0, 0 )
					else
						setTile( xCoord + cellOffsetX, yCoord + cellOffsetY, 1, 0, 0 )
					end
				end
			end
		end		
	end
	saveState()
end

----------------------------------------------------------------------------------------------------

function getTileAt( x, y )
	local cellX, cellY = getCell( x, y )
	
	local id = getCellTileId( cellX, cellY )
	
	if id ~= 0 then
		return getTileIdPath( id )
	end
	
	return ""
end

----------------------------------------------------------------------------------------------------
-- Tile Reader Path Getter
----------------------------------------------------------------------------------------------------

function getTilePath( id )
	if id ~= 0 then
		return getTileIdPath( id )
	end
end
