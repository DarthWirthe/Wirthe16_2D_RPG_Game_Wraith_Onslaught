local component = require "component"
local unicode = require "unicode"
local colorlib = require "G_colorlib"

local buffer = {}
local debug = false
local sizeOfPixelData = 3

------------------------------------------------- Вспомогательные методы -----------------------------------------------------------------

--Формула конвертации индекса массива изображения в абсолютные координаты пикселя изображения
local function convertIndexToCoords(index)
	local integer, fractional = math.modf(index / (buffer.width * 3))
	return math.ceil(fractional * buffer.width), integer + 1
end

--Формула конвертации абсолютных координат пикселя изображения в индекс для массива изображения
local function convertCoordsToIndex(x, y)
	return (buffer.width * 3) * (y - 1) + x * 3 - 2
end

local function printDebug(line, text)
	if debug then
		ecs.square(1, line, buffer.width, 1, 0x262626)
		ecs.colorText(2, line, 0xFFFFFF, text)
	end
end

-- Установить ограниченную зону рисования. Все пиксели, не попадающие в эту зону, будут игнорироваться.
local function setDrawLimit(x, y, width, height)
	buffer.drawLimit = { x = x, y = y, x2 = x + width - 1, y2 = y + height - 1 }
end

-- Удалить ограничение зоны рисования, по умолчанию она будет от 1х1 до координат размера экрана.
local function resetDrawLimit()
	buffer.drawLimit = {x = 1, y = 1, x2 = buffer.width, y2 = buffer.height}
end

-- Создать массив буфера с базовыми переменными и базовыми цветами. Т.е. черный фон, белый текст.
local screenCurrent, screenNew = {}, {}

local function init()
	buffer.screen = {}
	
	screenNew = {}
	buffer.width, buffer.height = component.gpu.getResolution()

	resetDrawLimit()

	for y = 1, buffer.height do
		for x = 1, buffer.width do
			table.insert(screenCurrent, 0x010101)
			table.insert(screenCurrent, 0xFEFEFE)
			table.insert(screenCurrent, " ")

			table.insert(screenNew, 0x010101)
			table.insert(screenNew, 0xFEFEFE)
			table.insert(screenNew, " ")
		end
	end
end

------------------------------------------------- Методы отрисовки -----------------------------------------------------------------

-- Получить информацию о пикселе из буфера
local function get(x, y)
	local index = convertCoordsToIndex(x, y)
	if x >= 1 and y >= 1 and x <= buffer.width and y <= buffer.height then
		return screenNew[index], screenNew[index + 1], screenNew[index + 2]
	else
		error("Невозможно получить указанные значения, так как указанные координаты лежат за пределами экрана.\n")
	end
end

-- Установить пиксель в буфере
local function set(x, y, background, foreground, symbol)
	local index = convertCoordsToIndex(x, y)
	if x >= buffer.drawLimit.x and y >= buffer.drawLimit.y and x <= buffer.drawLimit.x2 and y <= buffer.drawLimit.y2 then
		screenNew[index] = background
		screenNew[index + 1] = foreground
		screenNew[index + 2] = symbol
	end
end

--Нарисовать квадрат
local function square(x, y, width, height, background, foreground, symbol, transparency)
	local index, indexPlus1, indexPlus2
	if transparency then transparency = transparency * 2.55 end
	if not foreground then foreground = 0x000000 end
	if not symbol then symbol = " " end
	
	for j = y, (y + height - 1) do
		for i = x, (x + width - 1) do
			if i >= buffer.drawLimit.x and j >= buffer.drawLimit.y and i <= buffer.drawLimit.x2 and j <= buffer.drawLimit.y2 then
				index = convertCoordsToIndex(i, j)
				indexPlus1 = index + 1
				indexPlus2 = index + 2

				if transparency then
					screenNew[index] = colorlib.alphaBlend(screenNew[index], background, transparency)
					screenNew[indexPlus1] = colorlib.alphaBlend(screenNew[indexPlus1], background, transparency)
				else
					screenNew[index] = background
					screenNew[indexPlus1] = foreground
					screenNew[indexPlus2] = symbol
				end
			end
		end
	end
end

--Очистка экрана, по сути более короткая запись buffer.square
local function clear(color, transparency)
	buffer.square(1, 1, buffer.width, buffer.height, color or 0x262626, 0x000000, " ", transparency)
end

--Заливка области изображения (рекурсивная, говно-метод)
local function fill(x, y, background, foreground, symbol)
	
	local startBackground, startForeground, startSymbol

	local function doFill(xStart, yStart)
		local index = convertCoordsToIndex(xStart, yStart)

		if
			screenNew[index] ~= startBackground or
			-- screenNew[index + 1] ~= startForeground or
			-- screenNew[index + 2] ~= startSymbol or
			screenNew[index] == background
			-- screenNew[index + 1] == foreground or
			-- screenNew[index + 2] == symbol
		then
			return
		end

		--Заливаем в память
		if xStart >= buffer.drawLimit.x and yStart >= buffer.drawLimit.y and xStart <= buffer.drawLimit.x2 and yStart <= buffer.drawLimit.y2 then
			screenNew[index] = background
			screenNew[index + 1] = foreground
			screenNew[index + 2] = symbol
		end

		doFill(xStart + 1, yStart)
		doFill(xStart - 1, yStart)
		doFill(xStart, yStart + 1)
		doFill(xStart, yStart - 1)

		iterator = nil
	end

	local startIndex = convertCoordsToIndex(x, y)
	startBackground = screenNew[startIndex]
	startForeground = screenNew[startIndex + 1]
	startSymbol = screenNew[startIndex + 2]

	doFill(x, y)
end

--Нарисовать окружность, алгоритм спизжен с вики
local function circle(xCenter, yCenter, radius, background, foreground, symbol)
	--Подфункция вставки точек
	local function insertPoints(x, y)
		set(xCenter + x * 2, yCenter + y, background, foreground, symbol)
		set(xCenter + x * 2, yCenter - y, background, foreground, symbol)
		set(xCenter - x * 2, yCenter + y, background, foreground, symbol)
		set(xCenter - x * 2, yCenter - y, background, foreground, symbol)

		set(xCenter + x * 2 + 1, yCenter + y, background, foreground, symbol)
		set(xCenter + x * 2 + 1, yCenter - y, background, foreground, symbol)
		set(xCenter - x * 2 + 1, yCenter + y, background, foreground, symbol)
		set(xCenter - x * 2 + 1, yCenter - y, background, foreground, symbol)
	end

	local x = 0
	local y = radius
	local delta = 3 - 2 * radius;
	while (x < y) do
		insertPoints(x, y);
		insertPoints(y, x);
		if (delta < 0) then
			delta = delta + (4 * x + 6)
		else 
			delta = delta + (4 * (x - y) + 10)
			y = y - 1
		end
		x = x + 1
	end

	if x == y then insertPoints(x, y) end
end

--Скопировать область изображения и вернуть ее в виде массива
local function copy(x, y, width, height)
	local copyArray = {
		["width"] = width,
		["height"] = height,
	}

	if x < 1 or y < 1 or x + width - 1 > buffer.width or y + height - 1 > buffer.height then
		error("Область копирования выходит за пределы экрана.")
	end

	local index
	for j = y, (y + height - 1) do
		for i = x, (x + width - 1) do
			index = convertCoordsToIndex(i, j)
			table.insert(copyArray, screenNew[index])
			table.insert(copyArray, screenNew[index + 1])
			table.insert(copyArray, screenNew[index + 2])
		end
	end

	return copyArray
end

--Вставить скопированную ранее область изображения
local function paste(x, y, copyArray)
	local index, arrayIndex
	if not copyArray or #copyArray == 0 then error("Массив области экрана пуст.") end

	for j = y, (y + copyArray.height - 1) do
		for i = x, (x + copyArray.width - 1) do
			if i >= buffer.drawLimit.x and j >= buffer.drawLimit.y and i <= buffer.drawLimit.x2 and j <= buffer.drawLimit.y2 then
				--Рассчитываем индекс массива основного изображения
				index = convertCoordsToIndex(i, j)
				--Копипаст формулы, аккуратнее!
				--Рассчитываем индекс массива вставочного изображения
				arrayIndex = (copyArray.width * (j - y) + (i - x + 1)) * sizeOfPixelData - sizeOfPixelData + 1
				--Вставляем данные
				screenNew[index] = copyArray[arrayIndex]
				screenNew[index + 1] = copyArray[arrayIndex + 1]
				screenNew[index + 2] = copyArray[arrayIndex + 2]
			end
		end
	end
end

--Нарисовать линию, алгоритм спизжен с вики
local function line(x1, y1, x2, y2, background, foreground, symbol)
	local deltaX = math.abs(x2 - x1)
	local deltaY = math.abs(y2 - y1)
	local signX = (x1 < x2) and 1 or -1
	local signY = (y1 < y2) and 1 or -1

	local errorCyka = deltaX - deltaY
	local errorCyka2

	set(x2, y2, background, foreground, symbol)

	while(x1 ~= x2 or y1 ~= y2) do
		set(x1, y1, background, foreground, symbol)

		errorCyka2 = errorCyka * 2

		if (errorCyka2 > -deltaY) then
			errorCyka = errorCyka - deltaY
			x1 = x1 + signX
		end

		if (errorCyka2 < deltaX) then
			errorCyka = errorCyka + deltaX
			y1 = y1 + signY
		end
	end
end

-- Отрисовка текста, подстраивающегося под текущий фон
local function text(x, y, color, text, transparency)
	local index
	if transparency then transparency = transparency * 2.55 end
	local sText = unicode.len(text)
	for i = 1, sText do
		if (x + i - 1) >= buffer.drawLimit.x and y >= buffer.drawLimit.y and (x + i - 1) <= buffer.drawLimit.x2 and y <= buffer.drawLimit.y2 then
			index = convertCoordsToIndex(x + i - 1, y)
			screenNew[index + 1] = not transparency and color or colorlib.alphaBlend(screenNew[index], color, transparency)
			screenNew[index + 2] = unicode.sub(text, i, i)
		end
	end
end

-- Отрисовка изображения
local function image(x, y, picture)
	if not picture then error("Image is empty, got nil.") end
	local xPos, xEnd = x, x + picture.width - 1
	local bufferIndex, bufferIndexPlus1, bufferIndexPlus2, imageIndexPlus1, imageIndexPlus2, imageIndexPlus3 = convertCoordsToIndex(x, y)
	local bufferIndexIterationStep = (buffer.width - picture.width) * 3

	for imageIndex = 1, #picture, 4 do
		if xPos >= buffer.drawLimit.x and y >= buffer.drawLimit.y and xPos <= buffer.drawLimit.x2 and y <= buffer.drawLimit.y2 then
			bufferIndexPlus1, bufferIndexPlus2, imageIndexPlus1, imageIndexPlus2, imageIndexPlus3 = bufferIndex+1,bufferIndex+2,imageIndex+1,imageIndex+2,imageIndex+3
			--Фон и его прозрачность
			if picture[imageIndexPlus2] == 0 then
				screenNew[bufferIndex] = picture[imageIndex]
				screenNew[bufferIndexPlus1] = picture[imageIndexPlus1]
				screenNew[bufferIndexPlus2] = picture[imageIndexPlus3]
			elseif picture[imageIndexPlus2] > 0 and picture[imageIndexPlus2] < 255 then
				screenNew[bufferIndex] = colorlib.alphaBlend(screenNew[bufferIndex], picture[imageIndex], picture[imageIndexPlus2])
				screenNew[bufferIndexPlus1] = picture[imageIndexPlus1]
				screenNew[bufferIndexPlus2] = picture[imageIndexPlus3]
			elseif picture[imageIndexPlus2] == 255 and picture[imageIndexPlus3] ~= " " then
				screenNew[bufferIndexPlus1] = picture[imageIndexPlus1]
				screenNew[bufferIndexPlus1] = picture[imageIndexPlus1]
				screenNew[bufferIndexPlus2] = picture[imageIndexPlus3]
			end
		
		end

		--Корректируем координаты и индексы
		xPos = xPos + 1
		bufferIndex = bufferIndex + 3
		if xPos > xEnd then
			xPos, y, bufferIndex = x, y + 1, bufferIndex + bufferIndexIterationStep
		end
	end
end

-- Отрисовка любого изображения в виде трехмерного массива. Неоптимизированно, зато просто.
local function customImage(x, y, pixels)
	x = x - 1
	y = y - 1

	for i=1, #pixels do
		for j=1, #pixels[1] do
			if pixels[i][j][3] ~= "#" then
				set(x + j, y + i, pixels[i][j][1], pixels[i][j][2], pixels[i][j][3])
			end
		end
	end

	return (x + 1), (y + 1), (x + #pixels[1]), (y + #pixels)
end

local tableinsert, tableconcat, gpusetbackground, gpusetforeground, gpuset = table.insert, table.concat, component.gpu.setBackground, component.gpu.setForeground, component.gpu.set

local function draw(force)
	local changes, index, indexStepOnEveryLine, indexPlus1, indexPlus2, equalChars, x, charX, charIndex, charIndexPlus1, charIndexPlus2, currentForeground = {}, convertCoordsToIndex(buffer.drawLimit.x, buffer.drawLimit.y), (buffer.width - buffer.drawLimit.x2 + buffer.drawLimit.x - 1) * 3
	
	for y = buffer.drawLimit.y, buffer.drawLimit.y2 do
		x = buffer.drawLimit.x
		while x <= buffer.drawLimit.x2 do
			indexPlus1, indexPlus2 = index + 1, index + 2
			if
				screenCurrent[index] ~= screenNew[index] or
				screenCurrent[indexPlus1] ~= screenNew[indexPlus1] or
				screenCurrent[indexPlus2] ~= screenNew[indexPlus2] or
				force
			then
				-- Make pixel at both frames equal
				screenCurrent[index] = screenNew[index]
				screenCurrent[indexPlus1] = screenNew[indexPlus1]
				screenCurrent[indexPlus2] = screenNew[indexPlus2]
				equalChars = {screenCurrent[indexPlus2]}
				charX, charIndex = x + 1, index + 3
				while charX <= buffer.width do
					charIndexPlus1, charIndexPlus2 = charIndex + 1, charIndex + 2
					if	
						screenCurrent[index] == screenNew[charIndex] and
						(
							screenNew[charIndexPlus2] == " " or
							screenCurrent[indexPlus1] == screenNew[charIndexPlus1]
						)
					then
					 	screenCurrent[charIndex] = screenNew[charIndex]
					 	screenCurrent[charIndexPlus1] = screenNew[charIndexPlus1]
					 	screenCurrent[charIndexPlus2] = screenNew[charIndexPlus2]

					 	tableinsert(equalChars, screenCurrent[charIndexPlus2])
					else
						break
					end

					charIndex, charX = charIndex + 3, charX + 1
				end
				changes[screenCurrent[index]] = changes[screenCurrent[index]] or {}
				changes[screenCurrent[index]][screenCurrent[indexPlus1]] = changes[screenCurrent[index]][screenCurrent[indexPlus1]] or {}

				tableinsert(changes[screenCurrent[index]][screenCurrent[indexPlus1]], x)
				tableinsert(changes[screenCurrent[index]][screenCurrent[indexPlus1]], y)
				tableinsert(changes[screenCurrent[index]][screenCurrent[indexPlus1]], tableconcat(equalChars))
				
				x, index = x + #equalChars - 1, index + (#equalChars - 1) * 3
			end

			x, index = x + 1, index + 3
		end

		index = index + indexStepOnEveryLine
	end
	for background, foregrounds in pairs(changes) do
		gpusetbackground(background)

		for foreground, pixels in pairs(foregrounds) do
			if currentForeground ~= foreground then
				gpusetforeground(foreground)
				currentForeground = foreground
			end

			for i = 1, #pixels, 3 do
				gpuset(pixels[i], pixels[i + 1], pixels[i + 2])
			end
		end
	end
	changes = nil
end

return {
draw = draw,
get = get,
set = set,
text =text,
square = square,
fill = fill,
copy = copy,
paste = paste,
line = line,
circle = circle,
init = init,
setDrawLimit = setDrawLimit,
resetDrawLimit = resetDrawLimit,
image = image,
clear = clear
}

