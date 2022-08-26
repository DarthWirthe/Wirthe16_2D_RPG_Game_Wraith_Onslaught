
local fs = require("filesystem")
local image1 = require("G_image")
local image2 = require("E_image")

local folderPath = "/home/images/"
local resultPath = "/home/result/"
local picture1

local w, h

local function getFileList(path)
	local list = fs.list(path)
	local array = {}
	for file in list do
		table.insert(array, file)
	end
	list = nil
	return array
end

local picture2
local result, reason

local fileList = getFileList(folderPath)

for i = 1, #fileList do
	picture1 = image1.load(folderPath..fileList[i])
	w, h = picture1.width, picture1.height
	picture2 = {w, h, {}, {}, {}, {}}

	for i = 1, picture1.width * picture1.height * 4, 4 do
		local background, foreground, alpha, symbol = picture1[i], picture1[i + 1], picture1[i + 2] / 255, picture1[i + 3]
		table.insert(picture2[3], background)
		table.insert(picture2[4], foreground)
		table.insert(picture2[5], alpha or 0x0)
		table.insert(picture2[6], symbol)
	end

	result, reason = image2.save(resultPath..fileList[i], picture2, 6)

	if result == true then
		image2.draw(1, 1, picture2)
	else
		print(reason)
	end

end