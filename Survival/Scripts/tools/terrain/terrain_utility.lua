-- terrain_utility.lua

function inverseRotateLocal( cellX, cellY, x, y )
	local rotationStep = getCellRotationStep( cellX, cellY )
	local rx, ry
	if rotationStep == 1 then
		rx = y
		ry = CELL_SIZE - x
	elseif rotationStep == 2 then
		rx = CELL_SIZE - x
		ry = CELL_SIZE - y
	elseif rotationStep == 3 then
		rx = CELL_SIZE - y
		ry = x
	else
		rx = x
		ry = y
	end

	return rx, ry
end

function rotateLocal( cellX, cellY, x, y )
	local rotationStep = getCellRotationStep( cellX, cellY )

	local rx, ry
	if rotationStep == 1 then
		rx = CELL_SIZE - y
		ry = x
	elseif rotationStep == 2 then
		rx = CELL_SIZE - x
		ry = CELL_SIZE - y
	elseif rotationStep == 3 then
		rx = y
		ry = CELL_SIZE - x
	else
		rx = x
		ry = y
	end

	return rx, ry
end

function getRotationStepQuat( cellX, cellY )
	local rotationStep = getCellRotationStep( cellX, cellY )
	if rotationStep == 1 then
		return sm.quat.new( 0, 0, 0.70710678118654752440084436210485, 0.70710678118654752440084436210485 )
	elseif rotationStep == 2 then
		return sm.quat.new( 0, 0, 1, 0 )
	elseif rotationStep == 3 then
		return sm.quat.new( 0, 0, -0.70710678118654752440084436210485, 0.70710678118654752440084436210485 )
	end

	return sm.quat.new( 0, 0, 0, 1 )
end