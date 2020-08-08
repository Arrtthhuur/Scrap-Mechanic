--terrain_builder_celldata.lua

----------------------------------------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------------------------------------

CELL_SIZE = 64

----------------------------------------------------------------------------------------------------
-- Global terrain data
----------------------------------------------------------------------------------------------------

g_cellData = {
	bounds = { xMin=0, xMax=0, yMin=0, yMax=0 },
	seed = 0,
	tileId = {},
	tileOffsetX = {},
	tileOffsetY = {},
	rotation = {}
}

g_dirtyCells = {}

----------------------------------------------------------------------------------------------------
-- Init cell data
----------------------------------------------------------------------------------------------------

function initializeCellData(xMin, xMax, yMin, yMax)
	for cellY = yMin, yMax do
		g_cellData.tileId[cellY] = {}
		g_cellData.tileOffsetX[cellY] = {}
		g_cellData.tileOffsetY[cellY] = {}
		g_cellData.rotation[cellY] = {}
		
		for cellX = xMin, xMax do
			g_cellData.tileId[cellY][cellX] = 0
			g_cellData.tileOffsetX[cellY][cellX] = 0
			g_cellData.tileOffsetY[cellY][cellX] = 0
			g_cellData.rotation[cellY][cellX] = 0
		end
	end
end

----------------------------------------------------------------------------------------------------

function setTile( currentX, currentY, size, id, rotation )
	for cellY = 0, size - 1 do
		for cellX = 0, size - 1 do
			if insideTileMapBounds(currentX + cellX, currentY + cellY) then
				g_cellData.tileId[currentY + cellY][currentX + cellX] = id
				g_cellData.rotation[currentY + cellY][currentX + cellX] = rotation

				if rotation == 1 then
					g_cellData.tileOffsetX[currentY + cellY][currentX + cellX] = cellY % size
					g_cellData.tileOffsetY[currentY + cellY][currentX + cellX] = ( size - 1 ) - cellX % size
				elseif rotation == 2 then
					g_cellData.tileOffsetX[currentY + cellY][currentX + cellX] = ( size - 1 ) - cellX % size
					g_cellData.tileOffsetY[currentY + cellY][currentX + cellX] = ( size - 1 ) - cellY % size
				elseif rotation == 3 then
					g_cellData.tileOffsetX[currentY + cellY][currentX + cellX] = ( size - 1 ) - cellY % size
					g_cellData.tileOffsetY[currentY + cellY][currentX + cellX] = cellX % size
				else
					g_cellData.tileOffsetX[currentY + cellY][currentX + cellX] = cellX % size
					g_cellData.tileOffsetY[currentY + cellY][currentX + cellX] = cellY % size
				end
				addDirtyCell(currentX + cellX, currentY + cellY)
			end
		end
	end
	
end

----------------------------------------------------------------------------------------------------

function setCell( cellX, cellY, offsetX, offsetY, id, rotation )

	g_cellData.tileId[cellY][cellX] = id
	g_cellData.tileOffsetX[cellY][cellX] = offsetX
	g_cellData.tileOffsetY[cellY][cellX] = offsetY
	g_cellData.rotation[cellY][cellX] = rotation

	addDirtyCell(cellX, cellY)
end

----------------------------------------------------------------------------------------------------

function addDirtyCell( cellX, cellY )
	
	for offsetY = -1, 1 do
		for offsetX = -1, 1 do
			if insideTileMapBounds(cellX - offsetX, cellY - offsetY) then
				if not isCellDirty(cellX - offsetX, cellY - offsetY) then
					table.insert(g_dirtyCells, {y = cellY - offsetY, x = cellX - offsetX})
				end
			end
		end
	end
	
end

----------------------------------------------------------------------------------------------------

function isCellDirty( cellX, cellY )
	for index = 1, #g_dirtyCells do
		if g_dirtyCells[index].x == cellX and g_dirtyCells[index].y == cellY then
			return true
		end
	end
	return false	
end

----------------------------------------------------------------------------------------------------

function popDirtyCells()
	local dirtyCells = g_dirtyCells
	g_dirtyCells = {}
	return dirtyCells
end

----------------------------------------------------------------------------------------------------
-- Data convenience functions
----------------------------------------------------------------------------------------------------

function insideTileMapBounds(cellX, cellY)
	if cellX < g_cellData.bounds.xMin or cellX > g_cellData.bounds.xMax then
		return false
	elseif cellY < g_cellData.bounds.yMin or cellY > g_cellData.bounds.yMax then
		return false
	end
	return true
end

function insideBounds(cellX, cellY, bounds)
	local tileBounds = bounds / CELL_SIZE
	if cellX < -tileBounds or cellX >= tileBounds then
		return false
	elseif cellY < -tileBounds or cellY >= tileBounds then
		return false
	end
	return true
end

----------------------------------------------------------------------------------------------------

function getCell(x, y)
	return math.floor(x/CELL_SIZE), math.floor(y/CELL_SIZE)
end

----------------------------------------------------------------------------------------------------

function getFraction(x, y)
	local cellX = math.floor(x/CELL_SIZE)
	local cellY = math.floor(y/CELL_SIZE)
	local xFract = (x/CELL_SIZE - cellX)
	local yFract = (y/CELL_SIZE - cellY)

	return xFract, yFract
end

----------------------------------------------------------------------------------------------------

function getCellTileIdAndOffset(cellX, cellY)
	if insideTileMapBounds( cellX, cellY ) then
		return 	g_cellData.tileId[cellY][cellX],
				g_cellData.tileOffsetX[cellY][cellX],
				g_cellData.tileOffsetY[cellY][cellX]
	end
	return 0, 0, 0
end

----------------------------------------------------------------------------------------------------

function getCellTileId( cellX, cellY )
	if insideTileMapBounds( cellX, cellY ) then
		return 	g_cellData.tileId[cellY][cellX]
	end
	return 0
end

----------------------------------------------------------------------------------------------------

function getCellRotationStep( cellX, cellY )
	if insideTileMapBounds( cellX, cellY ) then
		if g_cellData.rotation[cellY] then
			return g_cellData.rotation[cellY][cellX]
		end
	end
	return 0
end
