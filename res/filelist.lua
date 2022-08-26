
local fs = require("filesystem")

local folderPath = "/games/testgame/sprpic"
local resultPath = "/filelist.txt"

local function getFileList(path)
	local list = fs.list(path)
	local array = {}
	for file in list do
		table.insert(array, file)
	end
	list = nil
	return array
end

local function writeLineToFile(path, strLine)
	local file = io.open(path, 'a')
	file:write(( strLine or "" ).."\n")
	file:close()
end

local fileList = getFileList(folderPath)
for i = 1, #fileList do
	writeLineToFile(resultPath, fileList[i])
end
