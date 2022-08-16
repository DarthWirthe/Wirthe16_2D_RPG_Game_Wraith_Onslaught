local term =		require("term")
local event =		require("event")
--local shell =		require("shell")
local image =		require("E_image")
local thread = 		require("G_thread")
local unicode =		require("unicode")
local computer =	require("computer")
local keyboard =  	require("keyboard")
local fs = 			require("filesystem")
local ser = 		require("serialization")
local buffer = 		require("E_doubleBuffering")
local component =	require("component")
local gpu = 		component.gpu
local tableInsert, tableRemove, mathFloor, mathCeil, mathMin, mathMax = table.insert, table.remove, math.floor, math.ceil, math.min, math.max
local mxw, mxh = gpu.maxResolution()

--[[ Контейнер для функций и конфигурации ]]--
local game = {
	_function = {},							-- Все функции
	_config = {								-- Неизменяемые настройки
		debugMode = false,
		unitDrawingDistance = 90,
		startWeapon = {[1]=7,[2]=124},
		reservedItemId = 200,
	},
	_parameter = {							-- Параметры
		lootItemImprovedChance = 25,
		physicalDamageReductionMul = 30,
		magicalDamageReductionMul = 30,
		healthPotionEffectID = 1,
		manaPotionEffectID = 2,
		inventorySize = 20,
		keys = {
			left1 = 203,
			left2 = 30,
			right1 = 205,
			right2 = 32,
			openInventory = 48,
			closeInventory = 48,
			interact = 18,
			jump = 57,
			spawn = 24,
			followerAction = 37,
			hp = 20,
			mp = 21,

		}
	},
	_data = {								-- Различные данные
		windowThread = nil,
		stopDrawing = false,
		inGame = true,
		paused = false,
		itemIcons,
		maxItemID,
		potralUnitId = 43,
		text = {
			directory = "/games/testgame/",
			logFile = "log.txt",
			screen1 = "Загрузка...",
			warning = "",
		},
		pauseMenuList = {
			"Продолжить игру",
			"Инвентарь",
			"Умения персонажа",
			"Характеристика",
			"Текущие задания",
			"Сохранить",
			"Загрузить",
			"Выйти из игры"
		},
		skillType = {
			[1] = "Атака",
			[2] = "Пассивный",
			[3] = "Бафф"
		},
		armorType = {
			"helmet",
			"pendant",
			"armor",
			"robe",
			"pants",
			"weapon",
			"footwear",
			"ring"
		},
		itemStatsNames = {
			["hp+"] = {"Здоровье"},
			["mp+"] = {"Мана"},
			["sur+"] = {"Выносливость"},
			["str+"] = {"Сила"},
			["int+"] = {"Магия"},
			["pdm+"] = {"Физическая атака"},
			["mdm+"] = {"Магическая атака"},
			["pdf+"] = {"Физическая защита"},
			["mdf+"] = {"Магическая защита"},
			["chc+"] = {"Вероятность нанесения критического удара","%"},
			["hp%"] = {"Максимальное здоровье","%"},
			["mp%"] = {"Максимальная мана","%"},
		},
		itemReqNames = {
			["lvl"] = "Требуемый уровень: ",
			["strg"] = "Требуемая сила: ",
			["int"] = "Требуемая магия: ",
			["agi"] = "Требуемая ловкость: ",
		},
		itemSubtypes = {
			[2]={
				[1] = "Накидка",
				[2] = "Кольцо",
				[3] = "Кулон",
				[4] = "Шлем",
				[5] = "Броня",
				[6] = "Поножи",
				[7] = "Сапоги",
				[8] = "Капюшон",
				[9] = "Мантия",
				[10]= "Магические поножи",
				[11]= "Магические сапоги"
			},
			[3]={
				[1] = "Меч",
				[2] = "Копьё",
				[3] = "Короткая секира",
				[4] = "Магический жезл"
			}
		},
		armorTypeIds = {
			["helmet"]={4,8},
			["armor"]={5,9},
			["pants"]={6,10},
			["footwear"]={7,11},
			["pendant"]={3},
			["robe"]={1},
			["ring"]={2},
		},
		emptyArmorPic = {
			[1]={"helmet","image/gigd1.pic"},
			[2]={"armor","image/gigd2.pic"},
			[3]={"pants","image/gigd3.pic"},
			[4]={"footwear","image/gigd4.pic"},
			[5]={"weapon","image/gigd5.pic"},
			[6]={"pendant","image/gigd6.pic"},
			[7]={"robe","image/gigd7.pic"},
			[8]={"ring","image/gigd8.pic"},
		},
		updatedPlayerStats = {
			["sur+"]=0,["str+"]=0,["int+"]=0,["agi+"]=0,
			["hp+"]=0,["mp+"]=0,["vPdm1"]=0,
			["pdm+"]=0,["mdm+"]=0,["vMdm1"]=0,
			["vPdm2"]=0,["vMdm2"]=0,["pdf+"]=0,
			["mdf+"]=0,["chc+"]=0,["hp%"]=0,
			["mp%"]=0,["pwd%"]=0,["mwd%"]=0,
			["weaponDistance"]=0
		},
		armorPhysicalDefenceMultiple = {
			[1]=30.6,[2]=8.3,[3]=19.5, -- общее
			[4]=38.2,[5]=40.4,[6]=38.7,[7]=37.3, -- физ
			[8]=14.2,[9]=23.8,[10]=21.1,[11]=11.4,
		},
		armorMagicalDefenceMultiple = {
			[1]=32.8,[2]=24.7,[3]=27.5, -- общее
			[4]=15.4,[5]=26.3,[6]=23.8,[7]=11.5, -- маг
			[8]=37.9,[9]=39.9,[10]=38.6,[11]=36.9,
		},
		messageTable1 = {"",""},
		messageTable1timer = 0,
	},
	_player = {
		id = 1,
		statsPoints = {vSur=0,vStr=0,vAgi=0,vInt=0,vPdm=0,vMdm=0},
		screenPosition = 75,
		pckTarget = nil,
		pickingUp = false,
		maxPckTime = 0,
		pckTime = 0,
		usepmx = false,
		actSkills = {1,2,3,4,0,0},
		quests = {} -- структура-{1(id),0(прогресс),0/1/2(доступно/не выполнено/выполнено)}
	},
	_gui = {
		blank = {

		},
		mainMenu = {},
		pauseMenu = {
			x = 1, y = 1, w = 30, h = 50, buttonX = 156, buttonY = 2,
			buttonFunction = {},
			action={}
		},
		NPCDialog = {
			currentDialog = nil,
			text = ""
		},
		playerSkills = {
			window = {
				x = 20, y = 5, w = 120, h = 40, title = "Умения"
			},
			targ = 0,
			action = {}
		},
		playerStats = {
			window = {
				x = 50, y = 12, w = 60, h = 25, title = "Персонаж"},
				x1 = 53, y1 = 26,
				info = {},
				selectedPoints = {0,0,0,0,0},
				action = {}
		},
		questsList = {
			window = {x = 30, y = 12, w = 100, h = 30, title = "Задания"},
			targetQuest = 0,
			action = {}
		},
		skillsTopPanel = {
			x = 115, y = 1, w = 28, h = 5, action = {},
			t = {
				{c = 0x614251, t = "/2"},
				{c = 0x0000FF, t = "*3"},
				{c = 0x008500, t = "@4"},
				{c = 0x8600A0, t = "&5"},
				{c = 0xEE0000, t = "!6"}
			}
		},
	}
}
-- game._data.text.directory
-- game._gui.NPCDialog.text
-- game._gui.blank.text
-- game._data.armorType

game._gui.mainMenu = {w=25,h=20,bx=2,bh=3,action={},imgx=4,imgy=2,obj={},mode=0,
			 [1]={w=50,h=20,class=1,obj={
								[1]={type=1,x=30,y=14,w=15,h=3,bcolor=0x838383,fcolor=0xcccccc,txt="Продолжить",
									action=function()
										if unicode.len(game._gui.mainMenu[1].obj[4].txt) >= 5 then
											if game._gui.mainMenu[1].class == 1 then
												game._player.id = 1
											elseif game._gui.mainMenu[1].class == 2 then
												game._player.id = 122
											end
											game._function.initGame()
											gud[CGD[game._player.id]["id"]]["name"] = game._gui.mainMenu[1].obj[4].txt
											end
										end
									},
								[2]={type=1,x=5,y=14,w=15,h=3,bcolor=0x838383,fcolor=0xcccccc,txt="Назад",
										action=function()
											game._gui.mainMenu.mode = 0
										end
									},
								[3]={type=2,x=5,y=5,w=40,h=1,bcolor=0x838383,fcolor=0xcccccc,txt="Имя содержит 6 - 18 символов:"},
								[4]={type=2,x=5,y=6,w=40,h=1,bcolor=0x222222,fcolor=0xffffff,txt=""},
								[5]={type=1,x=5,y=10,w=15,h=3,bcolor=0x555555,ccolor=0x22cc55,fcolor=0xcccccc,clicked=1,txt="Воин",
									action=function()
										game._gui.mainMenu[1].obj[5].clicked = 1
										game._gui.mainMenu[1].obj[6].clicked = 0
										game._gui.mainMenu[1].class = 1
									end
									},
								[6]={type=1,x=30,y=10,w=15,h=3,bcolor=0x555555,ccolor=0x22cc55,fcolor=0xcccccc,clicked=0,txt="Маг",
									action=function()
										game._gui.mainMenu[1].obj[6].clicked = 1
										game._gui.mainMenu[1].obj[5].clicked = 0
										game._gui.mainMenu[1].class = 2
									end
									},
								[7]={type=2,x=5,y=8,w=40,h=1,bcolor=0x838383,fcolor=0xcccccc,txt="Выберите класс:"},
								}
				 },
				 [2]={w=80,h=30,buff={},targ=nil,obj={
								[1]={type=1,x=10,y=25,w=20,h=3,bcolor=0x838383,fcolor=0xcccccc,txt="Назад",
									action = function()
									game._gui.mainMenu.mode = 0
									end
								},
								[2]={type=1,x=50,y=25,w=20,h=3,bcolor=0x838383,fcolor=0xcccccc,txt="Загрузить",
									action = function()
										if game._gui.mainMenu[2].targ then
											game._function.loadGame(game._data.text.directory .. "saves", game._gui.mainMenu[2].buff[game._gui.mainMenu[2].targ])
											game._gui.mainMenu.obj = {}
										end
									end
								},
								}

				 }
}

local cScreenStat = "Загрузка..."
local gotCriticalError = false
local startBckgColour = 0x222222
local cp = {white = 0xffffff, blue = 0x00aaff, magenta = 0x996dbf, golden = 0xffff00, orange = 0xffb420, green = 0xff9200}
local cGlobalx, cBackgroundPos = 1, 1
local pmov = 0
local bufferenv
local vAttackDistance

local gud, gid, gqd, gsd, eusd, ged, baseWtype, lootdata
local world
local imageBuffer = {} -- буффер для изображений, чтобы не грузить процессор и диск | с версии 1.2.1
local iconImageBuffer = {} -- буффер для иконок предметов | с версии 1.2.1
local CGD = {} -- массив со всеми персонажами
local cPlayerSkills = {} -- умения
local particles = {} -- тест
local savedUnits = {} -- (ache)

local playerParams = {
	[1]={
		["basehp"]=45,
		["basemp"]=28,
		["levelhpmul"]=28,
		["levelmpmul"]=7,
		["surhpmul"]=15,
		["intmpmul"]=6,
		["skills"]={
		{1,0,1},{2,0,1},{3,0,1},{4,0,1},{5,0,0},{6,0,0},{7,0,0},{8,0,0},{9,0,0},{10,0,0}
		}
	},
	[2]={
		["basehp"]=30,
		["basemp"]=42,
		["levelhpmul"]=18,
		["levelmpmul"]=24,
		["surhpmul"]=12,
		["intmpmul"]=15,
		["skills"]={
		{1,0,1},{11,0,1},{12,0,1},{13,0,1},{14,0,0},{15,0,0},{16,0,0}
		}
	}
}

game._function.watds = {[1]=10,[2]=12,[3]=10,[4]=3}
local weaponHitRate = {[1]=0.9,[2]=1,[3]=1.2,[4]=1}

local primaryError = _G.error

game._function.version = {1,2,8,1}

local gamefps, cfps, usram = 0, 0

local creditsInfo = {
	"Разрешение экрана только 160х50",
	"DoubleBuffering lib — автор IgorTimofeev",
	"Image lib, Сolor lib — автор IgorTimofeev",
	"Thread lib — автор Zer0Galaxy",
}

local function creditsInfoPrint()
	for f = 1, #creditsInfo do
		buffer.drawText(2, 48 - #creditsInfo + f, 0xA7A7A7, creditsInfo[f])
	end
end

--[[ Чёрный экран при запуске ]]--
local function startScreen()
	local ank, lec, sle = 20, 1, 0.001
	local limg = image.load(game._data.text.directory.."image/slg.pic")

	for f = 1, ank do
		buffer.drawRectangle(1, 1, mxw, mxh, startBckgColour, 0, " ")
		buffer.drawText(2, 2, 0xA7A7A7, game._data.text.screen1)
		ank, lec = 80 - mathFloor(limg[1] / 2),25 - mathFloor(limg[2] / 2)
		if f == 19 then
			ank = ank - 1; lec = lec + 1
		end
		if f == 24 then
			ank = ank + 1
			lec = lec - 1
		end
		buffer.drawImage(ank, lec, limg)
		creditsInfoPrint()
		buffer.drawChanges()
		os.sleep(sle)
	end

	buffer.drawText(2, 2, 0xA7A7A7, game._data.text.screen1)

	local totalMem = mathCeil(computer.totalMemory()/1048576*10)/10

	if mxw < 160 or mxh < 50 then
		gotCriticalError = true
		game._data.text.warning = 'Текущее разрешение экрана не соответствует требуемому.'
	end

	if totalMem > 0 and totalMem < 1.8 then
		gotCriticalError = true
		game._data.text.warning = game._data.text.warning .. ' оперативной памяти ('..totalMem..' МБ) недостаточно для нормальной работы программы.'
	end

end


function game._function.RAMInfo()
	return tostring(mathFloor((computer.totalMemory()-computer.freeMemory())/1024)).." KB/"..tostring(mathCeil(computer.totalMemory()/1048576*10)/10).." MB"
end

local function readFromFile(path)
	local file = io.open(path, 'r')
	local array = {}
	for line in file:lines() do
		if line:sub(-1) == "\r" then
			line = line:sub(1, -2)
		end
		tableInsert(array, line)
	end
	file:close()
	return array
end

function game._function.getVersion()
	return "Версия "..game._function.version[1].."."..game._function.version[2].."."..game._function.version[3].." Обновление "..game._function.version[4]
end

local function writeLineToFile(path,strLine)
	local file = io.open(path, 'a')
	file:write(( strLine or "" ).."\n")
	file:close()
end

function game._function.logtxt(text)
	writeLineToFile(game._data.text.directory .. game._data.text.logFile, text)
end

--[[ Подмена функции ошибки ]]--
_G.error = function(text)
	game._data.inGame = false
	thread.killAll()
	local file = io.open(game._data.text.directory .. game._data.text.logFile, 'a')
	if type(text) == table then
		for i = 1, #text do
			file:write(( tostring(text[i]) or "" ).."\n")
		end
	else
		file:write(( tostring(text) or "" ).."\n")
	end
	file:close()
	os.sleep(1)
	gpu.setBackground(0x222222)
	gpu.setForeground(0xffffff)
	term.clear()
	term.setCursor(1,2)
	io.write("Текст ошибки сохранён в файл log.txt\n")
	io.write("Ошибка:\n")
	if type(text) == table then
	for i = 1, #text do
		io.write(tostring(text[i]).."\n")
	end
	else
		io.write(tostring(text).."\n")
	end
	_G.error = primaryError
	primaryError = nil
	gpu.setForeground(0xffffff)
	io.write("Для продолжения нажмите любую клавишу...")
	while true do
		local ev = table.pack(event.pull())
		if ev[1] == "key_down" then
			computer.shutdown(true)
			break
		end
	end
end

function game._function.dofile(path)
	local file = io.open(path)
	local h = file:read("*all")
	file:close()
	local success, err = pcall(load(h))
	if not success then
		game._function.logtxt(tostring(err))
	end
	return success
end

-- не работает
--[[
function game._function.doScript(file, ... )
	local path = game._data.text.directory.."lua/"..file
	if fs.exists(path) then
		local success, err = shell.execute(path, game._function, ... )
		if not success then
			game._function.logtxt(tostring(err))
		end
	else
		game._function.logtxt("Не существует файл "..path)
	end
end

]]

function game._function.assert(...)
	local result = true
	local args = table.pack(...)
	for f = 1, #args / 2, 2 do
		if type(args[f-1]) ~= args[f] then
			result = false
			game._function.logtxt(text)
		end
	end
	return result
end

function game._function.initResources()
	local nmlt = 1
	game._data.itemIcons = readFromFile(game._data.text.directory.."data/itempic.data")
	gud, gid, gqd, gsd, eusd, ged, baseWtype, lootdata = dofile(game._data.text.directory.."data/elements.data")
	world = dofile(game._data.text.directory.."data/levels.data")
	world.current = 1

	for f = 1, #world do
		world[f].draw = load("local buffer=require('E_doubleBuffering');return function() "..world[f].draw.." end")()
		if not savedUnits[f] then
			savedUnits[f] = {}
		end
	end

	for f = 1, #gud do
		if gud[f]["name"] == "" then
			gud[f]["name"] = "Без названия"
		end
		if gud[f]["loot"] and not gud[f]["loot"]["exp"] then
			gud[f]["loot"]["exp"] = gud[f]["lvl"] * 5
		end
		if f % 603 == 0 then
			computer.pullSignal(0)
		end
	end

	for f = 1, #gid do
		if gid[f]["props"] and type(gid[f]["props"]) == "table" and gid[f]["props"]["dds"] then
			gid[f]["name"] = string.rep("♦",#gid[f]["props"]["dds"])..gid[f]["name"]
		end

		if gid[f]["name"] == "" then
			gid[f]["name"] = "Без названия"
		end

		if gid[f]["type"] == 2 then -- Броня
			gid[f]["stackable"] = 0
			if gid[f]["nmlt"] then
				nmlt = tonumber(gid[f]["nmlt"])
			end
			if gid[f]["props"]["pdef"] == nil then
				gid[f]["props"]["pdef"] = mathCeil(9+gid[f]["lvl"]*game._data.armorPhysicalDefenceMultiple[gid[f]["subtype"]]*nmlt*mathMax((gid[f]["lvl"]^1.2/4),1))
			end
			if gid[f]["props"]["mdef"] == nil then
				gid[f]["props"]["mdef"] = mathCeil(9+gid[f]["lvl"]*game._data.armorMagicalDefenceMultiple[gid[f]["subtype"]]*nmlt*mathMax((gid[f]["lvl"]^1.2/4),1))
			end
		end

		if gid[f]["type"] == 3 then
			gid[f]["stackable"] = 0
		end

		nmlt = 1
		if f % 603 == 0 then
			computer.pullSignal(0)
		end
	end

	for f = 1, #playerParams[gud[game._player.id]["class"]]["skills"] do
		cPlayerSkills[f] = {}
		for n = 1, #playerParams[gud[game._player.id]["class"]]["skills"][f] do
			cPlayerSkills[f][n] = playerParams[gud[game._player.id]["class"]]["skills"][f][n]
		end
	end

	for f = 1, #gqd do
		gqd[f]["givingQuest"] = nil
		gqd[f]["comp"] = 0
	end

	game._data.maxItemID = #gid
end

local function clicked(x,y,x1,y1,x2,y2)
	if x >= x1 and x <= x2 and y >= y1 and y <= y2 then
		return true
	end
	return false
end

function game._function.random(n1,n2,accuracy)
	local ass = 10^(accuracy or 0)
	return game._function.roundupnum(math.random(n1*ass,n2*ass))/ass
end

function game._function.getBrailleChar(n1, n1, n3, n4, n5, n6, n7, n8)
	return unicode.char(10240+128*n8+64*n7+32*n6+16*n4+8*n1+4*n5+2*n3+n1)
end

function game._function.unicodeFrame(x,y,w,h,c)
	buffer.drawText(x,y,c,"┌")
	buffer.drawText(x+1,y,c,string.rep("─",w-2))
	buffer.drawText(x+w-1,y,c,"┐")
	for f = 1, h-2 do
		buffer.drawText(x,y+f,c,"│")
		buffer.drawText(x+w-1,y+f,c,"│")
	end
	buffer.drawText(x,y+h-1,c,"└")
	buffer.drawText(x+1,y+h-1,c,string.rep("─",w-2))
	buffer.drawText(x+w-1,y+h-1,c,"┘")
end

-- function game._function.scolorText(x,y,col,str)
-- local dsymb = "^"
-- local pcl, cs, f, s = col, "", 1, 1
 -- while f <= unicode.len(str) do
 -- cs = unicode.sub(str,f,f)
  -- if cs ~= dsymb then
  -- buffer.drawText(x-1+s,y,pcl,cs)
  -- f = f + 1
  -- s = s + 1
  -- elseif cs == dsymb then
   -- if unicode.sub(str,f+1,f+6) == "native" then
   -- pcl = col
   -- else
   -- pcl = tonumber("0x"..unicode.sub(str,f+1,f+6))
   -- end
  -- f = f + 7
  -- end
 -- end
-- end

function game._function.textWrap(text, limit) -- угадайте откуда взял
	if type(text) == "string" then text = {text} end
	local wrappedLines, result, preResult, preResultLength = {}
	for i = 1, #text do
		for subLine in text[i]:gmatch("[^\n]+") do
		result = ""
			for word in subLine:gmatch("[^%s]+") do
				preResult = result .. word
				preResultLength = unicode.len(preResult)
				if preResultLength > limit then
					if unicode.len(word) > limit then
						tableInsert(wrappedLines, unicode.sub(preResult, 1, limit))
						for i = limit + 1, preResultLength, limit do
							tableInsert(wrappedLines, unicode.sub(preResult, i, i + limit - 1))
						end
						result = wrappedLines[#wrappedLines] .. " "
						wrappedLines[#wrappedLines] = nil
					else
						result = result:gsub("%s+$", "")
						tableInsert(wrappedLines, result)
						result = word .. " "
					end
				else
					result = preResult .. " "
				end
			end
			result = result:gsub("%s+$", "")
			tableInsert(wrappedLines, result)
		end
	end
	return wrappedLines
end

function game._function.getDistance(from,x,y)
	local x1, y1 = CGD[from]["x"], CGD[from]["y"]
	if x1 + CGD[from]["width"] < x then
		x1 = x1 + CGD[from]["width"]
	end
	return mathFloor(math.sqrt((x1-x)^2+(y1-( y or 1))^2)*10)/10
end

function game._function.getDistanceToId(from,to)
	local dist = 0
	local x1, x2 = CGD[from]["x"], CGD[to]["x"]
	if x1 + CGD[from]["width"] < x2 then
		dist = x2 - x1 - CGD[from]["width"]
	elseif x1 > x2 + CGD[to]["width"] then
		dist = x1 - x2 - CGD[to]["width"]
	end
	return dist
end

local sScreenTimerw = false
local sScreenTimer1 = 0
local sScreenXValue = 1
local old_cgx, old_cbpos = cGlobalx, cBackgroundPos

local function setScreenXValue(x, time)
game._data.windowThread = "screen_save"
old_cgx, old_cbpos = cGlobalx, cBackgroundPos
sScreenTimerw = true
sScreenTimer1 = time
sScreenXValue = x
end

local function setScreenPosition(x)
local ncGlobalx, ncBackgroundPos = cGlobalx, cBackgroundPos
cGlobalx = x
cBackgroundPos = x
game._player.screenPosition = 75-game._function.getDistance(1,x)
end

local function setScreenNormalPosition(ncGlobalx, ncBackgroundPos)
game._player.screenPosition = 75
cGlobalx, cBackgroundPos = ncGlobalx, ncBackgroundPos
sScreenTimerw = false
game._data.windowThread = nil
end

local function setScreenNewPosition()
 if sScreenTimerw and sScreenXValue ~= nil then
  if sScreenTimer1 - 1 > 0 then
  setScreenPosition(sScreenXValue)
  else
  sScreenTimer1 = 0
  setScreenNormalPosition(old_cgx, old_cbpos)
  end
 end
end

function game._function.moveToward(id, x, distanceLimit, step)
	distanceLimit = distanceLimit or math.huge
	if math.abs(CGD[id]["x"] - x) >= step then
		if game._function.getDistance(id,x) < distanceLimit and x < CGD[id]["x"] then
			CGD[id]["x"] = CGD[id]["x"] - step
			CGD[id]["spos"] = 0
		elseif game._function.getDistance(id,x) < distanceLimit and x > CGD[id]["x"] then
			CGD[id]["x"] = CGD[id]["x"] + step
			CGD[id]["spos"] = 1
		end
	else
		CGD[id]["x"] = CGD[id]["mx"]
	end
end

function game._function.playerAutoMove(x, distanceLimit, step)
	local kx
	if game._function.getDistance(game._player.id,x) >= step and game._function.getDistance(game._player.id,x) < distanceLimit and x < CGD[game._player.id]["x"] then
		CGD[game._player.id]["spos"] = 0
		pmov = -step
	elseif game._function.getDistance(game._player.id,x) >= step and game._function.getDistance(game._player.id,x) < distanceLimit and x > CGD[game._player.id]["x"] then
		CGD[game._player.id]["spos"] = 1
		pmov = step
	elseif game._function.getDistance(game._player.id,x) < step then
		pmov = 0
		game._player.usepmx = false
		CGD[game._player.id]["x"] = x
		CGD[game._player.id]["mx"] = x
		cGlobalx = x
		cBackgroundPos = x
		CGD[game._player.id]["image"] = 0
	end
end

function game._function.roundupnum(num)
	local res
	if num - mathFloor(num) < 0.5 then
		res = mathFloor(num)
	else
		res = mathCeil(num)
	end
	return res
end

function game._function.getPlayerAtdsBySkill(skill)
	return ( vAttackDistance or 8 ) + gsd[cPlayerSkills[game._player.actSkills[skill]][1]]["distance"]
end

local function insertQuests(id,dialog)
local var, povar
local newDialog = dialog
local cQue = gud[CGD[id]["id"]]["quests"]
local insQuestDialog = true
 if type(cQue) == "table" and game._gui.NPCDialog.currentDialog["im"] ~= nil then
  povar = 1
  tableInsert(cQue,0)
  for n = 1, #dialog do
   if dialog[n]["action"] == "dialog" then
   insQuestDialog = false
   break
   end
  end
  if insQuestDialog then
  tableInsert(newDialog,1,{["dq"]=0,["text"]="Задания",["action"]="dialog",["do"] ={["text"]="Выберите любые доступные задания"}})
  end
  for f = 1, #cQue do
  var = true
   for q = 1, #game._player.quests do
    if game._player.quests[q][1] == cQue[f] and game._player.quests[q][3] then
     if CGD[game._player.id]["lvl"] < gqd[cQue[f]]["minlvl"] then
	 var = false
     break
	 end
    end
   end
   if var and cQue[f] > 0 and cQue[f] <= #gqd and newDialog[1]["dq"]~=nil then
   newDialog[1]["do"][povar] = {["q"]=cQue[f],["text"]=gqd[cQue[f]]["name"],["action"]="qdialog",
    ["do"] = {
		["text"]=( gqd[cQue[f]]["gtext"] or "Новое задание" ),
		{["text"]=( gqd[cQue[f]]["atext"] or "Я выполню это задание" ),["action"]="getquest",["do"]=cQue[f]},
		{["text"]=( gqd[cQue[f]]["rtext"] or "Не сейчас" ),["action"]="close",["do"]=nil}
		}
    }
   else
   newDialog[1]["do"][povar] = nil
   end
  povar = povar + 1
  end
  for f = 1, #game._player.quests do
   if game._player.quests[f][3] and CGD[CGD[game._player.id]["target"]]["id"] == gqd[game._player.quests[f][1]]["qr"] and newDialog[1]["dq"]~=nil then
   newDialog[1]["do"][#newDialog[1]["do"]+1] = {["text"]=gqd[game._player.quests[f][1]]["name"],["action"]="cmpquest",["do"]=game._player.quests[f][1]}
   else
   newDialog[1]["do"][#newDialog[1]["do"]+1] = nil
   end
  povar = povar + 1
  end
  if newDialog[1]["dq"]~=nil then
  newDialog[1]["do"][#newDialog[1]["do"]+1] = {["text"]="До встречи",["action"]="close",["do"]=nil}
  end
 end
return newDialog
end

function game._function.showMessage1(msg)
	tableInsert(game._data.messageTable1, msg)
	game._data.messageTable1timer = 10
end

local sMSG2, smsg2time = {""}, 0

function game._function.showMapName(msg)
tableInsert(sMSG2,msg)
smsg2time = 5
end

local sMSG3 = ""

function game._function.textmsg3(msg)
sMSG3 = msg
end

local sMSG4, smsg4time = {"","",""}, 0

function game._function.textmsg4(msg)
tableInsert(sMSG4,msg)
if #sMSG4 > 3 then tableRemove(sMSG4,1) end
smsg4time = 5
end

local sMSG5, smsg5time = {}, 0

function game._function.textmsg5(msg)
smsg5time = 20
tableInsert(sMSG5,msg)
end

local consoleArray = {}

local function booleanToString(b)
	if b then
		return "true"
	end
	return "false"
end

game._function.console={}
--[[
function game._function.console.debug(...)
local args = table.pack(...)
local msg, adt = "", ""
 if #args > 0 then
  for f = 1, #args do
   if type(args[f]) == "string" then
   adt = args[f]
   elseif type(args[f]) == "number" then
   adt = tostring(args[f])
   elseif type(args[f]) == "boolean" then
   adt = booleanToString(args[f])
   else
   adt = type(args[f])
   end
  msg = msg..adt.." "
  end
 end
tableInsert(consoleArray,msg)
if #consoleArray > 30 then tableRemove(consoleArray,1) end
end
]]--

function game._function.console.wError(e)
	if type(e) == "string" then tableInsert(consoleArray,"!/"..e) end
end

-- Обновить характеристики юнитов
function game._function.updateUnitStats(uid)

	local function unitHpCalc(lvl)
		return 36 + (lvl - 1) * 34.3 + (((lvl - 1) ^ 2 - 1) / 2) * math.max((lvl - 1) / 10, 1) * (0.85 + 1 / lvl ^ (1 / lvl))
	end

	local id, level = CGD[uid]["id"], CGD[uid]["lvl"]

	local pmul, mmul
	if not gud[id]["dtype"] then
		pmul, mmul = 1, 1
	elseif gud[id]["dtype"] == 1 then
		pmul = 1 + 0.01 * (50 / math.sqrt(level))
		mmul = 1 - 0.01 * (50 / math.sqrt(level))
	elseif gud[id]["dtype"] == 2 then
		pmul = 1 - 0.01 * (50 / math.sqrt(level))
		mmul = 1 + 0.01 * (50 / math.sqrt(level))
	end

	-- физдеф
	CGD[uid]["pdef"] = mathCeil((level*17.84+((level-1)^2.2))*( pmul + ( gud[id]["pdefmul"] or 0 ) ) )
	-- магдеф
	CGD[uid]["mdef"] = mathCeil((level*16.55+((level-1)^2.2))*( mmul + ( gud[id]["mdefmul"] or 0 ) ) )
	-- физ атака
	CGD[uid]["ptk"] = {
		mathCeil(((1+level^1.22)*(1+1/level^(1/level)))*pmul),
		mathCeil(((3+level^1.34)*(1+1/level^(1/level)))*pmul)
	}
	-- маг атака
	CGD[uid]["mtk"] = {
		mathCeil((1+level^1.18)*(1+1/level^(1/level))*mmul),
		mathCeil((3+level^1.35)*(1+1/level^(1/level))*mmul)
	}
	-- макс жс
	CGD[uid]["mhp"] = gud[id]["mhp"] or mathCeil(unitHpCalc(level) * (gud[id]["hpmul"] or 1))
	-- if gud[id]["hpmul"] then
	-- CGD[uid]["mhp"] = mathCeil(CGD[uid]["mhp"] * gud[id]["hpmul"])
	-- end
end

-- Функция, чтобы поставить параметры мобов по умолчанию
function game._function.defaultUnitStats(f)
	-- физдеф
	CGD[f]["pdef"] = gud[CGD[f]["id"]]["pdef_con"] or CGD[f]["pdef"] or 0
	-- магдеф
	CGD[f]["mdef"] = gud[CGD[f]["id"]]["mdef_con"] or CGD[f]["mdef"] or 0
	-- физ атака
	if gud[CGD[f]["id"]]["ptk_con"] then
		CGD[f]["ptk"] = gud[CGD[f]["id"]]["ptk_con"]
	else
		CGD[f]["ptk"] = CGD[f]["ptk"] or {0,0}
	end
	 -- маг атака
	if gud[CGD[f]["id"]]["mtk_con"] then
		CGD[f]["mtk"] = gud[CGD[f]["id"]]["mtk_con"]
	else
		CGD[f]["mtk"] = CGD[f]["mtk"] or {0,0}
	end
	 -- макс жс
	--CGD[f]["mhp"] = gud[CGD[f]["id"]]["mhp_con"] or CGD[f]["mhp"] or 0 -- БАГ
end

-- Создать нового юнита на карте
function game._function.addUnit(id, x, y)
	CGD[#CGD+1] = {}
	local new, unitSprite = #CGD
	CGD[new]["sx"] = x
	CGD[new]["mx"] = x
	CGD[new]["x"] = x
	CGD[new]["y"] = y
	CGD[new]["id"] = gud[id]["id"]
	CGD[new]["lvl"] = gud[id]["lvl"]
	CGD[new]["spos"] = 1
	CGD[new]["image"] = 0
	if CGD[new]["image"] ~= nil then
		unitSprite = image.load(game._data.text.directory.."sprpic/"..gud[id]["image"]..".pic")
		CGD[new]["width"] = unitSprite[1]
		CGD[new]["height"] = unitSprite[2]
	end
	unitSprite = nil
	CGD[new]["pdef"] = 0
	CGD[new]["mdef"] = 0
	CGD[new]["resptime"] = 0
	CGD[new]["living"] = true
	CGD[new]["cmove"] = true
	CGD[new]["ctck"] = true
	CGD[new]["rtype"] = gud[id]["rtype"]
	CGD[new]["target"] = nil
	CGD[new]["tlinfo"] = {}
	if gud[id]["rtype"] == "f" then
		CGD[new]["dialog"] = gud[id]["dialog"]
	end
	CGD[new]["effects"] = {}
	
	-- Можно установить постоянные характеристики
	if (id ~= 1 and gud[CGD[new]["id"]]["rtype"] == "e" or gud[CGD[new]["id"]]["rtype"] == "p") and new ~= game._player.id then
		local idd = CGD[new]["id"]
		game._function.updateUnitStats(new)
		-- физдеф
		if not gud[idd]["pdef"] then
			gud[idd]["pdef_con"] = CGD[new]["pdef"] or 0
		else
			gud[idd]["pdef_con"] = gud[idd]["pdef"]
		end
		-- магдеф
		if not gud[idd]["mdef"] then
			gud[idd]["mdef_con"] = CGD[new]["mdef"] or 0
		else
			gud[idd]["mdef_con"] = gud[idd]["mdef"]
		end
		-- физ атака
		if not gud[idd]["ptk"] then
			gud[idd]["ptk_con"] = CGD[new]["ptk"] or 0
		else
			gud[idd]["ptk_con"] = gud[idd]["ptk"]
		end
		-- маг атака
		if not gud[idd]["mtk"] then
			gud[idd]["mtk_con"] = CGD[new]["mtk"] or 0
		else
			gud[idd]["mtk_con"] = gud[idd]["mtk"]
		end
		-- макс жс
		if not gud[idd]["mhp"] then
			gud[idd]["mhp_con"] = CGD[new]["mhp"] or 0
		else
			gud[idd]["mhp_con"] = gud[idd]["mhp"]
		end
	end
	game._function.defaultUnitStats(new)
	CGD[new]["chp"] = CGD[new]["mhp"]
	--game._function.console.debug("Добавление","id:"..tostring(gud[id]["id"]),"имя:"..gud[id]["name"],"x:"..tostring(x),"y:"..tostring(y),"Gid:"..#CGD)
	return new
end

--game._function.console.wError(game._data.text.warning)

--game._function.console.debug("Загрузка ("..unicode.sub(os.date(), 1, -4)..")")

-- инвентарь полный / не полный
function game._function.checkInventoryisFull()
	local full = true
	for f = 1, #CGD[game._player.id]["inventory"]["bag"] do
		if CGD[game._player.id]["inventory"]["bag"][f][2] == 0 then full = false end
	end
	return full
end

-- место в инвентаре, 0 = полный
function game._function.checkInventorySpace()
	local space = 0
	for f = 1, #CGD[game._player.id]["inventory"]["bag"] do
		if CGD[game._player.id]["inventory"]["bag"][f][1] == 0 then space = space + 1 end
	end
	return space
end

local lostItem

function game._function.addItem(itemid, num, indicate)
	local vparInvEx = 0
	local position = 0
	-- удалить ошибочные значения
	for f = 1, #CGD[game._player.id]["inventory"]["bag"] do
		if CGD[game._player.id]["inventory"]["bag"][f][2] == 0 then
			CGD[game._player.id]["inventory"]["bag"][f][1] = 0
			if CGD[game._player.id]["inventory"]["bag"][f][1] >= game._config.reservedItemId then
				gid[CGD[game._player.id]["inventory"]["bag"][f][1]] = nil
			end
			iconImageBuffer[f] = nil
		end
	end
	-- Добавить нестакающийся предмет
	if gid[itemid] and not gid[itemid]["stack"] then
		for f = 1, #CGD[game._player.id]["inventory"]["bag"] do
			if CGD[game._player.id]["inventory"]["bag"][f][1] == 0 then
				vparInvEx = 1
				CGD[game._player.id]["inventory"]["bag"][f][1] = itemid
				CGD[game._player.id]["inventory"]["bag"][f][2] = num
				if game._data.windowThread == "inventory" then
					iconImageBuffer[f] = image.load(game._data.text.directory.."itempic/"..game._data.itemIcons[gid[CGD[game._player.id]["inventory"]["bag"][f][1]]["icon"]]..".pic")
				end
				position = f
				break
			end
		end
	end
	-- Добавить стакающийся предмет
	if gid[itemid] and gid[itemid]["stack"] and vparInvEx == 0 then
		for i = 1, #CGD[game._player.id]["inventory"]["bag"] do
			-- Сгруппировать одинаковые
			if CGD[game._player.id]["inventory"]["bag"][i][1] == itemid then
				CGD[game._player.id]["inventory"]["bag"][i][2] = CGD[game._player.id]["inventory"]["bag"][i][2] + num
				vparInvEx = 1
				position = i
				break
			end
		end
		if vparInvEx == 0 then
		for i = 1, #CGD[game._player.id]["inventory"]["bag"] do
			if CGD[game._player.id]["inventory"]["bag"][i][1] == 0 or CGD[game._player.id]["inventory"]["bag"][i][2] == 0 then
				CGD[game._player.id]["inventory"]["bag"][i][1] = itemid
				CGD[game._player.id]["inventory"]["bag"][i][2] = num
					vparInvEx = 1
					if game._data.windowThread == "inventory" then
						iconImageBuffer[i] = image.load(game._data.text.directory.."itempic/"..game._data.itemIcons[gid[CGD[game._player.id]["inventory"]["bag"][i][1]]["icon"]]..".pic")
					end
					position = i
					break
				end
			end
		end
	end
	-- Переполнение
	if vparInvEx == 0 and game._function.checkInventoryisFull() then
		lostItem = {itemid,num}
		game._function.showMessage1("Инвентарь переполнен!")
	else
		if indicate then
			game._function.showMessage1("Получен предмет \""..gid[itemid]["name"].."\" " .. num .. " шт.")
		end
	end
	-- Нестакающиеся предметы
	for f = 1, #CGD[game._player.id]["inventory"]["bag"] do
		if CGD[game._player.id]["inventory"]["bag"][f][1] ~= 0 and gid[CGD[game._player.id]["inventory"]["bag"][f][1]] and not gid[CGD[game._player.id]["inventory"]["bag"][f][1]]["stackable"] and CGD[game._player.id]["inventory"]["bag"][f][2] > 1 then
			CGD[game._player.id]["inventory"]["bag"][f][2] = 1
		end
	end
	return position
end

local function removeItemFromInventory(invid, count)
	count = count or 1
	if CGD[game._player.id]["inventory"]["bag"][invid][2] > 1 then
		CGD[game._player.id]["inventory"]["bag"][invid][2] = CGD[game._player.id]["inventory"]["bag"][invid][2] - count
	else
		CGD[game._player.id]["inventory"]["bag"][invid] = {0,0}
	end
end

function game._function.removeItem(iid, count) -- вернёт 'true' если нет такого количества

	count = count or 1

	local num = 0

	local i = count

	for f = 1, #CGD[game._player.id]["inventory"]["bag"] do
		if CGD[game._player.id]["inventory"]["bag"][f][1] == iid then
			num = num + CGD[game._player.id]["inventory"]["bag"][f][2]
		end
	end

	if num >= count then
		for f = 1, #CGD[game._player.id]["inventory"]["bag"] do
			if CGD[game._player.id]["inventory"]["bag"][f][1] == iid then
				if CGD[game._player.id]["inventory"]["bag"][f][2] > i then
					removeItemFromInventory(f, CGD[game._player.id]["inventory"]["bag"][f][2])
					i = i - CGD[game._player.id]["inventory"]["bag"][f][2]
				else
					removeItemFromInventory(f, count)
					break
				end
			end
		end
	else
		return true
	end
end

-- Перемешать значения массива
local function getMixedSequence(massiv)
	local new = massiv
	local rand1, rand2, b
	for f = 1, #new do
		rand1 = game._function.random(1,#new)
		rand2 = game._function.random(1,#new)
		b = new[rand1]
		new[rand1] = new[rand2]
		new[rand2] = b
	end
	return new
end

-- Дополнительные характеристики предмета
local function createNewItem(itemID)
	local newItemID, hu = -1, 0
	
	while true do
		if not gid[game._config.reservedItemId + hu] then
			newItemID = game._config.reservedItemId + hu break
		end
		hu = hu + 1
	end
	if gid[itemID]["type"] == 2 or gid[itemID]["type"] == 3 then
		gid[newItemID] = {}
		for k, _ in pairs(gid[itemID]) do
		gid[newItemID][k] = gid[itemID][k]
		end
		gid[newItemID]["props"] = {["dds"]={}}
		for k, _ in pairs(gid[itemID]["props"]) do
			gid[newItemID]["props"][k] = gid[itemID]["props"][k]
		end

		local level = gid[itemID]["lvl"]
		local props = {
			[1]={"hp+",
				["min"] = 4+level^2,
				["max"] = 5+level^2*3,
				[3] = 10 + level*2, -- %
				[2] = 80 + level*2 -- %
				},
			[2]={"sur+",
				["min"] = mathCeil(level/2),
				["max"] = level,
				[3] = 40 + level*2,
				[2] = 50 + level*2
				},
			[3]={"str+",
				["min"] = mathCeil(level/2),
				["max"] = level,
				[3] = 40 + level*2,
				[2] = 50 + level*2
				},
			[4]={"int+",
				["min"] = mathCeil(level/2),
				["max"] = level,
				[3] = 40  + level*2,
				[2] = 50 + level*2
				},
			[5]={"pdm+",
				["min"] = 2+level*6+(level-3),
				["max"] = 2+level^1.2*8+(level-3),
				[3] = 60 + level*2,
				[2] = 0,
				["sub"] = {1,2,3}
				},
			[6]={"mdm+",
				["min"] = 2+level*6+(level-3),
				["max"] = 2+level^1.2*8+(level-3),
				[3] = 60 + level*2,
				[2] = 0,
				["sub"] = {4}
				},
			[7]={"pdf+",
				["min"] = 5+(level-1)^2*3,
				["max"] = 5+(level-1)^2*5,
				[3] = 0,
				[2] = 30 + level*2
				},
			[8]={"mdf+",
				["min"] = 5+(level-1)^2*3,
				["max"] = 5+(level-1)^2*5,
				[3] = 0,
				[2] = 30 + level*2
				},
			[9]={"mp+",
				["min"] = 4+level^2,
				["max"] = 5+level^2*2,
				[3] = 2 + level*2, -- %
				[2] = 20 + level*2 -- %
				},
			[10]={"chc+",
				["min"] = 1,
				["max"] = 2,
				[3] = 10,
				[2] = 5
				},
			[11]={"hp%",
				["min"] = 5,
				["max"] = 5,
				[3] = 0, -- %
				[2] = level-1 -- %
				},
			[12]={"mp%",
				["min"] = 5,
				["max"] = 5,
				[3] = 0, -- %
				[2] = level-1 -- %
				},
			[13]={"hp%",
				["min"] = 10,
				["max"] = 10,
				[3] = 0, -- %
				[2] = mathMax(level-2,0) -- %
				},
			[14]={"mp%",
				["min"] = 10,
				["max"] = 10,
				[3] = 0, -- %
				[2] = mathMax(level-2,0) -- %
				},
		}

		-- Количество звёзд: 0-5
		local ddch, adnum, newDds = {100,45,7.5,1,0.15}, 1, {}
		local addThisProp, dt, value

		for f = 1, 5 do
			if game._function.random(1, 10^6) / 10^4 <= ddch[6 - f] then
				adnum = 6 - f
				break
			end
		end

		while #newDds < mathMin(adnum,gid[itemID]["lvl"]) do
			addThisProp = false
			dt = game._function.random(1, #props)
			if game._function.random(1, 10^5) <= props[dt][gid[itemID]["type"]] * 10^3 then
				value = mathFloor(game._function.random(props[dt]["min"] * 10, props[dt]["max"] * 10) / 10)
				if props[dt]["sub"] then
					for j = 1, #props[dt]["sub"] do
						if gid[itemID]["subtype"] == props[dt]["sub"][j] then
							addThisProp = true
						end
					end
				elseif value >= 1 then
					addThisProp = true
				end
				if addThisProp then
					tableInsert(newDds, {props[dt][1], mathFloor(value)})
				end
			end
		end


		for r = 1, #newDds-1 do
			if gid[newItemID]["type"] == 3 and not gid[newItemID]["cchg"] then
				if gid[newItemID]["props"]["phisat"] then
					gid[newItemID]["props"]["phisat"][1] = mathFloor(gid[newItemID]["props"]["phisat"][1]*1.1)
					gid[newItemID]["props"]["phisat"][2] = mathFloor(gid[newItemID]["props"]["phisat"][2]*1.1)
				end
				if gid[newItemID]["props"]["magat"] then
					gid[newItemID]["props"]["magat"][1] = mathFloor(gid[newItemID]["props"]["magat"][1]*1.1)
					gid[newItemID]["props"]["magat"][2] = mathFloor(gid[newItemID]["props"]["magat"][2]*1.1)
				end
			elseif gid[newItemID]["type"] == 2 and not gid[newItemID]["cchg"] then
				if gid[newItemID]["props"]["pdef"] then
					gid[newItemID]["props"]["pdef"] = mathFloor(gid[newItemID]["props"]["pdef"]*1.23)
				end
				if gid[newItemID]["props"]["mdef"] then
					gid[newItemID]["props"]["mdef"] = mathFloor(gid[newItemID]["props"]["mdef"]*1.23)
				end
			end
		end

		if not gid[itemID]["ncolor"] then
			if #newDds > 0 and #newDds < 3 then gid[newItemID]["ncolor"] = cp.blue
			elseif #newDds == 3 then gid[newItemID]["ncolor"] = cp.magenta
			elseif #newDds == 4 then gid[newItemID]["ncolor"] = cp.orange
			elseif #newDds >= 5 then gid[newItemID]["ncolor"] = cp.green
			end
		end

		gid[newItemID]["props"]["dds"] = newDds
		gid[newItemID]["name"] = string.rep("♦",mathMin(#newDds,5))..gid[newItemID]["name"]
		gid[newItemID]["cost"] = gid[itemID]["cost"] + mathCeil(gid[itemID]["cost"]/2*mathMin(#gid[newItemID]["props"]["dds"],5))
		gid[newItemID]["oid"] = itemID
		gid[newItemID]["id"] = newItemID
		if #newDds == 0 or gid[itemID]["cchg"] then
			gid[newItemID] = nil
			return itemID
		else
			game._data.maxItemID = newItemID
		end
		else
		return itemID
	end
	return newItemID
end

-- Наложить эффект (усиление / ослабление, т.д.)
function game._function.addUnitEffect(uID, eID, lvl, source)
	local var = true
	if uID and eID and lvl and eID >= 1 and eID <= #ged then
		for eff = 1, #CGD[uID]["effects"] do
			if CGD[uID]["effects"][eff][1] == eID then
				CGD[uID]["effects"][eff][2] = ged[eID]["dur"][lvl]
				var = false
				break
			end
		end
		if var then
			tableInsert(CGD[uID]["effects"],{eID, ged[eID]["dur"][lvl], lvl, source})
		end
	else
		game._function.logtxt("addUnitEffect: ошибка данных")
	end
end

-- Табличка с уроном над головой
function game._function.addUnitHitInfo(u,text)
	tableInsert(CGD[u]["tlinfo"],text)
end

-- Поиск предмета itemid в инвентаре
function game._function.checkItemInBag(itemid)
	local d = 0
	for f = 1, #CGD[game._player.id]["inventory"]["bag"] do
		if CGD[game._player.id]["inventory"]["bag"][f][1] == itemid then
			d = d + CGD[game._player.id]["inventory"]["bag"][f][2]
		end
	end
	return d, itemid
end

function game._function.setAllValuesInArrayTo(tabli,value)
	local t = {}
	for k, v in pairs(tabli) do
		t[k] = value
	end
	return t
end

local gitypesNames = {
	["helmet"]="Голова",
	["pendant"]="Украшение",
	["armor"]="Броня",
	["pants"]="Штаны",
	["footwear"]="Обувь",
	["robe"]="Накидка",
	["ring"]="Кольцо",
	["weapon"]="Оружие",
}

function game._function.getWitemTypeName(subtype)
return gitypesNames[subtype] or ""
end

-- Функция, чтобы подсчитать характеристики (атака, защита, т.д.)

function game._function.UpdatePlayerStats()
	game._data.updatedPlayerStats = game._function.setAllValuesInArrayTo(game._data.updatedPlayerStats, 0)
	local temp, critRate
	-- Суммирование защиты от снаряжения --
	for k, _ in pairs(CGD[game._player.id]["inventory"]["weared"]) do
		if CGD[game._player.id]["inventory"]["weared"][k] ~= 0 and gid[CGD[game._player.id]["inventory"]["weared"][k]]["props"]["dds"] then
		temp = gid[CGD[game._player.id]["inventory"]["weared"][k]]["props"]["dds"]
			for e = 1, #temp do
				game._data.updatedPlayerStats[temp[e][1]] = game._data.updatedPlayerStats[temp[e][1]] + temp[e][2]
			end
		end
		if CGD[game._player.id]["inventory"]["weared"][k] ~= 0 and gid[CGD[game._player.id]["inventory"]["weared"][k]]["type"] == 2 then
			game._data.updatedPlayerStats["pdf+"] = game._data.updatedPlayerStats["pdf+"] + gid[CGD[game._player.id]["inventory"]["weared"][k]]["props"]["pdef"]
			game._data.updatedPlayerStats["mdf+"] = game._data.updatedPlayerStats["mdf+"] + gid[CGD[game._player.id]["inventory"]["weared"][k]]["props"]["mdef"]
		end
	end
    -- Суммирование пассивных умений
	local usingWeapon = false
	local skillLevel
	for f = 1, #cPlayerSkills do
		skillLevel = cPlayerSkills[f][3]
		if gsd[cPlayerSkills[f][1]]["type"] == 2 and gsd[cPlayerSkills[f][1]]["action"].weaponreq then
			for w = 1, #gsd[cPlayerSkills[f][1]]["action"].weaponreq do
				if CGD[game._player.id]["inventory"]["weared"]["weapon"] ~= 0 and
							gid[CGD[game._player.id]["inventory"]["weared"]["weapon"]]["subtype"] == gsd[cPlayerSkills[f][1]]["action"].weaponreq then
					usingWeapon = true
				end
			end
		else
			usingWeapon = true
		end

		if skillLevel > 0 and gsd[cPlayerSkills[f][1]]["type"] == 2 and game._data.updatedPlayerStats[gsd[cPlayerSkills[f][1]]["action"].etype] ~= nil
					and usingWeapon == true then
			game._data.updatedPlayerStats[gsd[cPlayerSkills[f][1]]["action"].etype] = game._data.updatedPlayerStats[gsd[cPlayerSkills[f][1]]["action"].etype] + gsd[cPlayerSkills[f][1]]["value"][skillLevel]
		end
	end
 ----
	critRate = 1 + mathFloor((CGD[game._player.id]["strg"]+game._data.updatedPlayerStats["str+"]) / 10)
	critRate = critRate + mathFloor((CGD[game._player.id]["int"]+game._data.updatedPlayerStats["int+"]) / 10)
	critRate = critRate + mathFloor((CGD[game._player.id]["agi"]+game._data.updatedPlayerStats["agi+"]) / 5)

	game._data.updatedPlayerStats["vPdm1"] = game._data.updatedPlayerStats["vPdm1"] + game._data.updatedPlayerStats["pdm+"]
	game._data.updatedPlayerStats["vPdm2"] = game._data.updatedPlayerStats["vPdm2"] + game._data.updatedPlayerStats["pdm+"]
	game._data.updatedPlayerStats["vMdm1"] = game._data.updatedPlayerStats["vMdm1"] + game._data.updatedPlayerStats["mdm+"]
	game._data.updatedPlayerStats["vMdm2"] = game._data.updatedPlayerStats["vMdm2"] + game._data.updatedPlayerStats["mdm+"]

	if CGD[game._player.id]["inventory"]["weared"]["weapon"] > 0 then
		if gid[CGD[game._player.id]["inventory"]["weared"]["weapon"]]["props"]["phisat"] then
			game._data.updatedPlayerStats["vPdm1"] = game._data.updatedPlayerStats["vPdm1"] + gid[CGD[game._player.id]["inventory"]["weared"]["weapon"]]["props"]["phisat"][1]*(1+game._data.updatedPlayerStats["pwd%"]*0.01)
			game._data.updatedPlayerStats["vPdm2"] = game._data.updatedPlayerStats["vPdm2"] + gid[CGD[game._player.id]["inventory"]["weared"]["weapon"]]["props"]["phisat"][2]*(1+game._data.updatedPlayerStats["pwd%"]*0.01)
		end
		if gid[CGD[game._player.id]["inventory"]["weared"]["weapon"]]["props"]["magat"] then
			game._data.updatedPlayerStats["vMdm1"] = game._data.updatedPlayerStats["vMdm1"] + gid[CGD[game._player.id]["inventory"]["weared"]["weapon"]]["props"]["magat"][1]*(1+game._data.updatedPlayerStats["mwd%"]*0.01)
			game._data.updatedPlayerStats["vMdm2"] = game._data.updatedPlayerStats["vMdm2"] + gid[CGD[game._player.id]["inventory"]["weared"]["weapon"]]["props"]["magat"][2]*(1+game._data.updatedPlayerStats["mwd%"]*0.01)
		end
		game._data.updatedPlayerStats["weaponDistance"] = game._function.watds[gid[CGD[game._player.id]["inventory"]["weared"]["weapon"]]["subtype"]]
		gsd[1]["reloading"] = weaponHitRate[gid[CGD[game._player.id]["inventory"]["weared"]["weapon"]]["subtype"]] or 1
	end

	game._player.statsPoints.vSur = game._data.updatedPlayerStats["sur+"]
	game._player.statsPoints.vStr = game._data.updatedPlayerStats["str+"]
	game._player.statsPoints.vInt = game._data.updatedPlayerStats["int+"]
	game._player.statsPoints.vAgi = game._data.updatedPlayerStats["agi+"]
	game._player.statsPoints.vPdm1 = game._data.updatedPlayerStats["vPdm2"]
	game._player.statsPoints.vMdm1 = game._data.updatedPlayerStats["vMdm1"]
	game._player.statsPoints.vPdm2 =game._data.updatedPlayerStats["vPdm2"]
	game._player.statsPoints.vMdm2 = game._data.updatedPlayerStats["vMdm2"]

	CGD[game._player.id]["mhp"] = mathCeil(((playerParams[CGD[game._player.id]["class"]]["basehp"]+(CGD[game._player.id]["surv"]+game._data.updatedPlayerStats["sur+"])*playerParams[CGD[game._player.id]["class"]]["surhpmul"]+(CGD[game._player.id]["lvl"]-1)*playerParams[CGD[game._player.id]["class"]]["levelhpmul"]+game._data.updatedPlayerStats["hp+"]))*(1+game._data.updatedPlayerStats["hp%"]/100))
	CGD[game._player.id]["mmp"] = mathCeil(((playerParams[CGD[game._player.id]["class"]]["basemp"]+(CGD[game._player.id]["int"]+game._data.updatedPlayerStats["int+"])*playerParams[CGD[game._player.id]["class"]]["intmpmul"]+(CGD[game._player.id]["lvl"]-1)*playerParams[CGD[game._player.id]["class"]]["levelmpmul"]+game._data.updatedPlayerStats["mp+"]))*(1+game._data.updatedPlayerStats["mp%"]/100))

	local pAttackBase = 1+(4*(CGD[game._player.id]["strg"]+game._data.updatedPlayerStats["str+"])+(CGD[game._player.id]["agi"]+game._data.updatedPlayerStats["agi+"]))/100
	local mAttackBase = 1+(4*(CGD[game._player.id]["int"]+game._data.updatedPlayerStats["int+"])+(CGD[game._player.id]["agi"]+game._data.updatedPlayerStats["agi+"]))/100
	CGD[game._player.id]["ptk"] = {
		mathFloor(1+pAttackBase*(CGD[game._player.id]["lvl"]+game._data.updatedPlayerStats["vPdm1"])),
		mathCeil(1+pAttackBase*(CGD[game._player.id]["lvl"]+game._data.updatedPlayerStats["vPdm2"]))
	}
	CGD[game._player.id]["mtk"] = {
		mathFloor(1+mAttackBase*(CGD[game._player.id]["lvl"]+game._data.updatedPlayerStats["vMdm1"])),
		mathCeil(1+mAttackBase*(CGD[game._player.id]["lvl"]+game._data.updatedPlayerStats["vMdm2"]))
	}
	CGD[game._player.id]["pdef"] = mathFloor(30+((CGD[game._player.id]["surv"]+game._data.updatedPlayerStats["sur+"])/2+(CGD[game._player.id]["strg"]+game._data.updatedPlayerStats["str+"])/4)*(CGD[game._player.id]["lvl"]+game._data.updatedPlayerStats["pdf+"]/2))
	CGD[game._player.id]["armorpdef"] = game._data.updatedPlayerStats["pdf+"]
	CGD[game._player.id]["mdef"] = mathFloor(30+((CGD[game._player.id]["surv"]+game._data.updatedPlayerStats["sur+"])/2+(CGD[game._player.id]["int"]+game._data.updatedPlayerStats["int+"])/4)*(CGD[game._player.id]["lvl"]+game._data.updatedPlayerStats["mdf+"]/2))
	CGD[game._player.id]["armormdef"] = game._data.updatedPlayerStats["mdf+"]
	CGD[game._player.id]["cmove"] = true
	CGD[game._player.id]["ctck"] = true
	CGD[game._player.id]["criticalhc"] = game._data.updatedPlayerStats["chc+"] + critRate
	vAttackDistance = game._data.updatedPlayerStats["weaponDistance"]
end

function game._function.maxXP()
	local reqxp = 0
	for e = 1, CGD[game._player.id]["lvl"] do
		if e <= 15 then
			reqxp = mathFloor(reqxp + reqxp*(2/e) + 50*e^(1/e))
		elseif e > 15 and e < 30 then
			reqxp = mathFloor(reqxp + reqxp*(3/e) + 52*e^(1/e))
		elseif e >= 30 then
			reqxp = mathFloor(reqxp + reqxp*(4/e) + 54*e^(1/e))
		end
	end
	CGD[game._player.id]["mxp"] = mathMax(reqxp,1)
end

local function addXP(value)
	local xpPlus, limit, i = value or 0, 99, 0
	while i <= limit do
		game._function.maxXP()
		if xpPlus <= CGD[game._player.id]["mxp"] - CGD[game._player.id]["cxp"] then
			CGD[game._player.id]["cxp"] = CGD[game._player.id]["cxp"] + xpPlus
			break
		else
			xpPlus = xpPlus - (CGD[game._player.id]["mxp"] - CGD[game._player.id]["cxp"])
			CGD[game._player.id]["cxp"] = 0
			CGD[game._player.id]["levelpoints"] = CGD[game._player.id]["levelpoints"] + 2
			CGD[game._player.id]["lvl"] = CGD[game._player.id]["lvl"] + 1
			game._function.showMessage1("Получен уровень " .. CGD[game._player.id]["lvl"])
			game._function.UpdatePlayerStats()
			CGD[game._player.id]["chp"] = CGD[game._player.id]["mhp"]
			CGD[game._player.id]["cmp"] = CGD[game._player.id]["mmp"]
			i = i + 1
		end
	end
	if game._data.windowThread == nil and value ~= nil and value > 0 then
		game._function.textmsg4("Опыт +"..value)
	end
end

-- Добавить денег
function game._function.addCoins(value)
	CGD[game._player.id]["cash"] = mathMax(CGD[game._player.id]["cash"] + value, 0)
	if game._data.windowThread == nil and value ~= nil and value > 0 then
		game._function.textmsg4("Монеты +"..value.."("..CGD[game._player.id]["cash"]..")")
	end
end

-- Добавить здоровье
function game._function.addHealth(id, value)
	if CGD[id]["chp"] + value < CGD[id]["mhp"] then
		CGD[id]["chp"] = CGD[id]["chp"] + value
	else
		CGD[id]["chp"] = CGD[id]["mhp"]
	end
end

-- Получить задание
function game._function.getQuest(quest)
	tableInsert(game._player.quests,{quest,0,false})
	if type(gqd[quest]["targ"]) == "table" then
		game._player.quests[#game._player.quests][2] = {}
		for f = 1, #gqd[quest]["targ"] do
			game._player.quests[#game._player.quests][2][f] = 0
		end
	end
end

function game._function.levelLoadingScreen()
	local pScreenText = "(C) 2016-2022 Wirthe16"
	buffer.drawRectangle(1,1,160,50,startBckgColour, 0, " ")
	buffer.drawText(2,2,0xA7A7A7,game._data.text.screen1)
	buffer.drawText(2,4,0xA7A7A7,world[world.current].name)
	buffer.drawText(158-unicode.len(game._function.getVersion()),48,0xA1A1A1,game._function.getVersion())
	buffer.drawText(158-unicode.len(pScreenText),49,0xB1B1B1,pScreenText)
	creditsInfoPrint()
	buffer.drawChanges()
	if gotCriticalError then
		buffer.drawText(2,mathFloor(mxh/2),0xD80000,"Предупреждение:" .. game._data.text.warning)
		buffer.drawText(2,mathFloor(mxh/2)+1,0xD80000,"Продолжить загрузку? Y/N")
		buffer.drawChanges()
		while true do
			local ev = table.pack(event.pull())
			if ev[1] == "key_up" then
				if ev[4] == 21 then
					break
				elseif ev[4] == 49 or ev[4] == 28 then
					error("Отмена")
				end
			end
		end
	end
	buffer.drawChanges()
end

-- Оптимизация буфера, изображение загружается только при необходимости
local function setImage(unitID)
	local loadNewImage = true
	for e = 1, #bufferenv do
		if bufferenv[e][1] == gud[unitID]["image"] then
			loadNewImage = false
			return bufferenv[e][2]
		end
	end
	if loadNewImage then
		imageBuffer[#imageBuffer+1] = image.load(game._data.text.directory.."sprpic/"..gud[unitID]["image"]..".pic")
		tableInsert(bufferenv,{gud[unitID]["image"],#imageBuffer})
		return #imageBuffer
	end
end

local function saveUnitData()
	local function isAvailable(id)
	local a = true
		if id == game._player.id then a = false end
		if CGD[id]["id"] == 43 then a = false end
		if CGD[game._player.id]["followers"] then
			for f = 1, #CGD[game._player.id]["followers"] do
				if id == CGD[game._player.id]["followers"][f][2] then
					a = false
					break
				end
			end
		end
		return a
	end

	savedUnits[world.current] = {}
	for f = 1, #CGD do
		if CGD[f] and isAvailable(f) then
		tableInsert(savedUnits[world.current],{CGD[f]["id"],game._function.roundupnum(CGD[f]["x"]),game._function.roundupnum(CGD[f]["y"]),CGD[f]["resptime"],CGD[f]["spos"]})
		end
	end
end

local function loadingBar(f, n)
	local x1, x2, y = 5, mathFloor(f * 150 / n), 40
	gpu.fill(x1, y, x2, 1, '█')
end

-- Загрузить карту
function game._function.loadWorld(id,unitList)
	local followers = {}

	game._data.stopDrawing = true
	game._data.paused = true
	game._data.windowThread = nil
	CGD[game._player.id]["target"] = nil
	game._gui.NPCDialog.currentDialog = nil
	world.current = id

	-- Чёрный экран
	game._function.levelLoadingScreen()
	gpu.setForeground(0xAAAAAA)
	gpu.fill(5, 39, 150, 1, '─')
	gpu.fill(5, 41, 150, 1, '─')
	gpu.setForeground(0xCCCCCC)

	--consoleArray = {"Загрузка уровня id:"..id.." "..world[world.current].name.."..."}

	local n = CGD[game._player.id] -- Данные игрока переносятся
	-- Пет переносится
	if CGD[game._player.id] and CGD[game._player.id]["followers"] and #CGD[game._player.id]["followers"] > 0 then
		for f = 1, #CGD[game._player.id]["followers"] do
			followers[f] = CGD[CGD[game._player.id]["followers"][f][2]]
		end
	end
	CGD = {}
	CGD[game._player.id] = n
	CGD[game._player.id]["x"], CGD[game._player.id]["mx"], cGlobalx, cBackgroundPos = 1, 1, 1, 1
	CGD[game._player.id]["cmove"] = true
	CGD[game._player.id]["ctck"] = true
	-- Картиночки
	imageBuffer = {
		[-4]=image.load(game._data.text.directory.."sprpic/"..gud[game._player.id]["aimage"][4]),
		[-3]=image.load(game._data.text.directory.."sprpic/"..gud[game._player.id]["aimage"][3]),
		[-2]=image.load(game._data.text.directory.."sprpic/"..gud[game._player.id]["aimage"][2]),
		[-1]=image.load(game._data.text.directory.."sprpic/"..gud[game._player.id]["aimage"][1]),
		[0]=image.load(game._data.text.directory.."sprpic/"..gud[game._player.id]["image"]..".pic")
	}
	bufferenv = {}

--

	local spx = 0
	local spawningUnits = unitList or world[id].spawnList

	if not savedUnits[id] or #savedUnits[id] == 0 then
		for f = 1, #spawningUnits do
			spx = spawningUnits[f][2]
			if gud[spawningUnits[f][1]]["nres"] ~= false then
				if spawningUnits[f][4] == nil then
					game._function.addUnit(spawningUnits[f][1],spx,spawningUnits[f][3])
					CGD[#CGD]["image"] = setImage(spawningUnits[f][1])
				else
					for i = 1, spawningUnits[f][4] do
						game._function.addUnit(spawningUnits[f][1],spx+i*spawningUnits[f][5]-spawningUnits[f][5],spawningUnits[f][3])
						CGD[#CGD]["image"] = setImage(spawningUnits[f][1])
					end
				end
				if f % 603 == 0 then
					computer.pullSignal(0)
				end
			end
			loadingBar(f, #spawningUnits)
		end
	else
		for f = 1, #savedUnits[id] do
			if gud[savedUnits[id][f][1]]["nres"] ~= false then
				game._function.addUnit(savedUnits[id][f][1],savedUnits[id][f][2],savedUnits[id][f][3])
				if savedUnits[id][f][4] > 0 then
					CGD[#CGD]["living"] = false
					CGD[#CGD]["resptime"] = savedUnits[id][f][4]
				end
				if savedUnits[id][f][5] then
					CGD[#CGD]["spos"] = savedUnits[id][f][5]
				end
				CGD[#CGD]["image"] = setImage(savedUnits[id][f][1])
				if f % 603 == 0 then
					computer.pullSignal(0)
				end
			end
			loadingBar(f, #savedUnits[id])
		end
	end

	local unitid
	if #followers > 0 then
		for f = 1, #followers do
			unitid = #CGD + 1
			tableInsert(CGD, unitid, followers[f])
			CGD[unitid]["x"] = CGD[game._player.id]["x"]
			CGD[unitid]["mx"] = CGD[game._player.id]["x"]
			CGD[unitid]["image"] = setImage(CGD[unitid]["id"])
			CGD[game._player.id]["followers"][f] = {CGD[unitid]["id"], unitid}
		end
	end

	followers = nil

	saveUnitData()
	game._data.paused = false
	game._data.stopDrawing = false
	game._function.showMapName(world[id].name)
end

-- Телепорт на другие координаты, или в другой мир
function game._function.teleport(x, tworld)
	if tworld and tworld ~= world[world.current] then
		saveUnitData()
		game._function.loadWorld(tworld)
		if #CGD[game._player.id]["followers"] > 0 then
			for f = 1, #CGD[game._player.id]["followers"] do
				CGD[CGD[game._player.id]["followers"][f][2]]["x"] = x
				CGD[CGD[game._player.id]["followers"][f][2]]["mx"] = x
				CGD[CGD[game._player.id]["followers"][f][2]]["target"] = nil
			end
		end
	end
	cGlobalx, cBackgroundPos, CGD[game._player.id]["x"], CGD[game._player.id]["mx"] = x or 1, x or 1, x or 1, x or 1
end

-- Сохранение игры

function game._function.saveGame(savePath,filename)
	if not fs.exists(savePath) then
		fs.makeDirectory(savePath)
	end
	
	saveUnitData()
	
	local gd = {}
	local qwertyn = 0
	
	for f = 1, 600 do
		if gid[game._config.reservedItemId - 1 + f] then tableInsert(gd,gid[game._config.reservedItemId - 1 + f]) end
	end
	
	for i = 1, #CGD do
		if CGD[i] then
			for f = 1, #CGD[game._player.id]["followers"] do
				if i == CGD[game._player.id]["followers"][f][2] then
					game._function.keepFollower(i)
				end
			end
		end
	end
 
	CGD[game._player.id]["chp"] = mathFloor(CGD[game._player.id]["chp"])
	local f = io.open(savePath.."/"..filename, "w")
	f:write(gud[game._player.id]["name"] .. "\n")
	f:write(ser.serialize(CGD[game._player.id]),"\n") -- игрок
	f:write(ser.serialize({world.current}),"\n") -- переменные
	f:write(ser.serialize(cPlayerSkills),"\n")
	f:write(ser.serialize(game._player.actSkills),"\n")
	f:write(ser.serialize(gd),"\n") -- предметы из gid
	f:write(ser.serialize(game._player.quests),"\n") -- задания
	
	gd = {}
	for i = 1, #gqd do
		if gqd[i]["comp"] > 0 then
			tableInsert(gd,i)
		end
	end
	f:write(ser.serialize(gd),"\n") -- выполненные/заблокированные задания
	gd = savedUnits
	f:write(ser.serialize(gd),"\n") -- чек побитых монстров
	
	gd = {}
	for i = 1, #gud do
		if gud[i]["nres"] == false then
			tableInsert(gd,i)
		end
	end
	f:write(ser.serialize(gd)) -- чек нересп. монстров
	f:close()
end

-- Загрузка игры

function game._function.loadGame(savePath,filename)
 if fs.exists(savePath.."/"..filename) then
 game._data.paused = true
 game._data.stopDrawing = true
 lostItem = nil
 game._data.messageTable1 = {}
 imageBuffer = {}
 iconImageBuffer = {}
local tkt, tbl, yv = 0
 while true do
  if gid[game._config.reservedItemId + tkt] then gid[game._config.reservedItemId + tkt] = nil end
  tkt = tkt + 1
  if tkt >= 600 then break end
 end
 tbl = readFromFile(savePath.."/"..filename)
 yv = ser.unserialize(tbl[3])
 world.current = yv[1]
 CGD = {}
 CGD[game._player.id] = ser.unserialize(tbl[2])
 CGD[game._player.id]["image"] = 0
 local buben = CGD[game._player.id]["x"]
 cPlayerSkills = ser.unserialize(tbl[4])
 game._player.actSkills = ser.unserialize(tbl[5])
 yv = ser.unserialize(tbl[6])
  for f = 1, #yv do
  gid[yv[f]["id"]] = yv[f]
   if gid[#gid]["oid"] then
   gid[#gid]["name"] = gid[gid[#gid]["oid"]]["name"]
   if gid[#gid]["props"] and type(gid[#gid]["props"]) == "table" and gid[#gid]["props"]["dds"] then for o = 1, #gid[#gid]["props"]["dds"] do gid[#gid]["name"] = "♦"..gid[#gid]["name"] end end
   game._data.maxItemID = mathMax(game._config.reservedItemId - 1 + f, game._config.reservedItemId)
   end
  end
 game._player.quests = ser.unserialize(tbl[7])
  for b = 1, #game._player.quests do
  gqd[game._player.quests[b][1]]["comp"] = 0
  end
 yv = ser.unserialize(tbl[8])
  for f = 1, #yv do
  gqd[yv[f]]["comp"] = 2
  end
 yv = ser.unserialize(tbl[10])
  for f = 1, #yv do
  gud[yv[f]]["nres"] = false
  end
 for f = 1, #world do savedUnits[f] = {} end
 yv = ser.unserialize(tbl[9])
  for n = 1, #yv do
  savedUnits[n] = yv[n]
  end
 game._player.id = CGD[game._player.id]["id"]
 gud[game._player.id]["name"] = tbl[1]
 game._function.loadWorld(world.current)
 CGD[game._player.id]["followers"] = {}
 game._function.teleport(buben)
 yv = nil
 tbl = nil
 end
targetQuest = 0
end

function game._function.pbar(x,y,size,percent,color1,color2, text, textcolor, style)
local dw, c = mathMin(mathCeil(percent*size/100),size), 1
 if not style then
 buffer.drawRectangle(x,y,size,1,color2, 0, " ")
 buffer.drawRectangle(x,y,dw,1,color1, 0, " ")
 if text then buffer.drawText(x, y, textcolor, text) end
 elseif style == 1 then
 buffer.drawRectangle(x,y,size-1,1,color2, 0, " ")
 buffer.drawText(x+size-1,y,color2,"◤")
 if dw < size/4 or dw > size*0.75 then c = 1 else c = 0 end
 buffer.drawRectangle(x,y,dw-c,1,color1, 0, " ")
 if dw < size/4 or dw > size*0.75 then buffer.drawText(x+dw-1,y,color1,"◤") end
 end
end

function game._function.checkNPCHasQuest(id)
	local sdq = false
	local NPCQuests = gud[id]["quests"]
	if id > 0 and NPCQuests then
		for f = 1, #NPCQuests do
			if gqd[NPCQuests[f]] and gqd[NPCQuests[f]]["comp"] == 0 and CGD[game._player.id]["lvl"] >= gqd[NPCQuests[f]]["minlvl"] then
				sdq = true
				break
			end
		end
	end
	return sdq
end

function game._function.checkNPCCompletedQuest(id)
	local scq = false
	for f = 1, #game._player.quests do
		if gqd[game._player.quests[f][1]]["qr"] == id and game._player.quests[f][3] == true then
			scq = true
			break
		end
	end
	return scq
end

local function isRtype(cid, ...)
	local args = {...}
	for i = 1, #args do
		if type(args[i]) == "string" then
			if CGD[cid]["rtype"] == cid then
			return true
			end
		end
	end
	return false
end

function game._function.drawAllCGDUnits()
	local ccl, cx, cy, dx, dy, btname, vpercentr, halfWidth, subtextninfo
	local hpbarwidth, textwidth = 8, 24
	for f = 1, #CGD do
		if f ~= game._player.id and CGD[f] then
			if CGD[f]["living"] and game._function.getDistanceToId(game._player.id,f) <= game._config.unitDrawingDistance then
				halfWidth = CGD[f]["width"]/2
				cx, cy = mathFloor(CGD[f]["x"]), mathFloor(CGD[f]["y"])
				dx,dy = cx+75-cGlobalx, 49-cy-CGD[f]["height"]
				if CGD[f]["image"] ~= nil and CGD[f]["spos"] == 1 then
					buffer.drawImage(dx,dy, imageBuffer[CGD[f]["image"]],true)
				elseif CGD[f]["image"] ~= nil and CGD[f]["spos"] == 0 then
					buffer.drawImage(dx,dy, image.flipHorizontally(image.copy(imageBuffer[CGD[f]["image"]])),true)
				else
					buffer.drawText(dx,dy,0xcc2222,"ERROR")
				end
	-- полоска хп над головой
				if CGD[f]["rtype"] == "e" and CGD[game._player.id]["target"] == f then
					game._function.pbar(dx+mathFloor((halfWidth-hpbarwidth/2)), dy-2,hpbarwidth,mathCeil(CGD[f]["chp"])*100/CGD[f]["mhp"],0xFF0000,0x444444," ",0xffffff)
					buffer.drawText(mathFloor(dx+(halfWidth-hpbarwidth/2)+(mathFloor((hpbarwidth/2) - (unicode.len(tostring(mathCeil(CGD[f]["chp"]))) / 2)))),dy-2,0xffffff,tostring(mathCeil(CGD[f]["chp"])))
	-- прогресс в выкапывании
				elseif game._player.pickingUp and game._player.pckTarget == f and CGD[f]["rtype"] == "r" then
					vpercentr = mathCeil((game._player.maxPckTime-game._player.pckTime)*100/game._player.maxPckTime)
					game._function.pbar(dx+mathFloor((halfWidth-hpbarwidth/2)),dy-2,hpbarwidth,vpercentr,0x009945,0x444444,vpercentr.."% ",0xffffff)
	-- галочка над НПС
				elseif CGD[f]["rtype"] == "f" then
					if game._function.checkNPCCompletedQuest(CGD[f]["id"]) == true then
						ccl = 0x009922
					elseif game._function.checkNPCHasQuest(CGD[f]["id"]) == true then
						ccl = 0xDCBC12
					end
					if ccl then
						buffer.drawText(dx+mathFloor(halfWidth)-2,dy-5,ccl,"▔██▔")
						buffer.drawText(dx+mathFloor(halfWidth)-1,dy-4,ccl,"◤◥")
						ccl = nil
					end
				end
	-- имя над головой
				if CGD[game._player.id]["target"] == f and isRtype(f, "e", "f", "p") then
					btname = tostring(gud[CGD[CGD[game._player.id]["target"]]["id"]]["name"])
				if unicode.len(btname) >= textwidth then btname = unicode.sub(btname,1,textwidth).."…" end
					buffer.drawText(mathFloor(dx+(halfWidth-textwidth/2)+(mathFloor((textwidth / 2) - (unicode.len(btname) / 2)))),dy-3,0xffffff,btname)
				end
				-- надписи над головой
				if CGD[f]["tlinfo"] and #CGD[f]["tlinfo"] > 0 then
					subtextninfo = ""
					for m = 1, 2 do
						if CGD[f]["tlinfo"][m] then
							subtextninfo = CGD[f]["tlinfo"][m]
							if unicode.len(tostring(CGD[f]["tlinfo"][m])) >= textwidth then
								subtextninfo = unicode.sub(CGD[f]["tlinfo"][m][1],1,textwidth).."…"
							end
							buffer.drawText(mathFloor(dx+(halfWidth-textwidth/2)+(mathFloor((textwidth/2) - (unicode.len(subtextninfo)/2)))),dy-m-3,0xffffff,subtextninfo)
						end
					end
				end
			end -- if CGD[f]["living"]
		end
	end
end

local function target(x,y)
	if CGD[game._player.id]["target"] ~= 1 and not game._gui.targetInfoPanel.showTargetInfo then
		CGD[game._player.id]["target"] = nil
	end
	for f = 1, #CGD do
		if CGD[f] and f ~= game._player.id and CGD[f]["living"] and clicked(x, y, mathFloor(CGD[f]["x"])+75-cGlobalx, 49-mathFloor(CGD[f]["y"])-2-CGD[f]["height"], mathFloor(CGD[f]["x"])+75-cGlobalx+CGD[f]["width"], 49-mathFloor(CGD[f]["y"])) then
			CGD[game._player.id]["target"] = f
		end
	end
end

function game._gui.blank.draw(data, title)
	local x, y, w, h, title = data.x, data.y, data.w, data.h, title or data.title
	local titleLen = unicode.len(title)
	buffer.drawRectangle(x, y, w, h, 0xABABAB, 0, " ")
	buffer.drawRectangle(x, y, w, 1, 0x525252, 0, " ")
	buffer.drawText(x + mathFloor(w / 2 - titleLen / 2), y, 0xffffff, title)
	if w > 50 then
		buffer.drawText(x + w - 8, y, 0xffffff, "Закрыть")
	else
		buffer.drawText(x + w - 1, y, 0xffffff, "X")
	end
end

----------------------------------Меню пауза-------------------------------------------------

game._gui.pauseMenu.buttonFunction = {
	[1]=function()
		game._data.windowThread = nil
		game._data.paused = false
	end,
	[2]=function()
		game._function.openInventory()
	end,
	[3]=function()
		game._data.windowThread = "skillsWindow"
	end,
	[4]=function()
		game._data.windowThread = "pstats"
		game._function.UpdatePlayerStats()
		game._gui.playerStats.updateContent() -- Обновить текст с ифнормацией
	end,
	[5]=function()
		game._data.windowThread = "quests"
	end,
	[6]=function()
		game._function.saveGame(game._data.text.directory.."saves",gud[CGD[game._player.id]["id"]]["name"])
	end,
	[7]=function()
		game._gui.mainMenu.open(2)
	end,
	[8]=function()
		--game._data.inGame = false
		game._gui.mainMenu.open(0)
	end,
}

function game._gui.pauseMenu.draw()
	local x, y = game._gui.pauseMenu.x, game._gui.pauseMenu.y
	buffer.drawRectangle(x, y, game._gui.pauseMenu.w, game._gui.pauseMenu.h, 0x9D9D9D, 0, " ")
	buffer.drawText(13,2,0xffffff,"Пауза")
	for f = 1, #game._data.pauseMenuList do
		buffer.drawRectangle(1, 1+f*4, game._gui.pauseMenu.w, 3, 0x838383, 0, " ")
		buffer.set(1,3+f*4,0x959595,0x000000," ")
		buffer.drawText(mathMax(mathFloor((game._gui.pauseMenu.w/2)-(unicode.len(game._data.pauseMenuList[f])/2)),0),2+f*4,0xffffff,game._data.pauseMenuList[f])
	end
end

game._gui.pauseMenu.action["touch"] = function(ev)
	for f = 1, #game._data.pauseMenuList do
		if ev[5] == 0 and clicked(ev[3],ev[4],game._gui.pauseMenu.x,4+f*4-3,game._gui.pauseMenu.x+game._gui.pauseMenu.w-1,3+f*4) then
			game._gui.pauseMenu.buttonFunction[f]()
			ev[3], ev[4] = 0, 0
			break
		end
	end
end

----------------------------------- Панель информация о персонаже ------------------------------------------------

function game._function.drawEffInfo(x,y,id) -- Информация после нажатия на иконку эффекта
	buffer.drawRectangle(x,y,mathMax(unicode.len(ged[id]["name"]),unicode.len(ged[id]["descr"])),2,0xA1A1A1, 0, " ")
	buffer.drawText(x,y,0xEDEDED,ged[id]["name"])
	buffer.drawText(x,y+1,0xCECECE,ged[id]["descr"])
end

local svxpbar = false

game._gui.playerInfoPanel = {x=1,y=1,w=25,h=5,effectDescription=0,edx=1,edy=1,action={}}

local function drawUnitEffectIcons(x, y, source) -- Иконки эффектов
	for f = 1, #source do
		for h = 1, 2 do
			for w = 1, 3 do
				buffer.set(x + f * 4 - 4 + w, y + 5 + h, ged[source[f][1]]["i"][2 * (3 * (h - 1) + w) - 1],0xffffff,ged[source[f][1]]["i"][2 * (3 * (h - 1) + w)])
			end
		end
	end
end

-- Панель в левом верхнем углу
function game._gui.playerInfoPanel.draw()
	local x, y, halfWidth = game._gui.playerInfoPanel.x, game._gui.playerInfoPanel.y, game._gui.playerInfoPanel.w / 2
	buffer.drawRectangle(x, y, game._gui.playerInfoPanel.w + 2, 1, 0x8C8C8C, 0, " ")
	buffer.drawRectangle(x, y + game._gui.playerInfoPanel.h - 1, game._gui.playerInfoPanel.w-2, 1, 0x8C8C8C, 0, " ")
	buffer.drawText(x+game._gui.playerInfoPanel.w-2,y+game._gui.playerInfoPanel.h-1,0x8C8C8C,"◤")
	local fxpdt = tostring(CGD[game._player.id]["cxp"]).."/"..tostring(CGD[game._player.id]["mxp"])
	local percent3, roundPrc3 = math.modf(CGD[game._player.id]["cxp"]*100/CGD[game._player.id]["mxp"])
	roundPrc3 = game._function.roundupnum(roundPrc3*10)
	buffer.drawText(x+1, y, 0xffffff, "Уровень "..CGD[game._player.id]["lvl"])

	-- Три полоски
	local tpbar1 = mathFloor(CGD[game._player.id]["chp"]).."/"..mathFloor(CGD[game._player.id]["mhp"])
	local tpbar2 = mathFloor(CGD[game._player.id]["cmp"]).."/"..mathFloor(CGD[game._player.id]["mmp"])
	local tpbar3 = percent3.."."..roundPrc3.."% "
	game._function.pbar(x,y+1,game._gui.playerInfoPanel.w+2,mathFloor(CGD[game._player.id]["chp"]*100/CGD[game._player.id]["mhp"]),0xFF0000,0x5B5B5B," ", 0xffffff,1)
	buffer.drawText(mathMax(mathFloor((halfWidth)-(#tpbar1/2)),0),y+1,0xffffff,tpbar1)
	game._function.pbar(x,y+2,game._gui.playerInfoPanel.w+1,mathFloor(CGD[game._player.id]["cmp"]*100/CGD[game._player.id]["mmp"]),0x0000FF,0x5B5B5B," ", 0xffffff,1)
	buffer.drawText(mathMax(mathFloor((halfWidth)-(#tpbar2/2)),0),y+2,0xffffff,tpbar2)
	game._function.pbar(x,y+3,game._gui.playerInfoPanel.w,percent3,0xFFFF00,0x5B5B5B," ", 0x333333,1)
	buffer.drawText(mathMax(mathFloor((halfWidth)-(#tpbar3/2)),0),y+3,0x333333,tpbar3)

	if svxpbar then
		buffer.drawText(x + 24 - #fxpdt, y + 3, 0x4F4F4F, fxpdt)
	end

	-- Иконки эффектов
	drawUnitEffectIcons(x, y, CGD[game._player.id]["effects"])

	if game._gui.playerInfoPanel.effectDescription ~= 0 and CGD[game._player.id]["effects"][game._gui.playerInfoPanel.effectDescription] then
		game._function.drawEffInfo(game._gui.playerInfoPanel.edx,game._gui.playerInfoPanel.edy,CGD[game._player.id]["effects"][game._gui.playerInfoPanel.effectDescription][1])
	end
end

game._gui.playerInfoPanel.action["touch"] = function(ev)
	local v = false
	-- Нажатие по иконкам эффектов
	for f = 1, #CGD[game._player.id]["effects"] do
		if ev[5] == 0 and clicked(ev[3],ev[4],game._gui.playerInfoPanel.x+f*4-4,game._gui.playerInfoPanel.y+game._gui.playerInfoPanel.h+1,game._gui.playerInfoPanel.x-1+f*4,game._gui.playerInfoPanel.y+game._gui.playerInfoPanel.h+2) then
			game._gui.playerInfoPanel.effectDescription = f
			game._gui.playerInfoPanel.edx = ev[3]
			game._gui.playerInfoPanel.edy = ev[4]+1
			v = true
			break
		end
	end
	if v == false then
		game._gui.playerInfoPanel.effectDescription = 0
	end
end

------------------------------------Панель информация о цели-----------------------------------------------
game._gui.targetInfoPanel = {x=60,y=2,w=35,h=4,effectDescription=0,edx=1,edy=1,showTargetInfo=false,action={}}

function game._gui.targetInfoPanel.showInfo(x,y)
	local cwtype = ""
	if type(gud[CGD[CGD[game._player.id]["target"]]["id"]]["wtype"]) == "number" then
		cwtype = baseWtype[gud[CGD[CGD[game._player.id]["target"]]["id"]]["wtype"]]
	end
	local sTInfoArray1 = {
		gud[CGD[CGD[game._player.id]["target"]]["id"]]["name"],
		"Тип: "..cwtype,
		"Респ: "..tostring(gud[CGD[CGD[game._player.id]["target"]]["id"]]["vresp"]).." секунд",
		"ID: "..tostring(CGD[CGD[game._player.id]["target"]]["id"]),
		"Физ.атака: "..CGD[CGD[game._player.id]["target"]]["ptk"][1].."-"..CGD[CGD[game._player.id]["target"]]["ptk"][2],
		"Маг.атака: "..CGD[CGD[game._player.id]["target"]]["mtk"][1].."-"..CGD[CGD[game._player.id]["target"]]["mtk"][2],
		"Физ.защита: "..tostring(CGD[CGD[game._player.id]["target"]]["pdef"].." ("..tostring(mathFloor(100*(CGD[CGD[game._player.id]["target"]]["pdef"]/(CGD[CGD[game._player.id]["target"]]["pdef"]+CGD[game._player.id]["lvl"]*30)))).."%)"),
		"Маг.защита: "..tostring(CGD[CGD[game._player.id]["target"]]["mdef"].." ("..tostring(mathFloor(100*(CGD[CGD[game._player.id]["target"]]["mdef"]/(CGD[CGD[game._player.id]["target"]]["mdef"]+CGD[game._player.id]["lvl"]*30)))).."%)"),
		"Цель: " .. tostring(CGD[CGD[game._player.id]["target"]]["target"])
	}
	buffer.drawRectangle(x, y, 27, 11, 0x6B6B6B, 0, " ")
	game._function.unicodeFrame(x,y,27,11,0x808080)
	for f = 1, #sTInfoArray1 do
		buffer.drawText(x+1,y+f,0xffffff,unicode.sub(tostring(sTInfoArray1[f]),1,25))
	end
	sTInfoArray1 = nil
end

function game._gui.targetInfoPanel.draw()
	local addInfoButton = false
	local textName, labelText, addText
	local x, y, halfWidth = game._gui.targetInfoPanel.x, game._gui.targetInfoPanel.y, game._gui.targetInfoPanel.w / 2
	buffer.drawRectangle(x, y, game._gui.targetInfoPanel.w, game._gui.targetInfoPanel.h - 1, 0x9B9B9B, 0, " ")
	buffer.drawRectangle(x + 1, y + 3, game._gui.targetInfoPanel.w - 2, 1, 0x9B9B9B, 0, " ")
	buffer.drawText(x, y + 3, 0x9B9B9B, "◥")
	buffer.drawText(x + game._gui.targetInfoPanel.w - 1, y + 3, 0x9B9B9B, "◤")
	local roleType = CGD[CGD[game._player.id]["target"]]["rtype"]
	if roleType == "e" or roleType == "p" or roleType == "m" then
		local chp, mhp = CGD[CGD[game._player.id]["target"]]["chp"], CGD[CGD[game._player.id]["target"]]["mhp"]

		local namecolor, clvl, plvl = 0xffffff, CGD[CGD[game._player.id]["target"]]["lvl"], CGD[game._player.id]["lvl"]
		if clvl >= plvl+2 and clvl <= plvl+4 then namecolor = 0xFFDB80
		elseif clvl >= plvl+5 and clvl <= plvl+7 then namecolor = 0xFF9200
		elseif clvl >= plvl+8 then namecolor = 0xFF1000
		elseif clvl <= plvl-2 and clvl >= plvl-5 then  namecolor = 0xBEBEBE
		elseif clvl <= plvl-6 then  namecolor = 0x00823A
		end

		local typestr = {[1] = "Физ.",[2] = "Маг."}
		if roleType == "e" then
			local typeString
			if gud[CGD[CGD[game._player.id]["target"]]["id"]]["dtype"] == nil then
				typeString = "Обычный"
			else
				typeString = typestr[gud[CGD[CGD[game._player.id]["target"]]["id"]]["dtype"]]
			end
			buffer.drawText(x + game._gui.targetInfoPanel.w - unicode.len(typeString) - 1, y + 3, 0xffffff, typeString)
		end

		textName, labelText = gud[CGD[CGD[game._player.id]["target"]]["id"]]["name"], tostring(CGD[CGD[game._player.id]["target"]]["lvl"]).." уровень"
		local percent = mathCeil(chp * 100 / mhp)
		game._function.unicodeFrame(x, y, game._gui.targetInfoPanel.w, 3, 0xA2A2A2)
		game._function.pbar(x, y + 1, game._gui.targetInfoPanel.w, percent, 0xFF0000, 0x5B5B5B, " ", 0xffffff)
		buffer.drawText(x + (mathMax(mathFloor((halfWidth) - (unicode.len(labelText) / 2)), 0)), y + 1, 0xffffff, labelText)
		buffer.drawText(x + (mathMax(mathFloor((halfWidth) - (unicode.len(textName) / 2)), 0)), y + 2, namecolor, textName)
		addInfoButton = true
	elseif roleType == "f" then
		labelText, textName = baseWtype[gud[CGD[CGD[game._player.id]["target"]]["id"]]["wtype"]], gud[CGD[CGD[game._player.id]["target"]]["id"]]["name"]
		buffer.drawText(x, y, 0x727272, "НИП")
		addText = "Нажмите 'E' чтобы открыть диалог"
		buffer.drawText(x + (mathMax(mathFloor((halfWidth) - (unicode.len(textName) / 2)), 0)), y + 1, 0xffffff, textName)
		buffer.drawText(x + (mathMax(mathFloor((halfWidth) - (unicode.len(labelText) / 2)), 0)), y + 2, 0xC8C8C8, labelText)
		buffer.drawText(x + (mathMax(mathFloor((halfWidth) - (unicode.len(addText) / 2)), 0)), y + 3, 0x727272, addText)
		addInfoButton = false
	elseif roleType == "r" then
		buffer.drawText(x,y,0x727272,"Ресурс")
		addText = "Нажмите 'E' чтобы собрать"
		buffer.drawText(x + (mathMax(mathFloor((halfWidth) - (unicode.len(gud[CGD[CGD[game._player.id]["target"]]["id"]]["name"]) / 2)), 0)), y+1, 0xffffff, gud[CGD[CGD[game._player.id]["target"]]["id"]]["name"])
		buffer.drawText(x + (mathMax(mathFloor((halfWidth) - (unicode.len(addText) / 2)), 0)), y + 2, 0x727272, addText)
		addInfoButton = false
	elseif roleType == "c" then
		addText = "Нажмите 'E' чтобы использовать"
		buffer.drawText(x + (mathMax(mathFloor((halfWidth) - (unicode.len(gud[CGD[CGD[game._player.id]["target"]]["id"]]["name"]) / 2)), 0)), y+1, 0xffffff, gud[CGD[CGD[game._player.id]["target"]]["id"]]["name"])
		buffer.drawText(x + (mathMax(mathFloor((halfWidth) - (unicode.len(addText) / 2)), 0)), y + 2, 0x727272, addText)
		addInfoButton = false
	end

	if addInfoButton then
		buffer.drawText(x + 1, y + 3, 0xffffff, "О персонаже")
	end

	-- Иконки эффектов
	drawUnitEffectIcons(x, y - 1, CGD[CGD[game._player.id]["target"]]["effects"])

	if game._gui.targetInfoPanel.showTargetInfo then
		game._gui.targetInfoPanel.showInfo(x + 1, y + 4)
	end

	if game._gui.targetInfoPanel.effectDescription ~= 0 and CGD[CGD[game._player.id]["target"]]["effects"][game._gui.targetInfoPanel.effectDescription] then
		game._function.drawEffInfo(game._gui.targetInfoPanel.edx,game._gui.targetInfoPanel.edy,CGD[CGD[game._player.id]["target"]]["effects"][game._gui.targetInfoPanel.effectDescription][1])
	end
end

game._gui.targetInfoPanel.action["touch"] = function(ev)
	local v = false
	-- Нажатие по иконкам эффектов
	if CGD[game._player.id]["target"] then
		for f = 1, #CGD[CGD[game._player.id]["target"]]["effects"] do
			if ev[5] == 0 and clicked(ev[3],ev[4],game._gui.targetInfoPanel.x+f*4-4,game._gui.targetInfoPanel.y+game._gui.targetInfoPanel.h+1,game._gui.targetInfoPanel.x+f*4-1,game._gui.targetInfoPanel.y+game._gui.targetInfoPanel.h+2) then
				game._gui.targetInfoPanel.effectDescription = f
				game._gui.targetInfoPanel.edx = ev[3]
				game._gui.targetInfoPanel.edy = ev[4] + 1
				v = true
				break
			end
		end
	end

	if v == false then
		game._gui.targetInfoPanel.effectDescription = 0
	end

	--кнопка ифно о цели
	if game._data.windowThread == nil and ev[5] == 0 and CGD[game._player.id]["target"] then
		if clicked(ev[3],ev[4],game._gui.targetInfoPanel.x,game._gui.targetInfoPanel.y+game._gui.targetInfoPanel.h-1,game._gui.targetInfoPanel.x+game._gui.targetInfoPanel.w-1,game._gui.targetInfoPanel.y+game._gui.targetInfoPanel.h-1) then
			if gud[CGD[CGD[game._player.id]["target"]]["id"]]["rtype"] ~= "r" and gud[CGD[CGD[game._player.id]["target"]]["id"]]["rtype"] ~= "f" then
				game._gui.targetInfoPanel.showTargetInfo = true
			end
		else
			game._gui.targetInfoPanel.showTargetInfo = false
		end
	end
end

-------------------------------Панель умений----------------------------------------------------

local vtskillUsingMsg, skillUsingMsg = 0, {}

function game._gui.skillsTopPanel.draw()
	local x, y, w, h = game._gui.skillsTopPanel.x, game._gui.skillsTopPanel.y, game._gui.skillsTopPanel.w, game._gui.skillsTopPanel.h
	buffer.drawRectangle(x, y, w, h, 0x9B9B9B, 0, " ")
	game._function.unicodeFrame(x, y, w, h, 0x6B6B6B)
	for f = 1, #game._gui.skillsTopPanel.t do
		buffer.drawRectangle(x + 3 + (f * 5 - 5), y + 1, 2, 1, game._gui.skillsTopPanel.t[f].c, 0, " ")
		buffer.drawText(x + 3 + (f * 5 - 5), y + 1, 0xffffff, game._gui.skillsTopPanel.t[f].t)
		if game._player.actSkills[f + 1] > 0 then
			buffer.drawText(x + 3 + (f * 5 - 5), y + 2, 0xffffff, tostring(mathCeil(cPlayerSkills[game._player.actSkills[f+1]][2] / 10)))
		end
	end
	if vtskillUsingMsg > 0 then
		buffer.drawText(x + 2, y + 3, 0xC1C1C1, skillUsingMsg[#skillUsingMsg])
	end
end

--------------------------------Союзники------------------------------

game._gui.followerInfo = {x=1,y=9,w=20,h=3,action={}}

function game._gui.followerInfo.draw()
	if CGD[game._player.id]["followers"] and #CGD[game._player.id]["followers"] > 0 then
		local x, y = game._gui.followerInfo.x, game._gui.followerInfo.y
		buffer.drawRectangle(x, y, game._gui.followerInfo.w, 1 + #CGD[game._player.id]["followers"] * 3, 0x9B9B9B, 0, " ")
		for f = 1, #CGD[game._player.id]["followers"] do
			buffer.drawText(x, y+f*3-3, 0xffffff, gud[CGD[game._player.id]["followers"][f][1]]["name"] .. " ур." .. CGD[CGD[game._player.id]["followers"][f][2]]["lvl"])
			game._function.pbar(x, y+f*3-2, game._gui.followerInfo.w,mathCeil(CGD[CGD[game._player.id]["followers"][f][2]]["chp"]*100/CGD[CGD[game._player.id]["followers"][f][2]]["mhp"]), 0xFF0000, 0x5B5B5B, mathCeil(CGD[CGD[game._player.id]["followers"][f][2]]["chp"]) .. "/" .. mathCeil(CGD[CGD[game._player.id]["followers"][f][2]]["mhp"]), 0xffffff)
			game._function.pbar(x, y+f*3-1, game._gui.followerInfo.w,mathCeil(CGD[CGD[game._player.id]["followers"][f][2]]["cxp"]*100/CGD[CGD[game._player.id]["followers"][f][2]]["mxp"]), 0xFFFF00, 0x5B5B5B, mathCeil(CGD[CGD[game._player.id]["followers"][f][2]]["cxp"]) .. "/" .. mathCeil(CGD[CGD[game._player.id]["followers"][f][2]]["mxp"]), 0x222222)
		end
	end
end

game._gui.followerInfo.action["touch"] = function(ev)
	if CGD[game._player.id]["followers"] and #CGD[game._player.id]["followers"] > 0 then
		local x, y = game._gui.followerInfo.x, game._gui.followerInfo.y
		for f = 1, #CGD[game._player.id]["followers"] do
			if ev[5] == 0 and clicked(ev[3], ev[4], x, y+f*3-3, x + game._gui.followerInfo.w - 1, y+f*3) then
				CGD[game._player.id]["target"] = CGD[game._player.id]["followers"][f][2]
				break
			end
		end
	end
end

-------------------------------Спонтанные диалоги----------------------------------------------------

--[[ -- Здесь Ошибки

local spdialogs = {
[1]={
	["text"]=string.rep("Текст. ",5),
	{["text"]="Продолжить1",["action"]="close"},
	{["text"]="Продолжить2",["action"]="close"},
	{["text"]="Продолжить3",["action"]="close"}
	}
}

game._function.specialDialog = {w=160,h=12,current=1,trg=1,action={}}

function game._function.specialDialog.draw()
local x, y = mathFloor(1+160/2-spDialog.w/2), 1+50-spDialog.h
buffer.drawRectangle(x, y, spDialog.w, spDialog.h, 0x5E5E5E, nil, nil, 15)
buffer.drawRectangle(x, y, spDialog.w, 1, 0x5E5E5E)
local num_h = mathCeil(unicode.len(spdialogs[spDialog.current]["text"])/(spDialog.w/2))
local text_y = 50-mathFloor(spDialog.h/2-num_h/2)
local ctext
 for f = 1, num_h do
 ctext = unicode.sub(spdialogs[spDialog.current]["text"],spDialog.w/2*f-spDialog.w/2,spDialog.w/2*f)
 buffer.drawText(1+mathFloor(spDialog.w/2-unicode.len(ctext)/2), text_y+f-4, 0xEDEDED, ctext)
 end
 for f = 1, #spdialogs[spDialog.current] do
 ctext = spdialogs[spDialog.current][f]["text"]
 if spDialog.trg == f then buffer.drawRectangle(x, text_y+f, spDialog.w, 1, 0x989898, nil, nil, 40) end
 buffer.drawText(1+mathFloor(spDialog.w/2-unicode.len(ctext)/2),text_y+f, 0xEDEDED, ctext)
 end
end

]]

------------------------------Диалоги НПС-----------------------------------------------------

game._gui.NPCDialog = {window={x=12,y=10,w=50,h=24,title=""},action={}}

function game._gui.NPCDialog.init()
	-- Разделить длинный текст в диалоге
	game._gui.NPCDialog.text = game._function.textWrap(game._gui.NPCDialog.currentDialog["text"], game._gui.NPCDialog.window.w - 4)
end

-- Открыть диалог клавишей 'E' ----------------------------
function game._gui.NPCDialog.start(NPC)
	game._player.usepmx = false
	pmov = 0
	CGD[game._player.id]["image"] = 0
	game._data.paused = true
	game._data.windowThread = "dialog"
	game._function.dialogsdata, game._function.gddnum = io.open(game._data.text.directory.."data/dialogs.data","r"), 1
	for dnum in game._function.dialogsdata:lines() do
		if game._function.gddnum == CGD[NPC]["dialog"] then
			game._gui.NPCDialog.currentDialog = load("return "..dnum)()
			break
		end
		game._function.gddnum = game._function.gddnum + 1
	end
	game._function.dialogsdata:close()
	game._function.dialogsdata = nil
	game._gui.NPCDialog.currentDialog["im"] = 0
	game._gui.NPCDialog.currentDialog = insertQuests(NPC, game._gui.NPCDialog.currentDialog)
	game._gui.NPCDialog.init()
end

local function isQuestAvailable(playerId, q)
	if gqd[q]["minlvl"] > CGD[playerId]["lvl"] or gqd[q]["comp"] > 0 then
		return false
	end
	return true
end

-- Отрисовка окна диалога ----------------------------
function game._gui.NPCDialog.draw(x, y)
	local x, y, w, h = game._gui.NPCDialog.window.x, game._gui.NPCDialog.window.y, game._gui.NPCDialog.window.w, game._gui.NPCDialog.window.h
	local isQnComp, isQcomp, sColor = false, false

	-- Окно
	game._gui.blank.draw(game._gui.NPCDialog.window, gud[CGD[CGD[game._player.id]["target"]]["id"]]["name"])
	buffer.drawRectangle(x + 1, y + 14, w - 2, 9, 0x7A7A7A, 0, " ")
	buffer.drawRectangle(x + 1, y + 1, w - 2, 12, 0x7A7A7A, 0, " ")

	insertQuests(CGD[game._player.id]["target"], game._gui.NPCDialog.currentDialog)
	for f = 1, #game._gui.NPCDialog.currentDialog do
		if not game._gui.NPCDialog.currentDialog[f] then
			tableRemove(game._gui.NPCDialog.currentDialog, f)
		end
	 end
	for f = 1, #game._gui.NPCDialog.currentDialog do
		isQnComp = false
		if game._gui.NPCDialog.currentDialog[#game._gui.NPCDialog.currentDialog-f+1] ~= nil then
			if game._gui.NPCDialog.currentDialog[#game._gui.NPCDialog.currentDialog-f+1]["action"] == "qdialog" then
				for l = 1, #game._player.quests do
					if game._player.quests[l][1] == game._gui.NPCDialog.currentDialog[#game._gui.NPCDialog.currentDialog-f+1]["q"] and game._player.quests[l][3] == false then
						isQnComp = true
						break
					end
				end
			end
			if game._gui.NPCDialog.currentDialog[#game._gui.NPCDialog.currentDialog-f + 1 ] ~= nil and game._gui.NPCDialog.currentDialog[#game._gui.NPCDialog.currentDialog-f+1]["action"] == "qdialog" then
				if isQnComp or not isQuestAvailable(game._player.id, game._gui.NPCDialog.currentDialog[#game._gui.NPCDialog.currentDialog - f + 1]["q"]) then
					tableRemove(game._gui.NPCDialog.currentDialog, #game._gui.NPCDialog.currentDialog - f + 1) -- БАГ
				end
			elseif game._gui.NPCDialog.currentDialog[#game._gui.NPCDialog.currentDialog-f+1]["action"] == "setWorld" and CGD[game._player.id]["lvl"] < game._gui.NPCDialog.currentDialog[#game._gui.NPCDialog.currentDialog-f+1]["reqlvl"] then
				game._gui.NPCDialog.currentDialog[#game._gui.NPCDialog.currentDialog-f+1]["text"] = unicode.sub(game._gui.NPCDialog.currentDialog[#game._gui.NPCDialog.currentDialog-f+1]["text"],1,unicode.len(game._gui.NPCDialog.currentDialog[#game._gui.NPCDialog.currentDialog-f+1]["text"])-#tostring(game._gui.NPCDialog.currentDialog[#game._gui.NPCDialog.currentDialog-f+1]["reqlvl"])-2)
				game._gui.NPCDialog.currentDialog[#game._gui.NPCDialog.currentDialog-f+1]["text"] = game._gui.NPCDialog.currentDialog[#game._gui.NPCDialog.currentDialog-f+1]["text"].." "..game._gui.NPCDialog.currentDialog[#game._gui.NPCDialog.currentDialog-f+1]["reqlvl"].."+"
			end
		end
	end

	for f = 1, #game._gui.NPCDialog.text do
		buffer.drawText(x + 2,y + 1 + f, 0xffffff, game._gui.NPCDialog.text[f])
	end
	for f = 1, #game._gui.NPCDialog.currentDialog do
		sColor = 0xffffff
		isQnComp, isQcomp = false, false
		for l = 1, #game._player.quests do
			if game._gui.NPCDialog.currentDialog[f] and game._gui.NPCDialog.currentDialog[f]["action"] == "qdialog" then
				if game._player.quests[l][1] == game._gui.NPCDialog.currentDialog[f]["q"] and not game._player.quests[l][3] then
					isQnComp = true
				end
			elseif game._gui.NPCDialog.currentDialog[f] and game._gui.NPCDialog.currentDialog[f]["action"] == "cmpquest" then
				isQcomp = true
			end
		end
		if isQnComp then
			sColor = 0x555555
		elseif isQcomp then
			sColor = 0x1AB235
		end
		if game._gui.NPCDialog.currentDialog[f] then buffer.drawText(x+2,y+14+f,sColor,game._gui.NPCDialog.currentDialog[f]["text"]) end
	end
end

-- События, связанные с мышью, в окне диалога
game._gui.NPCDialog.action["touch"] = function(ev)
	local x, y, w, h = game._gui.NPCDialog.window.x, game._gui.NPCDialog.window.y, game._gui.NPCDialog.window.w, game._gui.NPCDialog.window.h
	local qcomp
	local closeDialog = false
	local closeButtonX = x + w - 1

	for f = 1, #game._gui.NPCDialog.currentDialog do
		if game._gui.NPCDialog.currentDialog[f]["action"] == "getquest" and not isQuestAvailable(game._player.id, game._gui.NPCDialog.currentDialog[f]["do"]) then
			tableRemove(game._gui.NPCDialog.currentDialog[f]) -- Удаление активных / выполненных заданий (тест)
		end
	end

	game._gui.NPCDialog.init();

	for f = 1, #game._gui.NPCDialog.currentDialog do
		if ev[5] == 0 and clicked(ev[3], ev[4], x + 2, y + 14 + f, x + w - 2, y + 14 + f) then
			-- Кнопка "закрыть"
			if game._gui.NPCDialog.currentDialog[f]["action"] == "close" then
				closeDialog = true
			-- Торговля
			elseif game._gui.NPCDialog.currentDialog[f]["action"] == "trade" then
				game._function.tradew.loaded = loadfile(game._data.text.directory.."data/trade.data")(game._gui.NPCDialog.currentDialog[f]["do"])
				game._function.tradew.sect = 1
				game._data.windowThread = "tradewindow"
				game._gui.NPCDialog.text = ""
			-- Ремесло
			elseif game._gui.NPCDialog.currentDialog[f]["action"] == "craft" then
				game._function.craftw.loaded = loadfile(game._data.text.directory.."data/manufacturing.data")(game._gui.NPCDialog.currentDialog[f]["do"])
				game._function.craftw.sect = 1
				game._data.windowThread = "craftwindow"
				game._gui.NPCDialog.text = ""
			-- Диалог
			elseif game._gui.NPCDialog.currentDialog[f]["action"] == "dialog" then
				game._gui.NPCDialog.currentDialog = game._gui.NPCDialog.currentDialog[f]["do"]
				game._gui.NPCDialog.init()
			-- Задания
			elseif game._gui.NPCDialog.currentDialog[f]["action"] == "qdialog" and isQuestAvailable(game._player.id, game._gui.NPCDialog.currentDialog[f]["q"]) then
				game._gui.NPCDialog.currentDialog = game._gui.NPCDialog.currentDialog[f]["do"]
				game._gui.NPCDialog.init()
			-- Получение задания
			elseif game._gui.NPCDialog.currentDialog[f]["action"] == "getquest" and gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["comp"] == 0 and CGD[game._player.id]["lvl"] >= gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["minlvl"] then
				game._function.getQuest(game._gui.NPCDialog.currentDialog[f]["do"])
				gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["givingQuest"] = CGD[CGD[game._player.id]["target"]]["id"]
				gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["comp"] = 1
				closeDialog = true
			-- Завершение задания
			elseif game._gui.NPCDialog.currentDialog[f]["action"] == "cmpquest" then
				for t = 1, #game._player.quests do
					if game._player.quests[t][1] == game._gui.NPCDialog.currentDialog[f]["do"] and game._player.quests[t][3] then
						if gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["type"] == 2 then -- Задание на поиск
							for l = 1, #gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["targ"] do
								-- if gid[gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["targ"][l][1]]["subtype"] == 2 then -- "subtype" = 2 - Для задания
									-- for k = 1, #CGD[game._player.id]["inventory"]["bag"] do
										-- if CGD[game._player.id]["inventory"]["bag"][k][1] == gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["targ"][l][1] then
											-- CGD[game._player.id]["inventory"]["bag"][k] = {0,0}
										-- end
									-- end
								-- else
								for k = 1, #CGD[game._player.id]["inventory"]["bag"] do
									if CGD[game._player.id]["inventory"]["bag"][k][1] == gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["targ"][l][1] and CGD[game._player.id]["inventory"]["bag"][k][2] >= gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["targ"][l][2] then
										CGD[game._player.id]["inventory"]["bag"][k][2] = CGD[game._player.id]["inventory"]["bag"][k][2] - gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["targ"][l][2]
									end
								end
								--end
							end
						end
						-- *награда за задание*
						if gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["qreward"] then
							if type(gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["qreward"]["item"]) == "table" then
								if #gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["qreward"]["item"] <= game._function.checkInventorySpace() then
									game._function.getQuestReward(game._gui.NPCDialog.currentDialog[f]["do"])
									qcomp = true
								elseif #gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["qreward"]["item"] > game._function.checkInventorySpace() then
									game._function.showMessage1("Необходимо "..#gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["qreward"]["item"].." ячеек в инвентаре")
									qcomp = false
								end
							elseif gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["qreward"]["item"] == nil then
								qcomp = true
								game._function.getQuestReward(game._gui.NPCDialog.currentDialog[f]["do"])
							end
						end
						if qcomp and not gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["afterCompleted"] then
							tableRemove(game._player.quests, t) -- Сделать задание неактивным
							if game._data.windowThread ~= "rewardChoice" then
								closeDialog = true
							end
							game._gui.NPCDialog.currentDialog = nil
							break
						elseif qcomp and gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["afterCompleted"] then
							if gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["afterCompleted"] == "setquest" then
								game._function.getQuest(gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["value"])
								game._function.showMessage1("Задание '"..gqd[gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["value"]]["name"].."' получено")
								gqd[gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["value"]]["givingQuest"] = CGD[CGD[game._player.id]["target"]]["id"]
								gqd[gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["value"]]["comp"] = 1
								tableRemove(game._player.quests, t)
								closeDialog = true
								break
							end
						end
						
						if gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["repeat"] == true then
							gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["comp"] = 0
						else
							gqd[game._gui.NPCDialog.currentDialog[f]["do"]]["comp"] = 2
						end
					end
				end
			elseif game._gui.NPCDialog.currentDialog[f]["action"] == "setWorld" and CGD[game._player.id]["lvl"] >= game._gui.NPCDialog.currentDialog[f]["reqlvl"] then
				game._function.teleport(game._gui.NPCDialog.currentDialog[f]["do"][2] or 1,game._gui.NPCDialog.currentDialog[f]["do"][1] or 1)
			end
		end
	end

	-- Если нажали кнопку закрыть
	if clicked(ev[3], ev[4], closeButtonX, y, closeButtonX, y) then
		closeDialog = true
	end

	if closeDialog then
		game._gui.NPCDialog.text = ""
		game._data.windowThread = nil
		game._gui.NPCDialog.currentDialog = nil
		game._data.paused = false
	end
end

------------------------------Выбор награды------------------------------

game._gui.rewardChoice = {x=0,y=15,w=0,h=18,button1={x=0,y=13,w=16,h=3,c=0x838383,t="Выбрать"},buffer={items={},images={},targ=nil},action={}}

function game._gui.rewardChoice.draw()
	game._gui.rewardChoice.w = 5 + #game._gui.rewardChoice.buffer.items * 23
	game._gui.rewardChoice.x = mathFloor(mxw / 2 - game._gui.rewardChoice.w / 2)
	local x, y = game._gui.rewardChoice.x, game._gui.rewardChoice.y
	local title, ccolor, x1, y1 = "Выбор награды"
	buffer.drawRectangle(x, y, game._gui.rewardChoice.w, game._gui.rewardChoice.h, 0x9B9B9B, 0, " ")
	buffer.drawRectangle(x, y, game._gui.rewardChoice.w, 1, 0x525252, 0, " ")
	buffer.drawText(x+mathFloor(game._gui.rewardChoice.w / 2 - unicode.len(title) / 2),y,0xffffff,title)
	for f = 1, #game._gui.rewardChoice.buffer.items do
		x1 = x+4
		y1 = y+2
		ccolor = 0x4A4A4A
		if f == game._gui.rewardChoice.buffer.targ then
			ccolor = 0x009922
		end
		for n = 1, 22 do
			buffer.drawText(x1+f*23-25+n,y1-1,ccolor,"▄")
			buffer.drawText(x1+f*23-25+n,y1+10,ccolor,"▀")
		end
		buffer.drawRectangle(x1+f*23-24, y1, 22, 10, ccolor, 0, " ")
		buffer.drawImage(x1+f*23-23, y1, game._gui.rewardChoice.buffer.images[f])
	end
	ccolor = 0x4A4A4A
	if game._gui.rewardChoice.buffer.targ then
		game._function.drawItemDescription(x + game._gui.rewardChoice.w, y, game._function.getItemInfo(game._gui.rewardChoice.buffer.items[game._gui.rewardChoice.buffer.targ][1], game._gui.rewardChoice.buffer.items[game._gui.rewardChoice.buffer.targ][2]))
		ccolor = game._gui.rewardChoice.button1.c
	end
	game._gui.rewardChoice.button1.x = x + mathFloor(game._gui.rewardChoice.w / 2 - game._gui.rewardChoice.button1.w / 2)
	buffer.drawRectangle(game._gui.rewardChoice.button1.x, y + game._gui.rewardChoice.button1.y, game._gui.rewardChoice.button1.w, game._gui.rewardChoice.button1.h, ccolor, 0, " ")
	buffer.drawText(game._gui.rewardChoice.button1.x + mathFloor(game._gui.rewardChoice.button1.w / 2 - unicode.len(game._gui.rewardChoice.button1.t) / 2),y + game._gui.rewardChoice.button1.y + 1,0xFFFFFF,game._gui.rewardChoice.button1.t)
end

game._gui.rewardChoice.action["touch"] = function(ev)
	for f = 1, #game._gui.rewardChoice.buffer.items do
		if ev[5] == 0 and clicked(ev[3], ev[4], game._gui.rewardChoice.x+4+f*23-23, game._gui.rewardChoice.y + 2, game._gui.rewardChoice.x+4+f*23-2, game._gui.rewardChoice.y + 11) then
			game._gui.rewardChoice.buffer.targ = f
			break
		end
	end
	if ev[5] == 0 and clicked(ev[3], ev[4], game._gui.rewardChoice.button1.x, game._gui.rewardChoice.y + game._gui.rewardChoice.button1.y, game._gui.rewardChoice.button1.x + game._gui.rewardChoice.button1.w - 1, game._gui.rewardChoice.y + game._gui.rewardChoice.button1.y + game._gui.rewardChoice.button1.h - 1) and game._gui.rewardChoice.buffer.targ then
		game._function.addItem(game._gui.rewardChoice.buffer.items[game._gui.rewardChoice.buffer.targ][1], game._gui.rewardChoice.buffer.items[game._gui.rewardChoice.buffer.targ][2], true)
		game._data.windowThread = nil
		game._data.paused = false
		game._gui.rewardChoice.buffer.items = {}
		game._gui.rewardChoice.buffer.images = {}
		game._gui.rewardChoice.buffer.targ = nil
	end
end


-----------------------------Окно инвентарь------------------------------------------------------

local invTItem = 0
local invcTItem, showItemData = 0, false
local invIdx, invIdy = 1, 1

local itemInfo = {}

function game._function.getItemInfo(id, count)
	local subt
	count = count or 1
	local function giiwcAdd(t,c)
		tableInsert(itemInfo,{tostring(t),c})
	end

	if gid[id] then
		local itemType, itemsubtype = gid[id]["type"], gid[id]["subtype"]
		local ccolor
		itemInfo = {}
		giiwcAdd(gid[id]["name"], gid[id]["ncolor"] or 0xffffff)
		if itemType == 2 or itemType == 3 then -- Броня, оружие
			giiwcAdd(game._data.itemSubtypes[itemType][itemsubtype], 0xBCBCBC)
			giiwcAdd("Уровень "..tostring(gid[id]["lvl"]), 0xffffff)
		end
		if itemType == 3 then -- Оружие
			giiwcAdd("Скорость атаки: "..tostring(mathCeil((1/weaponHitRate[gid[id]["subtype"]])*10)/10).." уд./сек.", 0xEFEFEF)
			giiwcAdd("Дальность атаки: "..game._function.watds[gid[id]["subtype"]], 0xEFEFEF)
		end
		if itemType == 1 and itemsubtype == 1 then -- Предметы
			giiwcAdd("Уровень материала "..tostring(gid[id]["lvl"]), 0xffffff)
		end
		if itemType == 2 then -- Броня
			if gid[id]["props"]["pdef"] ~= 0 then
				giiwcAdd("Защита +"..tostring(gid[id]["props"]["pdef"]), 0xEFEFEF)
			end
			if gid[id]["props"]["mdef"] ~= 0 then
				giiwcAdd("Магическая защита +"..tostring(gid[id]["props"]["mdef"]), 0xEFEFEF)
			end
		elseif itemType == 3 then -- Оружие
			if gid[id]["props"]["phisat"] and gid[id]["props"]["phisat"] ~= 0 then
				giiwcAdd("Физическая атака "..gid[id]["props"]["phisat"][1].."-"..gid[id]["props"]["phisat"][2], 0xffffff)
			end
			if gid[id]["props"]["magat"] and gid[id]["props"]["magat"] ~= 0 then
				giiwcAdd("Магическая атака "..gid[id]["props"]["magat"][1].."-"..gid[id]["props"]["magat"][2], 0xffffff)
			end
		end
		if itemType == 2 or itemType == 3 or itemType == 4 then
			if itemType == 4 and gid[id]["subtype"] == 1 then
				giiwcAdd("Восстановить "..tostring(ged[1]["val"][gid[id]["lvl"]]).." ед. здоровья за 10 секунд", 0xEFEFEF)
			elseif itemType == 4 and gid[id]["subtype"] == 2 then
				giiwcAdd("Восстановить "..tostring(ged[2]["val"][gid[id]["lvl"]]).." ед. маны за 10 секунд", 0xEFEFEF)
			end
			if gid[id]["required"] then
				for k, v in pairs(gid[id]["required"]) do
					ccolor = 0xFFFFFF
					if gid[id]["required"][k] > CGD[game._player.id][k] then
						ccolor = 0xFF0000
					end
					giiwcAdd(game._data.itemReqNames[k]..v, ccolor)
				end
			end
			if itemType == 2 or itemType == 3 then
				local subt
				if gid[id]["props"]["dds"] ~= nil then
					for e = 1, #gid[id]["props"]["dds"] do
						subt = ""
						if gid[id]["props"]["dds"][e] and gid[id]["props"]["dds"][e][2] > 0 then
							if #game._data.itemStatsNames[gid[id]["props"]["dds"][e][1]] >= 2 then
								subt = game._data.itemStatsNames[gid[id]["props"]["dds"][e][1]][2]
							end
							giiwcAdd(game._data.itemStatsNames[gid[id]["props"]["dds"][e][1]][1].." + "..gid[id]["props"]["dds"][e][2]..subt,cp.blue)
						end
					end
				end
			end
		end
		local t1
		if gid[id]["description"] and gid[id]["description"] ~= "" then
			t1 = game._function.textWrap(gid[id]["description"], 30)
			for f = 1, #t1 do
				giiwcAdd(t1[f], 0xBCBCBC)
			end
		end
		subt = ""
			if count > 1 then
			subt = " ("..tostring(gid[id]["cost"]*count)..")"
			end
		giiwcAdd("Цена "..tostring(gid[id]["cost"])..subt, 0xffffff)
		return itemInfo
	end
	return {}
end

function game._function.drawItemDescription(x,y,source)
	if not source then
		source = {{"Неправильный предмет",0xFF0000}}
	end
	local w, h = 0, #source
	for f = 1, #source do
		if unicode.len(source[f][1]) > w then
			w = unicode.len(source[f][1])
		end
	end
	buffer.drawRectangle(mathMin(x-1,159-w), mathMin(y-1,49-h), w+2, h+2, 0x6B6B6B, 0, " ")
	game._function.unicodeFrame(mathMin(x-1,159-w), mathMin(y-1,49-h), w+2, h+2, 0x808080)
	for f = 1, #source do
		buffer.drawText(mathMin(x,160-w),mathMin(y+f-1,50-h+f-1),source[f][2],source[f][1])
	end
end

local itemInfo

game._function.inventory = {x=1, y=1, w=160, h=50, ax = 117, ay = 3, b1={x=2,y=47,w=14}, target = 0, action={}}

function game._function.inventory.draw()
local x, y, w, h = game._function.inventory.x, game._function.inventory.y, game._function.inventory.w, game._function.inventory.h
local ax, ay = game._function.inventory.ax, game._function.inventory.ay
local formula, xps, yps
local textRemoveItem = "Выбросить предмет(ы)"
buffer.drawRectangle(x, y, w, h, 0x9B9B9B, 0, " ")
buffer.drawRectangle(x, y, w, 1, 0x525252, 0, " ")
buffer.drawRectangle(x, y + h - 1, w, 1, 0x525252, 0, " ")
--buffer.drawRectangle(x, y+1, 105, 45, 0x767676, 0, " ")
--buffer.drawRectangle(x+106, y+1, 43, 45, 0x4A4A4A, 0, " ")
buffer.drawRectangle(x, y + 1, w - 2, h - 5, 0x4A4A4A, 0, " ")
 -- for f = 1, 5 do
 -- buffer.drawRectangle(x, y+1+(f*11-11), 105, 1, 0x4A4A4A, 0, " ")
 -- end
  -- for f = 1, 6 do
 -- buffer.drawRectangle(x+(f*21-21), y+1, 1, 45, 0x4A4A4A, 0, " ")
 -- end
 for f = 1, 4 do
  for i = 1, 2 do
   if iconImageBuffer[0][game._data.armorType[(f-1)*2+i]] then
   buffer.drawImage(ax + i * 21 - 21, 3 + f * 11 - 11, iconImageBuffer[0][game._data.armorType[(f-1)*2+i]])
   else
   buffer.drawRectangle(ax + i *21 - 21, 3 + f * 11 - 11, 20, 10, 0x00, 0, " ")
   end
  end
 end
buffer.drawText(x+1,y,0xC4C420,"●•. Монеты: "..tostring(CGD[game._player.id]["cash"]))
buffer.drawText(x+75,y,0xffffff,"Инвентарь")
buffer.drawText(x+152,y,0xffffff,"Закрыть")
 for y1 = 1, 4 do
  for x1 = 1, 5 do
  formula, xps, yps = (y1-1)*5+x1, x+1+x1*21-21, y+2+y1*11-11
   if CGD[game._player.id]["inventory"]["bag"][formula][1] ~= 0 and CGD[game._player.id]["inventory"]["bag"][formula][2] ~= 0 then
    if iconImageBuffer[formula] then
	 if gid[CGD[game._player.id]["inventory"]["bag"][formula][1]] then
	 buffer.drawImage(xps, yps, iconImageBuffer[formula])
	  if CGD[game._player.id]["inventory"]["bag"][formula][2] > 1 then
      buffer.drawRectangle(xps, yps+9, #tostring(CGD[game._player.id]["inventory"]["bag"][formula][2]), 1, 0x4A4A4A, 0, " ")
	  buffer.drawText(xps,yps+9,0xffffff,tostring(CGD[game._player.id]["inventory"]["bag"][formula][2]))
      end
	 else
	 buffer.drawImage(xps, yps, image.load(game._data.text.directory.."image/itemnotex.pic"))
	 end
    else
	buffer.drawRectangle(xps, yps, 20, 10, 0x00, 0, " ")
	end
   else
   buffer.drawRectangle(xps, yps, 20, 10, 0x767676, 0, " ")
   end
  end
 end
	for y1 = 1, 4 do
		for x1 = 1, 2 do
			formula, xps, yps = (y1-1)*2+x1, ax+x1*21-21, ay+y1*11-11
			if CGD[game._player.id]["inventory"]["weared"][game._data.armorType[formula]] ~= 0 then
				if iconImageBuffer[game._data.armorType[formula]] then
					if gid[CGD[game._player.id]["inventory"]["weared"][game._data.armorType[formula]]] then
						buffer.drawImage(xps, yps, iconImageBuffer[game._data.armorType[formula]])
					else
						buffer.drawImage(xps, yps, image.load(game._data.text.directory.."image/itemnotex.pic"))
					end
				else
					buffer.drawRectangle(xps, yps, 20, 10, 0x00, 0, " ")
				end
			end
		end
	end

	buffer.drawText(x + 1, y + 47,0x444444,sMSG3)

	if showItemData and invcTItem ~= 0 then
		buffer.drawRectangle(game._function.inventory.b1.x,game._function.inventory.b1.y,unicode.len(textRemoveItem),1,0x3c539e, 0, " ")
		buffer.drawText(game._function.inventory.b1.x,game._function.inventory.b1.y,0xFEFEFE,textRemoveItem)
		-- описание
		game._function.drawItemDescription(invIdx,invIdy,itemInfo)
	end

end

function game._function.getArmorType(id)
	if gid[id]["type"] == 2 then
		for k, v in pairs(game._data.armorTypeIds) do
			for n = 1, #v do
				if gid[id]["subtype"] == game._data.armorTypeIds[k][n] then
					return k
				end
			end
		end
	end
end

function game._function.getItemRequirement(id)
	local out = true
	if gid[id]["required"] then
		for k, v in pairs(gid[id]["required"]) do
			if gid[id]["required"][k] > CGD[game._player.id][k] then
				out = false
			end
		end
	else
		return true
	end
	return out
end

game._function.inventory.action["touch"] = function(ev)
	local x, y, w, h = game._function.inventory.x, game._function.inventory.y, game._function.inventory.w, game._function.inventory.h
	local ax, ay = game._function.inventory.ax, game._function.inventory.ay

	local formula, pItem, pType
	if clicked(ev[3],ev[4], x + w - 8, y, x + w - 1, y) then
		game._data.windowThread = "pause"
		iconImageBuffer = {}
	end
	-- кнопка выбросить предмет
	if showItemData and game._function.inventory.target ~= 0 and clicked(ev[3],ev[4],game._function.inventory.b1.x,game._function.inventory.b1.y,game._function.inventory.b1.x+game._function.inventory.b1.w,game._function.inventory.b1.y) then
		-- чистка памяти при утрате предмета
		if CGD[game._player.id]["inventory"]["bag"][game._function.inventory.target][1] >= game._config.reservedItemId then
			gid[CGD[game._player.id]["inventory"]["bag"][game._function.inventory.target][1]] = nil
		end
		-- пустая ячейка в инв.
		CGD[game._player.id]["inventory"]["bag"][game._function.inventory.target] = {0, 0}
		-- чистка ячейки буфера
		iconImageBuffer[game._function.inventory.target] = nil
		-- скрыть описание
		showItemData, game._function.inventory.target = false, 0
	end

	local fbParam = true
	local nwitemuwr, xps, yps
	for f = 1, 4 do
		for i = 1, 5 do
			xps, yps = 2 + i * 21 - 21, 3 + f * 11 - 11
			formula = (f - 1) * 5 + i
			if CGD[game._player.id]["inventory"]["bag"][formula][1] ~= 0 and CGD[game._player.id]["inventory"]["bag"][formula][2] ~= 0 then
				if clicked(ev[3],ev[4],xps,yps,xps+19,yps+9) then
				pItem = gid[CGD[game._player.id]["inventory"]["bag"][formula][1]]
					if ev[5] == 0 then
						invcTItem = CGD[game._player.id]["inventory"]["bag"][formula][1]
						game._function.inventory.target = formula
						invTItem = CGD[game._player.id]["inventory"]["bag"][formula][2]
						itemInfo = game._function.getItemInfo(CGD[game._player.id]["inventory"]["bag"][formula][1])
						showItemData = true
						invIdx, invIdy = ev[3], ev[4]
						fbParam = false
						break
					elseif ev[5] == 1 and gid[CGD[game._player.id]["inventory"]["bag"][formula][1]] then
				-- Броня
						if pItem["type"] == 2 and game._function.getItemRequirement(CGD[game._player.id]["inventory"]["bag"][formula][1]) then
							pType = game._function.getArmorType(CGD[game._player.id]["inventory"]["bag"][formula][1])
							if CGD[game._player.id]["inventory"]["weared"][pType] == 0 then
								CGD[game._player.id]["inventory"]["weared"][pType] = CGD[game._player.id]["inventory"]["bag"][formula][1]
								iconImageBuffer[pType] = image.load(game._data.text.directory.."itempic/"..game._data.itemIcons[gid[CGD[game._player.id]["inventory"]["bag"][formula][1]]["icon"]]..".pic")
								CGD[game._player.id]["inventory"]["bag"][formula][1] = 0
								CGD[game._player.id]["inventory"]["bag"][formula][2] = 0
								if iconImageBuffer[formula] ~= nil then
									iconImageBuffer[formula] = nil
								end
							else
								nwitemuwr = CGD[game._player.id]["inventory"]["weared"][pType]
								CGD[game._player.id]["inventory"]["weared"][pType] = CGD[game._player.id]["inventory"]["bag"][formula][1]
								iconImageBuffer[pType] = image.load(game._data.text.directory.."itempic/"..game._data.itemIcons[gid[CGD[game._player.id]["inventory"]["bag"][formula][1]]["icon"]]..".pic")
								CGD[game._player.id]["inventory"]["bag"][formula][1] = nwitemuwr
								CGD[game._player.id]["inventory"]["bag"][formula][2] = 1
								iconImageBuffer[formula] = image.load(game._data.text.directory.."itempic/"..game._data.itemIcons[gid[nwitemuwr]["icon"]]..".pic")
							end
				-- Оружие
						elseif pItem["type"] == 3 and game._function.getItemRequirement(CGD[game._player.id]["inventory"]["bag"][formula][1]) then
							if CGD[game._player.id]["inventory"]["weared"]["weapon"] == 0 then
								CGD[game._player.id]["inventory"]["weared"]["weapon"] = CGD[game._player.id]["inventory"]["bag"][formula][1]
								iconImageBuffer["weapon"] = image.load(game._data.text.directory.."itempic/"..game._data.itemIcons[gid[CGD[game._player.id]["inventory"]["bag"][formula][1]]["icon"]]..".pic")
								CGD[game._player.id]["inventory"]["bag"][formula][1] = 0
								CGD[game._player.id]["inventory"]["bag"][formula][2] = 0
								if iconImageBuffer[formula] ~= nil then
									iconImageBuffer[formula] = nil
								end
							else
								nwitemuwr = CGD[game._player.id]["inventory"]["weared"]["weapon"]
								CGD[game._player.id]["inventory"]["weared"]["weapon"] = CGD[game._player.id]["inventory"]["bag"][formula][1]
								iconImageBuffer["weapon"] = image.load(game._data.text.directory.."itempic/"..game._data.itemIcons[gid[CGD[game._player.id]["inventory"]["bag"][formula][1]]["icon"]]..".pic")
								CGD[game._player.id]["inventory"]["bag"][formula][1] = nwitemuwr
								CGD[game._player.id]["inventory"]["bag"][formula][2] = 1
								iconImageBuffer[formula] = image.load(game._data.text.directory.."itempic/"..game._data.itemIcons[gid[nwitemuwr]["icon"]]..".pic")
							end
				-- Сундук, коробка
						elseif pItem["type"] == 5 then
							for t = 1, #pItem["props"] do
								if 10^3-pItem["props"][t][3]*10 <= game._function.random(1,10^3) then
									game._function.addItem(pItem["props"][t][1],pItem["props"][t][2],true)
									break
								end
							end
							game._function.textmsg3("Использован предмет "..pItem["name"])
							CGD[game._player.id]["inventory"]["bag"][formula][2] = CGD[game._player.id]["inventory"]["bag"][formula][2] - 1
				-- Телепорт
						elseif pItem["type"] == 6 then
							CGD[game._player.id]["x"], cGlobalx, cBackgroundPos = 1, 1, 1
							game._function.textmsg3("Использован предмет "..pItem["name"])
							CGD[game._player.id]["inventory"]["bag"][formula][2] = CGD[game._player.id]["inventory"]["bag"][formula][2]	- 1
				-- Зелье
						elseif pItem["type"] == 4 and CGD[game._player.id]["lvl"] >= pItem["required"]["lvl"] then
							if pItem["subtype"] == 1 then
								game._function.addUnitEffect(game._player.id,1,pItem["lvl"])
								CGD[game._player.id]["inventory"]["bag"][formula][2] = CGD[game._player.id]["inventory"]["bag"][formula][2] - 1
							elseif pItem["subtype"] == 2 then
								game._function.addUnitEffect(game._player.id,2,pItem["lvl"])
								CGD[game._player.id]["inventory"]["bag"][formula][2] = CGD[game._player.id]["inventory"]["bag"][formula][2] - 1
							end
							game._function.textmsg3("Использован предмет "..pItem["name"])
				-- Яйцо
						elseif pItem["type"] == 8 then
							tableInsert(CGD[game._player.id]["petcage"], {["id"] = pItem["subtype"], ["lvl"] = gud[pItem["subtype"]]["lvl"], ["cxp"] = 0, ["chp"] = 1})
							removeItemFromInventory(formula, 1)
						end
						nwitemuwr = nil
						break
					end
				end
			end
			formula = nil
		end
	end
	for f = 1, 4 do
		for i = 1, 2 do
			formula, xps, yps = (f - 1) * 2 + i, ax + i * 21 - 21, ay + f * 11 - 11
			if CGD[game._player.id]["inventory"]["weared"][game._data.armorType[formula]] ~= 0 then
				if clicked(ev[3],ev[4],xps,yps,xps+19,yps+9) then
					if ev[5] == 0 then
						invcTItem = CGD[game._player.id]["inventory"]["weared"][game._data.armorType[formula]]
						invTItem = 1
						showItemData = true
						itemInfo = game._function.getItemInfo(CGD[game._player.id]["inventory"]["weared"][game._data.armorType[formula]])
						invIdx, invIdy = ev[3], ev[4]
						fbParam = false
						break
					elseif ev[5] == 1 then
						nwitemuwr = game._function.addItem(CGD[game._player.id]["inventory"]["weared"][game._data.armorType[formula]],1)
						-- iconImageBuffer[nwitemuwr] = image.load(game._data.text.directory.."itempic/"..game._data.itemIcons[gid[CGD[game._player.id]["inventory"]["weared"][game._data.armorType[formula]]]["icon"]]..".pic")
						CGD[game._player.id]["inventory"]["weared"][game._data.armorType[formula]] = 0
						if iconImageBuffer[game._data.armorType[formula]] ~= nil then
							iconImageBuffer[game._data.armorType[formula]] = nil
						end
						nwitemuwr = nil
					end
				end
			else
				if clicked(ev[3],ev[4],xps,yps,xps+19,yps+9) then
					if ev[5] == 0 then
						invcTItem = 1
						showItemData = true
						itemInfo = {{game._function.getWitemTypeName(game._data.armorType[formula]),0xFFFFFF}}
						invIdx, invIdy = ev[3], ev[4]
						fbParam = false
					end
				end
			end
			formula = nil
		end
   end

	if fbParam then
		game._function.inventory.target = 0
		invTItem = 0
		showItemData = false
		invIdx, invIdy = 1, 1
	end
	game._function.UpdatePlayerStats()
end


-----------------------------Окно торговля------------------------------------------------------

function game._function.genitiveWordEnding(rstring, number)
	local numokn, numpokn, letter = tonumber(string.sub(tostring(number),-1,-1)), tonumber(string.sub(tostring(number),-2,-2)), ""
	if numokn == 1 then
		letter = "а"
	elseif numokn >= 2 and numokn <= 4 then
		letter = "ы"
	elseif numokn >= 5 and numokn <= 9 then
		letter = ""
	end
	if numpokn == 1 or numokn == 0 then
		letter = ""
	end
	return rstring .. letter
end

game._function.tradew = {
	action = {},
	loaded = {},
	titem = 0,
	titemcount = 1,
	sect = 1,
	tScrl = 1,
	torg = 1,
	asmt = {},
	x = 1,
	y = 1,
	w = 160,
	h = 50,
	cWidth = 50,
	cHeight = 15
}

game._function.tradew.twx = mathFloor(80-game._function.tradew.cWidth/2)
game._function.tradew.twy = mathFloor(25-game._function.tradew.cHeight/2)

function game._function.tradew.draw()
local x, y = game._function.tradew.x, game._function.tradew.y
buffer.drawRectangle(x, y, game._function.tradew.w, game._function.tradew.h, 0x9B9B9B, 0, " ")
buffer.drawRectangle(x, y, game._function.tradew.w, 1, 0x525252, 0, " ")
buffer.drawRectangle(x, y+1, game._function.tradew.w, 3, 0x747474, 0, " ")
local hclr
local t = "Торговля"
buffer.drawText(mathMax(80-(unicode.len(t)/2), 0), y, 0xffffff, t)
buffer.drawText(x+game._function.tradew.w-9,y,0xffffff,"Закрыть")
buffer.drawText(x+1,y,0xffffff,"Монеты "..CGD[game._player.id]["cash"])
hclr = {"Перейти к продаже","Перейти к покупке"}
buffer.drawRectangle(x+118, y+1, unicode.len(hclr[game._function.tradew.torg])+2, 3, 0x8a8a8a, 0, " ")
buffer.drawText(x+119, y+2,0xffffff,hclr[game._function.tradew.torg])
 if game._function.tradew.torg == 1 then
 buffer.drawText(x+1,y+3,0xC2C2C2,"Наименование")
 buffer.drawText(x+65,y+3,0xC2C2C2,"Цена за единицу")
  for f = 1, #game._function.tradew.loaded do
  if game._function.tradew.sect == f then hclr = 0x525252 else hclr = 0x606060 end
  buffer.drawRectangle(x+1+f*26-26, y+1, 25, 1, hclr, 0, " ")
  buffer.drawText(x+1+f*26-26, y+1, 0xCCCCCC, unicode.sub(game._function.tradew.loaded[f]["s_name"],1,25))
  end
  for f = 1, mathMin(#game._function.tradew.loaded[game._function.tradew.sect], 24) do
  if f+4*game._function.tradew.tScrl-4 == game._function.tradew.titem then
  buffer.drawRectangle(x+1,y+4+f*2-2, 160, 3, 0x818181, 0, " ")
  end
  end
  for f = 1, mathMin(#game._function.tradew.loaded[game._function.tradew.sect]+1, 24) do
   buffer.drawText(x+1,y+4+f*2-2,0xffffff,"═")
   buffer.drawText(x+2,y+4+f*2-2,0xffffff,string.rep("─",157))
  end
  for f = 1, mathMin(#game._function.tradew.loaded[game._function.tradew.sect], 24) do
  buffer.drawText(x+1,y+4+f*2-1,0xffffff,gid[game._function.tradew.loaded[game._function.tradew.sect][f+4*game._function.tradew.tScrl-4]["item"]]["name"])
  buffer.drawText(x+65,y+4+f*2-1,0xffffff,tostring(game._function.tradew.loaded[game._function.tradew.sect][f+4*game._function.tradew.tScrl-4]["cost"])..game._function.genitiveWordEnding(" монет",game._function.tradew.loaded[game._function.tradew.sect][f+4*game._function.tradew.tScrl-4]["cost"]))
  end
  local tn = "Купить"
  if game._function.tradew.titem > 0 then
  local clr, smx, smy = 0xCCCCCC, game._function.tradew.twx, game._function.tradew.twy
  buffer.drawRectangle(smx, smy, game._function.tradew.cWidth, game._function.tradew.cHeight, 0x828282, 0, " ")
  game._function.unicodeFrame(smx, smy, game._function.tradew.cWidth, game._function.tradew.cHeight, 0x4c4c4c)
  buffer.drawRectangle(smx-23, smy, 22, 12, 0x828282, 0, " ")
  buffer.drawImage(smx-22, smy+1, iconImageBuffer[1])
  buffer.drawText(smx+game._function.tradew.cWidth-2, smy, 0x4c4c4c, "X")
  buffer.drawText(smx+(game._function.tradew.cWidth/2-unicode.len(gid[game._function.tradew.loaded[game._function.tradew.sect][game._function.tradew.titem]["item"]]["name"])/2), smy+1, clr, gid[game._function.tradew.loaded[game._function.tradew.sect][game._function.tradew.titem]["item"]]["name"])
  buffer.drawText(smx+1,smy+2, clr, "Покупка предмета")
  buffer.drawText(smx+1,smy+3, clr, "Количество:")
  buffer.drawRectangle(smx+13, smy+3, #tostring(game._function.tradew.titemcount)+4, 1, 0x616161, 0, " ")
  buffer.drawText(smx+13,smy+3, clr, "+ "..game._function.tradew.titemcount.." -")
  buffer.drawText(smx+1,smy+4, clr, "Цена: "..game._function.tradew.loaded[game._function.tradew.sect][game._function.tradew.titem]["cost"]..game._function.genitiveWordEnding(" монет",game._function.tradew.loaded[game._function.tradew.sect][game._function.tradew.titem]["cost"]))
  local td = clr
  if game._function.tradew.titemcount*game._function.tradew.loaded[game._function.tradew.sect][game._function.tradew.titem]["cost"] > CGD[game._player.id]["cash"] then td = 0xb71202 end
  buffer.drawText(smx+1,smy+5, td, "Стоимость: "..tostring(game._function.tradew.titemcount*game._function.tradew.loaded[game._function.tradew.sect][game._function.tradew.titem]["cost"])..game._function.genitiveWordEnding(" монет",game._function.tradew.titemcount*game._function.tradew.loaded[game._function.tradew.sect][game._function.tradew.titem]["cost"]))
  buffer.drawRectangle(smx, smy+game._function.tradew.cHeight, game._function.tradew.cWidth, 3, 0x0054cb5, 0, " ")
  buffer.drawText(smx+(game._function.tradew.cWidth/2-unicode.len(tn)/2), smy+game._function.tradew.cHeight+1, clr, tn)
  game._function.drawItemDescription(smx+game._function.tradew.cWidth+2,smy+1,itemInfo)
  end
 elseif game._function.tradew.torg == 2 then
  buffer.drawText(x+2,y+3,0xC2C2C2,"#")
  buffer.drawText(x+5,y+3,0xC2C2C2,"Наименование")
  buffer.drawText(x+50,y+3,0xC2C2C2,"Количество")
  buffer.drawText(x+70,y+3,0xC2C2C2,"Цена за единицу")
  game._function.tradew.asmt = {}
  for f = 1, #CGD[game._player.id]["inventory"]["bag"] do
   if CGD[game._player.id]["inventory"]["bag"][f][1] ~= 0 and CGD[game._player.id]["inventory"]["bag"][f][2] ~= 0 then
   tableInsert(game._function.tradew.asmt,CGD[game._player.id]["inventory"]["bag"][f])
   end
  end
  for f = 1, 25 do
  buffer.drawRectangle(x+1,y+5+f*2-2,85,1,0x8C8C8C, 0, " ")
  end
  for f = 1, #game._function.tradew.asmt do
  buffer.drawText(x+2,y+4+f,0xDDDDDD,tostring(f))
  buffer.drawText(x+5,y+4+f,gid[game._function.tradew.asmt[f][1]]["ncolor"] or 0xffffff, "► "..gid[game._function.tradew.asmt[f][1]]["name"])
  buffer.drawText(x+50,y+4+f,0xDDDDDD,tostring(game._function.tradew.asmt[f][2]))
  buffer.drawText(x+70,y+4+f,0xDDDDDD,gid[game._function.tradew.asmt[f][1]]["cost"]..game._function.genitiveWordEnding(" монет",gid[game._function.tradew.asmt[f][1]]["cost"]))
  end
   if game._function.tradew.titem > 0 then
   local ttext = "Продать предмет"
   buffer.drawRectangle(90, 6, 22, 12, 0x828282, 0, " ")
   buffer.drawImage(91, 7, iconImageBuffer[1])
   game._function.drawItemDescription(91,20,itemInfo)
   buffer.drawText(118,6,0xffffff,"Количество")
   buffer.drawRectangle(118, 7, 10, 3, 0x828282, 0, " ")
   buffer.drawText(119,8,0xffffff,"┼")
   buffer.drawText(126,8,0xffffff,"—")
   buffer.drawText(121,9,0xffffff,"Макс.")
   buffer.drawRectangle(121, 8, 4, 1, 0x717171, 0, " ")
   buffer.drawText(121,8,0xffffff,tostring(game._function.tradew.titemcount))
   buffer.drawRectangle(130, 7, unicode.len(ttext)+2, 3, 0x00447C, 0, " ")
   buffer.drawText(131,8,0xffffff,ttext)
   end
 end
end

game._function.tradew.action["touch"] = function(ev)
 if ev[5] == 0 and clicked(ev[3],ev[4],game._function.tradew.x+game._function.tradew.w-8,game._function.tradew.y,game._function.tradew.x+game._function.tradew.w-1,game._function.tradew.y) then
 game._function.tradew.titem = 0
 game._function.tradew.titemcount = 1
 game._function.tradew.sect = 1
 game._function.tradew.tScrl = 1
 game._function.tradew.torg = 1
 game._function.tradew.asmt = {}
 game._data.windowThread = nil
 game._gui.NPCDialog.currentDialog = nil
 game._data.paused = false
 itemInfo = nil
 end
    if ev[5] == 0 and game._function.tradew.torg == 1 and game._function.tradew.titem == 0 and clicked(ev[3],ev[4],119,2,136,4) then
	game._function.tradew.torg = 2
	game._function.tradew.titem = 0
    elseif ev[5] == 0 and game._function.tradew.torg == 2 and clicked(ev[3],ev[4],119,2,136,4) then
	game._function.tradew.torg = 1
	game._function.tradew.titem = 0
	game._function.tradew.titemcount = 1
    iconImageBuffer = {}
	end
   if game._function.tradew.torg == 2 then
    for f = 1, #game._function.tradew.asmt do
	 if ev[5] == 0 and clicked(ev[3],ev[4],2,5+f,85,5+f) then
	 iconImageBuffer[1] = image.load(game._data.text.directory.."itempic/"..game._data.itemIcons[gid[game._function.tradew.asmt[f][1]]["icon"]]..".pic")
	 itemInfo = game._function.getItemInfo(game._function.tradew.asmt[f][1])
	 game._function.tradew.titem = f
	 game._function.tradew.titemcount = 1
	 end
	end
	if game._function.tradew.titem > 0 then
	 if ev[5] == 0 then
	  if clicked(ev[3],ev[4],119,8,119,8) and game._function.tradew.titemcount < game._function.tradew.asmt[game._function.tradew.titem][2] then
	  game._function.tradew.titemcount = game._function.tradew.titemcount + 1
	  elseif clicked(ev[3],ev[4],126,8,126,8) and game._function.tradew.titemcount > 1 then
	  game._function.tradew.titemcount = game._function.tradew.titemcount - 1
	  elseif clicked(ev[3],ev[4],121,9,125,9) then
	  game._function.tradew.titemcount = game._function.tradew.asmt[game._function.tradew.titem][2]
	  end
	  if clicked(ev[3],ev[4],130,7,145,9) then
	   for d = 1, #CGD[game._player.id]["inventory"]["bag"] do
		if CGD[game._player.id]["inventory"]["bag"][d][1] == game._function.tradew.asmt[game._function.tradew.titem][1] then
		CGD[game._player.id]["cash"] = CGD[game._player.id]["cash"] + game._function.tradew.titemcount*gid[game._function.tradew.asmt[game._function.tradew.titem][1]]["cost"]
		CGD[game._player.id]["inventory"]["bag"][d][2] = CGD[game._player.id]["inventory"]["bag"][d][2] - game._function.tradew.titemcount
		for h = 1, #CGD[game._player.id]["inventory"]["bag"] do if CGD[game._player.id]["inventory"]["bag"][h][2] <= 0 then CGD[game._player.id]["inventory"]["bag"][h][1] = 0 end end
		iconImageBuffer = {}
		game._function.tradew.titem = 0
		game._function.tradew.titemcount = 1
	    break
		end
	   end
	  end
	 end
	end
   elseif game._function.tradew.torg == 1 and game._function.tradew.titem == 0 then
    for c = 1, #game._function.tradew.loaded do
	 if ev[5] == 0 and clicked(ev[3],ev[4],2+c*26-26, 2, 2+c*25, 2) then
	 game._function.tradew.sect = c
	 break
	 end
	end
	for c = 1, mathMin(#game._function.tradew.loaded[game._function.tradew.sect], 24) do
     if clicked(ev[3],ev[4],2,5+c*2-2,160,5+c*2) then
	 game._function.tradew.titem = c+4*game._function.tradew.tScrl-4
	 itemInfo = game._function.getItemInfo(game._function.tradew.loaded[game._function.tradew.sect][game._function.tradew.titem]["item"])
	 iconImageBuffer = {[1]=image.load(game._data.text.directory.."itempic/"..game._data.itemIcons[gid[game._function.tradew.loaded[game._function.tradew.sect][game._function.tradew.titem]["item"]]["icon"]]..".pic")}
	 break
	 end
    end
   elseif game._function.tradew.torg == 1 and game._function.tradew.titem > 0 then
    if ev[5] == 0 and gid[game._function.tradew.loaded[game._function.tradew.sect][game._function.tradew.titem]["item"]]["stackable"] and game._function.tradew.titemcount < 100 and clicked(ev[3],ev[4],game._function.tradew.twx+13, game._function.tradew.twy+3,game._function.tradew.twx+13, game._function.tradew.twy+3) then -- +
    game._function.tradew.titemcount = game._function.tradew.titemcount + 1
    elseif ev[5] == 0 and game._function.tradew.titemcount > 1 and clicked(ev[3],ev[4],game._function.tradew.twx+16+#tostring(game._function.tradew.titemcount), game._function.tradew.twy+3,game._function.tradew.twx+16+#tostring(game._function.tradew.titemcount), game._function.tradew.twy+3) then -- -
    game._function.tradew.titemcount = game._function.tradew.titemcount - 1
    end
    -- купить
	if clicked(ev[3],ev[4],game._function.tradew.twx,game._function.tradew.twy+game._function.tradew.cHeight,game._function.tradew.twx+game._function.tradew.cWidth,game._function.tradew.twy+game._function.tradew.cHeight+3) and CGD[game._player.id]["cash"] >= game._function.tradew.titemcount*game._function.tradew.loaded[game._function.tradew.sect][game._function.tradew.titem]["cost"] then
	CGD[game._player.id]["cash"] = CGD[game._player.id]["cash"] - game._function.tradew.titemcount*game._function.tradew.loaded[game._function.tradew.sect][game._function.tradew.titem]["cost"]
	game._function.addItem(game._function.tradew.loaded[game._function.tradew.sect][game._function.tradew.titem]["item"],game._function.tradew.titemcount)
	game._function.tradew.titem = 0
	game._function.tradew.titemcount = 1
	iconImageBuffer = {}
	end
	-- закрыть
	if clicked(ev[3],ev[4],game._function.tradew.twx+game._function.tradew.cWidth-2, game._function.tradew.twy, game._function.tradew.twx+game._function.tradew.cWidth-2, game._function.tradew.twy) then
	game._function.tradew.titem = 0
	game._function.tradew.titemcount = 1
	iconImageBuffer = {}
	end
   end
end

-----------------------------Окно создание------------------------------------------------------

game._function.craftw = {
	action = {},
	loaded = {},
	titem = 0,
	titemcount = 1,
	sect = 1,
	tScrl = 1,
	x = 1,
	y = 1,
	w = 160,
	h = 50,
	cWidth = 50,
	cHeight = 15,
	bWidth = 26
}

game._function.craftw.twx = mathFloor(80-game._function.craftw.cWidth/2)
game._function.craftw.twy = mathFloor(25-game._function.craftw.cHeight/2)

function game._function.craftw.draw()
	local x, y = game._function.craftw.x, game._function.craftw.y
	
	buffer.drawRectangle(x, y, game._function.craftw.w, game._function.craftw.h, 0x9B9B9B, 0, " ")
	buffer.drawRectangle(x, y, game._function.craftw.w, 1, 0x525252, 0, " ")
	buffer.drawRectangle(x, y+1, game._function.craftw.w, 3, 0x747474, 0, " ")
	local t = "Создание предметов"
	buffer.drawText(mathMax(80-(unicode.len(t)/2), 0), y, 0xffffff, t)
	buffer.drawText(x+1,y+3,0xC2C2C2,"Наименование")
	buffer.drawText(x+65,y+3,0xC2C2C2,"Шанс создания")
	buffer.drawText(x+130,y+3,0xC2C2C2,"Цена")
	buffer.drawText(x+game._function.craftw.w-9,y,0xffffff,"Закрыть")
buffer.drawText(x+1,y+2,0xffffff,"Монеты "..CGD[game._player.id]["cash"])
 --------------
	local t1, n1, hclr
	for i = 1, 2 do
		for f = 1, 5 do
			n1 = (i-1)*5+f
			if game._function.craftw.loaded[n1] then
				t1 = unicode.sub(game._function.craftw.loaded[n1]["s_name"],1,game._function.craftw.bWidth-1)
				if game._function.craftw.sect == f then
					hclr = 0x525252
				else
					hclr = 0x606060
				end
				buffer.drawRectangle(x+1+f*game._function.craftw.bWidth-game._function.craftw.bWidth, y+i, game._function.craftw.bWidth-1, 1, hclr, 0, " ")
				buffer.drawText(x+1+f*game._function.craftw.bWidth-game._function.craftw.bWidth, y+i, 0xCCCCCC, t1)
			end
		end
	end

 for f = 1, mathMin(#game._function.craftw.loaded[game._function.craftw.sect], 24) do
 if f+4*game._function.craftw.tScrl-4 == game._function.craftw.titem then buffer.drawRectangle(x+1,y+4+f*2-2, 160, 3, 0x818181, 0, " ") end
 end
  for f = 1, mathMin(#game._function.craftw.loaded[game._function.craftw.sect]+1, 24) do
   buffer.drawText(x+1,y+4+f*2-2,0xffffff,"═")
   buffer.drawText(x+2,y+4+f*2-2,0xffffff,string.rep("─",157))
  end
 for f = 1, mathMin(#game._function.craftw.loaded[game._function.craftw.sect], 24) do
 buffer.drawText(x+1,y+4+f*2-1,0xffffff,gid[game._function.craftw.loaded[game._function.craftw.sect][f+4*game._function.craftw.tScrl-4]["item"]]["name"])
 buffer.drawText(x+65,y+4+f*2-1,0xffffff,tostring(game._function.craftw.loaded[game._function.craftw.sect][f+4*game._function.craftw.tScrl-4]["chance"]).."%")
 buffer.drawText(x+130,y+4+f*2-1,0xffffff,tostring(game._function.craftw.loaded[game._function.craftw.sect][f+4*game._function.craftw.tScrl-4]["cost"])..game._function.genitiveWordEnding(" монет",game._function.craftw.loaded[game._function.craftw.sect][f+4*game._function.craftw.tScrl-4]["cost"]))
 end
 if game._function.craftw.titem ~= 0 then
 local clr, smx, smy = 0xCCCCCC, game._function.craftw.twx, game._function.craftw.twy
 buffer.drawRectangle(smx, smy, game._function.craftw.cWidth, game._function.craftw.cHeight, 0x828282, 0, " ")
 game._function.unicodeFrame(smx, smy, game._function.craftw.cWidth, game._function.craftw.cHeight, 0x4c4c4c)
 buffer.drawRectangle(smx-23, smy, 22, 12, 0x828282, 0, " ")
 buffer.drawImage(smx-22, smy+1, iconImageBuffer[1])
 buffer.drawText(smx+game._function.craftw.cWidth-2, smy, 0x4c4c4c, "X")
 buffer.drawText(smx+(mathFloor(game._function.craftw.cWidth/2-unicode.len(gid[game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["item"]]["name"])/2)), smy+1, clr, gid[game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["item"]]["name"])
 buffer.drawText(smx+1,smy+2, clr, "Создание предмета")
 buffer.drawText(smx+1,smy+3, clr, "Количество:")
 buffer.drawRectangle(smx+13, smy+3, #tostring(game._function.craftw.titemcount)+4, 1, 0x616161, 0, " ")
 buffer.drawText(smx+13,smy+3, clr, "+ "..game._function.craftw.titemcount.." -")
 local td
 if game._function.craftw.titemcount*game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["cost"] <= CGD[game._player.id]["cash"] then td = clr else td = 0xb71202 end
 buffer.drawText(smx+1,smy+4, td, "Стоимость: "..tostring(game._function.craftw.titemcount*game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["cost"])..game._function.genitiveWordEnding(" монет",game._function.craftw.titemcount*game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["cost"]))
 buffer.drawText(smx+1,smy+5, clr, "Шанс создания: "..game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["chance"].."%")
 buffer.drawText(smx+1,smy+6, clr, "Шанс улучшения: "..tostring(game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["achance"]).."%")
 buffer.drawText(smx+1,smy+7, clr, "Требуются предметы:")
 local tcl, tcc = nil, 0
  for i = 1, mathMin(#game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["recipe"], 5) do
  if game._function.checkItemInBag(game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["recipe"][i][1]) >= game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["recipe"][i][2]*game._function.craftw.titemcount then tcl = 0xdcdcdc; tcc = tcc + 1 else tcl = 0x575757 end
  buffer.drawText(smx+1,smy+7+i, tcl, "▸"..gid[game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["recipe"][i][1]]["name"].." ("..game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["recipe"][i][2]*game._function.craftw.titemcount..")")
  end
 tcl = 0x0054cb5
 if #game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["recipe"] > tcc or td == 0xb71202 then tcl = 0x7B7B7B end
 buffer.drawRectangle(smx, smy+game._function.craftw.cHeight, game._function.craftw.cWidth, 3, tcl, 0, " ")
 buffer.drawText(smx+18, smy+game._function.craftw.cHeight+1, clr, "Создать предмет")
 game._function.drawItemDescription(smx+game._function.craftw.cWidth+2,smy+1,itemInfo)
 end
end

game._function.craftw.action["touch"] = function(ev)
local checkVar1, Citem
 if ev[5] == 0 and clicked(ev[3],ev[4],game._function.craftw.x+game._function.craftw.w-8,game._function.craftw.y,game._function.craftw.x+game._function.craftw.w-1,game._function.craftw.y) then
 game._function.craftw.titem = 0
 game._function.craftw.titemcount = 1
 game._function.craftw.sect = 1
 game._function.craftw.tScrl = 1
 game._data.windowThread = nil
 game._gui.NPCDialog.currentDialog = nil
 game._data.paused = false
 itemInfo = nil
 end
   if game._function.craftw.titem == 0 then
	-- targ section
	for i = 1, 2 do
		for f = 1, 5 do
			if game._function.craftw.loaded[(i-1)*5+f] then
				if ev[5] == 0 and clicked(ev[3],ev[4],game._function.craftw.x+1+f*game._function.craftw.bWidth-game._function.craftw.bWidth, game._function.craftw.y + i, game._function.craftw.x+1+f*(game._function.craftw.bWidth-1), game._function.craftw.y + i) then
					game._function.craftw.sect = (i-1)*5+f
				end
			end
		end
	end

	-- targ item
	for c = 1, mathMin(#game._function.craftw.loaded[game._function.craftw.sect], 24) do
     if clicked(ev[3],ev[4],2,5+c*2-2,160,5+c*2) then
	 game._function.craftw.titem = c+4*game._function.tradew.tScrl-4
	 itemInfo = game._function.getItemInfo(game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["item"])
	 iconImageBuffer[1] = image.load(game._data.text.directory.."itempic/"..game._data.itemIcons[gid[game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["item"]]["icon"]]..".pic")
	 break
	 end
    end
   else
    if ev[5] == 0 and gid[game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["item"]]["stackable"] and game._function.craftw.titemcount < 100 and clicked(ev[3],ev[4],game._function.craftw.twx+13, game._function.craftw.twy+3,game._function.craftw.twx+13, game._function.craftw.twy+3) then
    game._function.craftw.titemcount = game._function.craftw.titemcount + 1
    elseif ev[5] == 0 and game._function.craftw.titemcount > 1 and clicked(ev[3],ev[4],game._function.craftw.twx+16+#tostring(game._function.craftw.titemcount), game._function.craftw.twy+3,game._function.craftw.twx+16+#tostring(game._function.craftw.titemcount), game._function.craftw.twy+3) then
    game._function.craftw.titemcount = game._function.craftw.titemcount - 1
    end
    if clicked(ev[3],ev[4],game._function.craftw.twx,game._function.craftw.twy+game._function.craftw.cHeight,game._function.craftw.twx+game._function.craftw.cWidth,game._function.craftw.twy+game._function.craftw.cHeight+3) and CGD[game._player.id]["cash"] >= game._function.craftw.titemcount*game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["cost"] then
	 -- нажатие на кнопку 'создать предмет'
	 checkVar1 = true
	 for i = 1, #game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["recipe"] do
	  if game._function.checkItemInBag(game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["recipe"][i][1]) < game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["recipe"][i][2]*game._function.craftw.titemcount then
	  checkVar1 = false
	  end
	 end
	if game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["cost"] > CGD[game._player.id]["cash"] then checkVar1 = false end
	 if checkVar1 then
	  for d = 1, #game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["recipe"] do
	   for i = 1, #CGD[game._player.id]["inventory"]["bag"] do
	    if CGD[game._player.id]["inventory"]["bag"][i][1] == game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["recipe"][d][1] then
	    CGD[game._player.id]["inventory"]["bag"][i][2] = CGD[game._player.id]["inventory"]["bag"][i][2] - game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["recipe"][d][2]*game._function.craftw.titemcount
	    if CGD[game._player.id]["inventory"]["bag"][i][2] == 0 then CGD[game._player.id]["inventory"]["bag"][i][1] = 0 end
		break
		end
	   end
	  end
	 for d = 1, game._function.craftw.titemcount do
	  Citem = game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["item"]
	  CGD[game._player.id]["cash"] = CGD[game._player.id]["cash"] - game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["cost"]
       if Citem ~= nil and 10^10-game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["chance"]*10^10 <= game._function.random(1,10^10) then
       if 10^10-(game._function.craftw.loaded[game._function.craftw.sect][game._function.craftw.titem]["achance"] or 0)*10^10 <= game._function.random(1,10^10) then Citem = createNewItem(Citem) end
       game._function.addItem(Citem,1,true)
	   end
	  Citem = nil
	  end
	 game._function.craftw.titem = 0
	 game._function.craftw.titemcount = 1
	 iconImageBuffer = {}
	 end
	end
	if clicked(ev[3],ev[4],game._function.craftw.twx+game._function.craftw.cWidth-2, game._function.craftw.twy,game._function.craftw.twx+game._function.craftw.cWidth-2, game._function.craftw.twy) then
	game._function.craftw.titem = 0
	game._function.craftw.titemcount = 1
	iconImageBuffer = {}
	end
   end
end

-----------------------------Окно "YOU DEAD"------------------------------------------------------

game._function.ydw = {
	w=40,
	h=24,
	x=1,
	y=1,
	action={},
	[1]={
		"Продолжить",
		f=function()
			local xpdec = mathFloor(CGD[game._player.id]["mxp"]*game._function.random(2*(10/math.sqrt(CGD[game._player.id]["lvl"]))*100,5*(10/math.sqrt(CGD[game._player.id]["lvl"]))*100)*0.0001)
			for f=1,#CGD[game._player.id]["inventory"]["bag"] do
				if game._function.random(0,100) <= 1 then
					CGD[game._player.id]["inventory"]["bag"][f][2] = CGD[game._player.id]["inventory"]["bag"][f][2] - 1
				end
			end
			CGD[game._player.id]["cint"] = nil
			game._function.loadWorld(world[world.current].drespawn)
			game._function.teleport(world[world.current].drx)
			game._function.UpdatePlayerStats()
			CGD[game._player.id]["chp"] = CGD[game._player.id]["mhp"]
			CGD[game._player.id]["cmp"] = CGD[game._player.id]["mmp"]
			if CGD[game._player.id]["cxp"] > xpdec then
				CGD[game._player.id]["cxp"] = CGD[game._player.id]["cxp"] - xpdec
			end
			game._player.usepmx = false
			pmov = 0
			CGD[game._player.id]["image"] = 0
			CGD[game._player.id]["effects"] = {}
			CGD[game._player.id]["living"] = true
			game._data.windowThread = nil
			game._data.paused = false
		end
		},
	[2]={
		"Загрузить игру",
		f=function()
			game._gui.mainMenu.open(2)
		end
		},
	[3]={
		"Выйти в меню",
		f=function()
			game._gui.mainMenu.open(0)
		end
		}
}

function game._function.ydw.draw()
game._data.paused = true
CGD[game._player.id]["target"] = nil
game._data.windowThread = "game._function.ydw"
buffer.drawRectangle(1, 1, mxw, mxh, 0x6B6B6B, 0, " ", 40)
local x, y = mathFloor(mxw/2-game._function.ydw.w/2), mathFloor(mxh/2-game._function.ydw.h/2)
game._function.ydw.x, game._function.ydw.y = x, y
buffer.drawRectangle(x, y, game._function.ydw.w, game._function.ydw.h, 0x7B7B7B, 0, " ")
buffer.drawRectangle(x-1, y+1, 1, game._function.ydw.h-2, 0x7B7B7B, 0, " ")
buffer.drawRectangle(x+game._function.ydw.w, y+1, 1, game._function.ydw.h-2, 0x7B7B7B, 0, " ")
local ydwTitle = "Слишком низкое здоровье"
buffer.drawText(mathFloor(x+game._function.ydw.w/2-unicode.len(ydwTitle)/2),y+1,0xFCFCFC,ydwTitle)
 for f = 1, #game._function.ydw do
 buffer.drawText(mathFloor(x+game._function.ydw.w/2-unicode.len(game._function.ydw[f][1])/2),y+4+f*3-3,0xCCCCCC,game._function.ydw[f][1])
 end
end

game._function.ydw.action["touch"] = function(ev)
 for e = 1, #game._function.ydw do
  if clicked(ev[3],ev[4],game._function.ydw.x,game._function.ydw.y+4+e*3-3,game._function.ydw.x+game._function.ydw.w-1,game._function.ydw.y+4+e*3-3) then
  pcall(game._function.ydw[e].f)
  end
 end
end

-----------------------------Console window------------------------------------------------------

local cCnsScroll = 1

game._function.gameConsole = {x=50,y=10,w=60,h=35,action={}}

function game._function.gameConsole.draw()
local x, y, w, h = game._function.gameConsole.x, game._function.gameConsole.y, game._function.gameConsole.w, game._function.gameConsole.h
buffer.drawRectangle(x, y, w, h, 0xABABAB, 0, " ")
buffer.drawRectangle(x, y, w, 1, 0x525252, 0, " ")
buffer.drawRectangle(x+1, y+1, w-2, h-4, 0x1A1A1A, 0, " ")
buffer.drawRectangle(x+1, y+33, w-2, 1, 0x1A1A1A, 0, " ")
local bColor, bSub
local text1 = "debug"
buffer.drawText(x+(mathMax(mathFloor((w / 2) - (unicode.len(text1) / 2)), 0)), y, 0xffffff, text1)
buffer.drawText(x+59,y,0xffffff,"X")
 for f = 1, mathMin(#consoleArray,h-7) do
  if consoleArray[f+(cCnsScroll*4-4)] then
   if unicode.sub(consoleArray[f+(cCnsScroll*4-4)],1,2) == "!/" then
   bColor = 0xFF0000
   bSub = 3
   else
   bColor = 0xffffff
   bSub = 1
   end
  buffer.drawText(x+2,y+2+f,bColor,unicode.sub(consoleArray[f+(cCnsScroll*4-4)],bSub,w-4))
  end
 end
end

game._function.gameConsole.action["touch"] = function(ev)
 if ev[5] == 0 and clicked(ev[3],ev[4],game._function.gameConsole.x+game._function.gameConsole.w-1,game._function.gameConsole.y,game._function.gameConsole.x+game._function.gameConsole.w-1,game._function.gameConsole.y) then
 game._data.windowThread = nil
 game._data.paused = false
 end
end

game._function.gameConsole.action["scroll"] = function(ev)
local x, y, w, h = game._function.gameConsole.x, game._function.gameConsole.y, game._function.gameConsole.w, game._function.gameConsole.h
 if clicked(ev[3],ev[4],x,y,x+w-1,y+h-3) and ev[5] == 1 and cCnsScroll > 1 then
 cCnsScroll = cCnsScroll - 1
 elseif clicked(ev[3],ev[4],x,y,x+w-1,y+h-3) and ev[5] == -1 and mathCeil(cCnsScroll*4) < #consoleArray then
 cCnsScroll = cCnsScroll + 1
 end
end

game._function.gameConsole.action["key_down"] = function(ev)
 if not game._data.paused and ev[4] == 46 then
 game._data.paused = true
 cCnsScroll = mathFloor(#consoleArray/4)
 game._data.windowThread = "console"
 end
end

-----------------------------Окно список заданий------------------------------------------------------

function game._gui.questsList.draw()
	local x, y = game._gui.questsList.window.x, game._gui.questsList.window.y

	-- Окно
	game._gui.blank.draw(game._gui.questsList.window)
	buffer.drawRectangle(x+2, y+2, 29, 27, 0x7A7A7A, 0, " ")
	buffer.drawRectangle(x+32, y+2, 66, 27, 0x7A7A7A, 0, " ")

	-- Список
	for f = 1, mathMin(#game._player.quests,25) do
		if game._player.quests[f][3] then
			buffer.drawText(x+2,y+2+f,0x00C222,"→")
		end
		buffer.drawText(x+3,y+2+f,0xDDDDDD,unicode.sub(gqd[game._player.quests[f][1]]["name"],1,28))
	end

	--Если выбран из списка
	if game._gui.questsList.targetQuest > 0 and game._player.quests[game._gui.questsList.targetQuest] ~= nil then
		local qDeskList = {}
		local dstr = game._function.textWrap(gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["descr"],63)

		for i = 1, #dstr do
			tableInsert(qDeskList, dstr[i])
		end

		local qInfoList = {}
		if gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["qreward"] then
			qInfoList = {
				"Награда:",
				"Монеты "..tostring(gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["qreward"]["coins"]),
				"Опыт "..tostring(gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["qreward"]["xp"]),
			}
		end

		tableInsert(qInfoList,1,"Описание:")

		for i = 1, #qDeskList do
			if qDeskList[i] ~= nil and qDeskList[i] ~= "" then
				tableInsert(qInfoList,i+1,qDeskList[i])
			end
		end

		-- Задание на охоту
		if gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["type"] == 1 then
			if type(gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["targ"]) == "number" then
				tableInsert(qInfoList,1,"► "..gud[gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["targ"]]["name"].." ("..game._player.quests[game._gui.questsList.targetQuest][2].."/"..gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["num"]..")")
			else
				for j = 1, #gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["targ"] do
					tableInsert(qInfoList,1,"► "..gud[gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["targ"][j]]["name"].." ("..game._player.quests[game._gui.questsList.targetQuest][2][j].."/"..gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["num"][j]..")")
				end
			end
		tableInsert(qInfoList,1,"Уничтожить: ")
		-- Задание на поиск предмета
		elseif gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["type"] == 2 then
			if type(gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["targ"][1]) == "number" then
				tableInsert(qInfoList,1,"► "..gid[gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["targ"]]["name"].." ("..game._player.quests[game._gui.questsList.targetQuest][2].."/"..gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["num"]..")")
			else
				for j = 1, #gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["targ"] do
					tableInsert(qInfoList,1,"► "..gid[gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["targ"][j][1]]["name"].." ("..game._player.quests[game._gui.questsList.targetQuest][2][j].."/"..gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["targ"][j][2]..")")
				end
			end
			tableInsert(qInfoList,1,"Найти предметы: ")
		end

		if gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["qr"] > 0 then
			tableInsert(qInfoList,1,"Задание закончено: "..gud[gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["qr"]]["name"])
		else
			tableInsert(qInfoList,1,"Задание закончено: автоматически")
		end
		if gqd[game._gui.questsList.targetQuest]["givingQuest"] then
			tableInsert(qInfoList,1,"Задание выдано: "..gud[gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["givingQuest"]]["name"])
		end
		if gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["qreward"] and gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["qreward"]["item"] ~= nil then
			tableInsert(qInfoList,"Предмет:")
			for o = 1, #gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["qreward"]["item"] do
				if type(gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["qreward"]["item"][o][1]) == "table" then
					tableInsert(qInfoList,"??? (?)")
				else
					tableInsert(qInfoList,unicode.sub(gid[gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["qreward"]["item"][o][1]]["name"].." ("..tostring(gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["qreward"]["item"][o][2])..")",1,45))
				end
			end
		end

		local ub = ""
		if gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["repeat"] then ub = " (Повторяемое)" end
		buffer.drawText(x+33,y+3,0xffffff,unicode.sub(gqd[game._player.quests[game._gui.questsList.targetQuest][1]]["name"]..ub,1,60))
		for f = 1, #qInfoList do
			buffer.drawText(x+33,y+3+f,0xffffff,qInfoList[f])
		end
	end
end

game._gui.questsList.action["touch"] = function(ev)
	local x, y, w = game._gui.questsList.window.x, game._gui.questsList.window.y, game._gui.questsList.window.w
	local tag
	-- Кнопка "закрыть"
	if ev[5] == 0 and clicked(ev[3], ev[4], x + w - 8, y, x + w - 1, y) then
		game._data.windowThread = "pause"
	end
	-- Клик на список заданий
	for f = 1, #game._player.quests do
		if game._player.quests[f] ~= nil and clicked(ev[3], ev[4], x + 3,y + 2 + f, x + 30, y + 2 + f) then
			tag = false
			game._gui.questsList.targetQuest = f
			break
		end
		if not tag then
			game._gui.questsList.targetQuest = 0
		end
	end
end

-----------------------------Окно инфо о персонаже ------------------------------------------------------

function game._gui.playerStats.updateContent()
	game._gui.playerStats.info = {
		"Имя персонажа: "..gud[CGD[game._player.id]["id"]]["name"],
		"Уровень: "..CGD[game._player.id]["lvl"],
		"Здоровье: "..mathFloor(CGD[game._player.id]["chp"]).."/"..mathFloor(CGD[game._player.id]["mhp"]),
		"Мана: "..mathFloor(CGD[game._player.id]["cmp"]).."/"..mathFloor(CGD[game._player.id]["mmp"]),
		"Опыт: "..CGD[game._player.id]["cxp"].."/"..CGD[game._player.id]["mxp"].." ("..tostring(mathFloor(CGD[game._player.id]["cxp"]*100/CGD[game._player.id]["mxp"]*10)/10).."%)",
		"Физическая атака: "..CGD[game._player.id]["ptk"][1].."-"..CGD[game._player.id]["ptk"][2].." ("..mathCeil((game._player.statsPoints.vPdm1+game._player.statsPoints.vPdm2)/2).." от снаряжения)",
		"Магическая атака: "..CGD[game._player.id]["mtk"][1].."-"..CGD[game._player.id]["mtk"][2].." ("..mathCeil((game._player.statsPoints.vMdm1+game._player.statsPoints.vMdm2)/2).." от снаряжения)",
		"Физическая защита: "..CGD[game._player.id]["pdef"].." ("..CGD[game._player.id]["armorpdef"].." от снаряжения)",
		"Магическая защита: "..CGD[game._player.id]["mdef"].." ("..CGD[game._player.id]["armormdef"].." от снаряжения)",
		"Скорость атаки: "..tostring(mathCeil((1/gsd[1]["reloading"])*10)/10),
		"Вероятность нанесения критического удара: "..CGD[game._player.id]["criticalhc"].."%",
	}
end

function game._gui.playerStats.draw()
	local x, y = game._gui.playerStats.window.x, game._gui.playerStats.window.y
	local x1, y1 = game._gui.playerStats.x1, game._gui.playerStats.y1

	game._gui.blank.draw(game._gui.playerStats.window)

	for f = 1, #game._gui.playerStats.info do
		buffer.drawText(x+3,y+1+f,0xffffff,game._gui.playerStats.info[f])
	end

	buffer.drawRectangle(x1, y1, 37, 5, 0x898989, 0, " ")
	buffer.drawText(x1+1,y1,0xffffff,"Очков для распределения " .. CGD[game._player.id]["levelpoints"])
	buffer.drawText(x1+1,y1+1,0xEEEEEE,"Магия")
	buffer.drawText(x1+14,y1+1,0xCECECE,tostring(CGD[game._player.id]["int"]+game._gui.playerStats.selectedPoints[1]+game._player.statsPoints.vInt))
	buffer.drawText(x1+1,y1+2,0xEEEEEE,"Сила")
	buffer.drawText(x1+14,y1+2,0xCECECE,tostring(CGD[game._player.id]["strg"]+game._gui.playerStats.selectedPoints[2]+game._player.statsPoints.vStr))
	buffer.drawText(x1+1,y1+3,0xEEEEEE,"Ловкость")
	buffer.drawText(x1+14,y1+3,0xCECECE,tostring(CGD[game._player.id]["agi"]+game._gui.playerStats.selectedPoints[3]+game._player.statsPoints.vAgi))
	buffer.drawText(x1+1,y1+4,0xEEEEEE,"Выносливость")
	buffer.drawText(x1+14,y1+4,0xCECECE,tostring(CGD[game._player.id]["surv"]+game._gui.playerStats.selectedPoints[4]+game._player.statsPoints.vSur))
	for f = 1, 4 do
		buffer.drawRectangle(x+20, y+14+f, 3, 1, 0x727272, 0, " ")
		buffer.drawText(x+21,y+14+f,0xEEEEEE,"+")
		buffer.drawRectangle(x+24, y+14+f, 3, 1, 0x727272, 0, " ")
		buffer.drawText(x+25,y+14+f,0xEEEEEE,"-")
	end
	buffer.drawRectangle(x+28, y+16, 9, 1, 0x737373, 0, " ")
	buffer.drawText(x+28,y+16,0xEEEEEE,"→Принять")
	buffer.drawRectangle(x+28, y+18, 9, 1, 0x737373, 0, " ")
	buffer.drawText(x+28,y+18,0xEEEEEE,"×отменить")
end

-- События по кнопкам (в окне инфо о персонаже)
game._gui.playerStats.action["touch"] = function(ev)
	local x, y = game._gui.playerStats.window.x, game._gui.playerStats.window.y
	local x1, y1 = game._gui.playerStats.x1, game._gui.playerStats.y1

	-- Кнопка "закрыть"
	if ev[5] == 0 and clicked(ev[3], ev[4],x + game._gui.playerStats.window.w - 8, y, x + game._gui.playerStats.window.w - 1, y) then
		game._data.windowThread = "pause"
		return
	end
	
	-- 4 параметра, кнопки плюс и минус
	for t = 1, 4 do
		if ev[5] == 0 and CGD[game._player.id]["levelpoints"] > 0 and clicked(ev[3], ev[4], x1 + 17, y1+t, x1 + 20, y1 + t) then
			game._gui.playerStats.selectedPoints[t] = game._gui.playerStats.selectedPoints[t] + 1
			CGD[game._player.id]["levelpoints"] = CGD[game._player.id]["levelpoints"] - 1
			game._gui.playerStats.selectedPoints[5] = game._gui.playerStats.selectedPoints[5] + 1
		elseif ev[5] == 0 and CGD[game._player.id]["levelpoints"] > 0 and clicked(ev[3],ev[4],x1 + 22, y1 + t, x1+25, y1 + t) and game._gui.playerStats.selectedPoints[t] > 0 then
			game._gui.playerStats.selectedPoints[t] = game._gui.playerStats.selectedPoints[t] - 1
			CGD[game._player.id]["levelpoints"] = CGD[game._player.id]["levelpoints"] + 1
			game._gui.playerStats.selectedPoints[5] = game._gui.playerStats.selectedPoints[5] - 1
		end
	end
	-- Кнопки принять / Отмена
	if ev[5] == 0 and clicked(ev[3], ev[4], x1 + 28, y1 + 2, x1 + 34, y1 + 2) then
		CGD[game._player.id]["int"] = CGD[game._player.id]["int"] + game._gui.playerStats.selectedPoints[1]
		CGD[game._player.id]["strg"] = CGD[game._player.id]["strg"] + game._gui.playerStats.selectedPoints[2]
		CGD[game._player.id]["agi"] = CGD[game._player.id]["agi"] + game._gui.playerStats.selectedPoints[3]
		CGD[game._player.id]["surv"] = CGD[game._player.id]["surv"] + game._gui.playerStats.selectedPoints[4]
		game._gui.playerStats.selectedPoints = {0,0,0,0,0}
		game._function.UpdatePlayerStats()
		game._gui.playerStats.updateContent() -- Обновить текст с ифнормацией
	elseif ev[5] == 0 and game._gui.playerStats.selectedPoints[5] > 0 and clicked(ev[3],ev[4], x1 + 28, y1 + 4, x1 + 34, y1 + 4) then
		CGD[game._player.id]["levelpoints"] = CGD[game._player.id]["levelpoints"] + game._gui.playerStats.selectedPoints[5]
		game._gui.playerStats.selectedPoints = {0,0,0,0,0}
		game._function.UpdatePlayerStats()
		game._gui.playerStats.updateContent() -- Обновить текст с ифнормацией
	end

end

-----------------------------Окно список умений------------------------------------------------------

function game._function.pSkillsPbar(x,y,number)
buffer.drawRectangle(x, y, 46, 4, 0x8c8c8c, 0, " ")
local c
 for f = 1, 7 do
 c = 0x00CA85
  if f > number + 1 then c = 0xAAAAAA
  elseif f == number + 1 then c = 0x0085CA
  end
 buffer.drawRectangle(x+2+f*6-6, y+1, 5, 2, c, 0, " ")
 end
end

function game._gui.playerSkills.draw()
	local x, y = game._gui.playerSkills.window.x, game._gui.playerSkills.window.y

	game._gui.blank.draw(game._gui.playerSkills.window)
	buffer.drawRectangle(x + 1, y + 2, 50, game._gui.playerSkills.window.h - 3, 0x919191, 0, " ")

	game._function.UpdatePlayerStats()

	local ntt, kfc, targetSkill, abc, rv

	local cnm = ""
	for f = 1, #cPlayerSkills do
		if f == game._gui.playerSkills.targ then
			buffer.drawRectangle(x+1, y+2+f*3-3, 50, 3, 0xABABAB, 0, " ");
			buffer.drawRectangle(x+51, y+3+f*3-3, 1, 1, 0x919191, 0, " ");
			buffer.drawRectangle(x+52, y+2+f*3-3, 1, 3, 0x919191, 0, " ")
		end
		cnm = gsd[cPlayerSkills[f][1]]["name"].." ("..cPlayerSkills[f][3].." ур.)"
		buffer.drawText(x+mathFloor(25-unicode.len(cnm)/2),y+3+f*3-3,0xffffff,cnm)
	end
	buffer.drawRectangle(x+53, y+2, 50, 37, 0x919191, 0, " ")
	if game._gui.playerSkills.targ ~= 0 then
	local slvl = mathMax(cPlayerSkills[game._gui.playerSkills.targ][3],1)
 targetSkill = gsd[cPlayerSkills[game._gui.playerSkills.targ][1]]
  if ( targetSkill["type"] == 2 and cPlayerSkills[game._gui.playerSkills.targ][3] < 7 ) or cPlayerSkills[game._gui.playerSkills.targ][3] < #targetSkill["manacost"] then
   buffer.drawRectangle(x+55, y+30, 46, 8, 0xA3A3A3, 0, " ")
   local buben = {
   {"Улучшение умения • следующий уровень "..cPlayerSkills[game._gui.playerSkills.targ][3]+1,0xEFEFEF}
   }
   if targetSkill["reqlvl"] then
   tableInsert(buben,{"Требуемый уровень: "..targetSkill["reqlvl"][cPlayerSkills[game._gui.playerSkills.targ][3]+1],0xEFEFEF})
   if targetSkill["reqlvl"][cPlayerSkills[game._gui.playerSkills.targ][3]+1] > CGD[game._player.id]["lvl"] then buben[#buben][2] = 0xEE1414 end
   end
   if targetSkill["reqcn"] then
   tableInsert(buben,{"Стоимость улучшения: "..targetSkill["reqcn"][cPlayerSkills[game._gui.playerSkills.targ][3]+1].." монет",0xEFEFEF})
   if targetSkill["reqcn"][cPlayerSkills[game._gui.playerSkills.targ][3]+1] > CGD[game._player.id]["cash"] then buben[#buben][2] = 0xEE1414 end
   end
   if targetSkill["reqitem"] then
   tableInsert(buben,{"Требуемый предмет: "..gid[targetSkill["reqitem"][cPlayerSkills[game._gui.playerSkills.targ][3]+1][1]]["name"].."("..game._function.checkItemInBag(targetSkill["reqitem"][cPlayerSkills[game._gui.playerSkills.targ][3]+1][1]).."/"..targetSkill["reqitem"][cPlayerSkills[game._gui.playerSkills.targ][3]+1][2]..")",0xEFEFEF})
   if game._function.checkItemInBag(targetSkill["reqitem"][cPlayerSkills[game._gui.playerSkills.targ][3]+1][1]) < targetSkill["reqitem"][cPlayerSkills[game._gui.playerSkills.targ][3]+1][2] then buben[#buben][2] = 0xEE1414 end
   end
   for f = 1, #buben do
   buffer.drawText(x+57,y+30+f,buben[f][2],tostring(buben[f][1]))
   end
   abc = "Изучить умение"
   buffer.drawRectangle(x+70, y+35, unicode.len(abc)+2, 3, 0x077DAC, 0, " ")
   buffer.drawText(x+71,y+36,0xCECECE,abc)
  end

 kfc = {["p"]="физического",["m"]="магического"}
 rv = {}
  if targetSkill["value"] then rv[1] = targetSkill["value"][slvl] else rv[1] = "" end
  if targetSkill["bseatckinc"] then rv[2] = targetSkill["bseatckinc"][slvl] else rv[2] = "" end
  if type(targetSkill["basedmgmlt"]) == "table" then rv[3] = targetSkill["basedmgmlt"][slvl]
  elseif type(targetSkill["basedmgmlt"]) == "number" then rv[3] = targetSkill["basedmgmlt"]
  else rv[3] = "" end
  if targetSkill["weapondmgmlt"] then rv[4] = targetSkill["weapondmgmlt"][slvl] else rv[4] = "" end
  if targetSkill["eff"] and ged[targetSkill["eff"]]["dur"] then rv[5] = ged[targetSkill["eff"]]["dur"][slvl] else rv[5] = "" end
  if targetSkill["eff"] and ged[targetSkill["eff"]]["val"] then rv[6] = math.abs(ged[targetSkill["eff"]]["val"][slvl]) else rv[6] = "" end
 slvl = cPlayerSkills[game._gui.playerSkills.targ][3]
 ntt = {
 ["a"]=kfc[targetSkill["typedm"]],
 ["b"]=rv[1],
 ["c"]=rv[2],
 ["i"]=rv[3],
 ["e"]=rv[4],
 ["d"]=rv[5],
 ["v"]=rv[6],
 }

 game._function.pSkillsPbar(x+55,y+25,slvl)
 buffer.drawText(x+54,y+3,0xffffff,"•"..targetSkill["name"])
 buffer.drawText(x+54,y+4,0xffffff,"Тип: " .. game._data.skillType[targetSkill["type"]])
  if slvl > 0 and ( targetSkill["type"] == 1 or targetSkill["type"] == 3 ) then
  buffer.drawText(x+54,y+5,0xffffff,"Уровень умения: "..slvl.." / "..#targetSkill["manacost"])
  buffer.drawText(x+54,y+6,0xffffff,"Использует маны: "..targetSkill["manacost"][slvl].." ед.")
  buffer.drawText(x+54,y+7,0xffffff,"Перезарядка: "..targetSkill["reloading"].." сек.")
   if targetSkill["type"] == 1 then
   buffer.drawText(x+54,y+8,0xffffff,"Дальность: "..(targetSkill["distance"]+(vAttackDistance or 8)))
   end
  elseif slvl > 0 and targetSkill["type"] == 2 then
  buffer.drawText(x+54,y+5,0xffffff,"Уровень умения: "..slvl.." / "..#targetSkill["value"])
  else
  buffer.drawText(x+54,y+5,0xCCCCCC,"Умение ещё не изучено")
  end
  abc = ""
  rv = 1
   for m = 1, unicode.len(targetSkill["descr"]) do
    if unicode.sub(targetSkill["descr"],rv,rv) ~="$" then
	abc = abc..unicode.sub(targetSkill["descr"],rv,rv)
	rv = rv+1
    else
	abc = abc..tostring(ntt[unicode.sub(targetSkill["descr"],rv+1,rv+1)])
	rv = rv+2
	end
   end
  local cbc = game._function.textWrap(abc,42)
   for f = 1, #cbc do
   buffer.drawText(x+54,y+9+f,0xffffff,tostring(cbc[f]))
   end
 buffer.drawText(x+105,y+3,0xffffff,"Установить")
 buffer.drawText(x+105,y+4,0xffffff,"на клавишу…")
 local bColor
  for p = 1, #game._gui.skillsTopPanel.t do
  bColor = game._gui.skillsTopPanel.t[p].c
   for n = 1, #game._player.actSkills do
    if game._player.actSkills[p+1] == cPlayerSkills[game._gui.playerSkills.targ][1] then
	bColor = 0xBBBBBB
	break
	end
   end
  buffer.drawRectangle(x+105, 6+y+4*p-4, 10, 3, bColor, 0, " ")
  buffer.drawText(x+109,6+y+4*p-3,0xffffff,tostring(p+1))
  end
 end
end

game._gui.playerSkills.action["touch"] = function(ev)
	local x, y = game._gui.playerSkills.window.x, game._gui.playerSkills.window.y

	local targetSkill, checkv1, checkv2

	-- Кнопка "закрыть"
	if clicked(ev[3], ev[4], x + game._gui.playerSkills.window.w - 8, y, x + game._gui.playerSkills.window.w - 1, y) then
		game._data.windowThread = "pause"
	end

	-- Кнопки слева
	for e = 1, #cPlayerSkills do
		if ev[5] == 0 and clicked(ev[3], ev[4], x + 1, y+2+e*3-3, x+50, y+2+e*3) then
			game._gui.playerSkills.targ = e
		end
	end

	if game._gui.playerSkills.targ > 0 then
		if ev[5] == 0 and clicked(ev[3],ev[4],x+70,game._gui.playerSkills.window.y+35,x+84,y+37) and ( ( gsd[cPlayerSkills[game._gui.playerSkills.targ][1]]["type"] == 2 and cPlayerSkills[game._gui.playerSkills.targ][3] < 7 ) or cPlayerSkills[game._gui.playerSkills.targ][3] < #gsd[cPlayerSkills[game._gui.playerSkills.targ][1]]["manacost"] ) then
			targetSkill, checkv1, checkv2 = gsd[cPlayerSkills[game._gui.playerSkills.targ][1]], true, {}
			if targetSkill["reqlvl"] then
				if targetSkill["reqlvl"][cPlayerSkills[game._gui.playerSkills.targ][3]+1] > CGD[game._player.id]["lvl"] then
					checkv1 = false
				end
			end
			if targetSkill["reqcn"] then
				if targetSkill["reqcn"][cPlayerSkills[game._gui.playerSkills.targ][3]+1] > CGD[game._player.id]["cash"] then
					checkv1 = false
				else
					checkv2.c = true
				end
			end
			if targetSkill["reqitem"] then
				if game._function.checkItemInBag(targetSkill["reqitem"][cPlayerSkills[game._gui.playerSkills.targ][3]+1][1]) < targetSkill["reqitem"][cPlayerSkills[game._gui.playerSkills.targ][3]+1][2] then
					checkv1 = false
				else
					checkv2.o, checkv2.i = game._function.checkItemInBag(targetSkill["reqitem"][cPlayerSkills[game._gui.playerSkills.targ][3]+1][1])
				end
			end
			if checkv1 == true then
				if checkv2.c then
					CGD[game._player.id]["cash"] = CGD[game._player.id]["cash"] - targetSkill["reqcn"][cPlayerSkills[game._gui.playerSkills.targ][3]+1]
				end
				if checkv2.i then
					for y = 1, #CGD[game._player.id]["inventory"]["bag"] do
						if CGD[game._player.id]["inventory"]["bag"][y][1] == checkv2.i and CGD[game._player.id]["inventory"]["bag"][y][2] >= checkv2.o then
						CGD[game._player.id]["inventory"]["bag"][y][2] = CGD[game._player.id]["inventory"]["bag"][y][2] - targetSkill["reqitem"][cPlayerSkills[game._gui.playerSkills.targ][3]+1][2]
						break
						end
					end
				end
				cPlayerSkills[game._gui.playerSkills.targ][3] = cPlayerSkills[game._gui.playerSkills.targ][3] + 1
			end
		end
		for p = 1, #game._player.actSkills do
			if ev[5] == 0 and cPlayerSkills[game._gui.playerSkills.targ][1] > 1 and clicked(ev[3],ev[4],x+105,y+6+4*p-4,x+115,y+6+4*p-1) and cPlayerSkills[game._gui.playerSkills.targ][3] > 0 and gsd[cPlayerSkills[game._gui.playerSkills.targ][1]]["type"] ~= 2 then
				for n = 1, #game._player.actSkills do
					if game._player.actSkills[n] == cPlayerSkills[game._gui.playerSkills.targ][1] then
						game._player.actSkills[n] = 0
					end
				end
				game._player.actSkills[p+1] = game._gui.playerSkills.targ
				break
			end
		end
	end
end

function game._function.spawnSingleUnit(id,x,y)
	local newID = game._function.addUnit(id,x,y)
	CGD[newID]["image"] = setImage(id)
	return newID
end

function game._function.removeUnit(id)
	for f = 1, #CGD do
		if CGD[f] and CGD[f]["target"] == id then
			CGD[f]["target"] = nil
		end
	end
	if CGD[id] then
		tableRemove(CGD, id)
		return true
	end
	return false
end

function game._function.addFollower(fid)
	local id
	if fid then
		if CGD[game._player.id]["petcage"] and CGD[game._player.id]["petcage"][fid] then
			id = CGD[game._player.id]["petcage"][fid]["id"]
			local cgdid = game._function.spawnSingleUnit(id, CGD[game._player.id]["x"] + math.random(-10,10), 1)
			tableInsert(CGD[game._player.id]["followers"], {id, cgdid})
			CGD[cgdid]["summoner"] = game._player.id
			CGD[cgdid]["lvl"] = CGD[game._player.id]["petcage"][fid]["lvl"] or 1
			CGD[cgdid]["mxp"] = game._function.getUnitMaxXP(cgdid)
			CGD[cgdid]["cxp"] = CGD[game._player.id]["petcage"][fid]["cxp"] or 0
			CGD[cgdid]["chp"] = CGD[game._player.id]["petcage"][fid]["chp"] or 1
			game._function.updateUnitStats(cgdid)
			CGD[cgdid]["fid"] = fid
		end
	end
end

function game._function.keepFollower(id)
	if CGD[id] and CGD[game._player.id]["petcage"] then
		for f = 1, #CGD[game._player.id]["followers"] do
			if CGD[CGD[game._player.id]["followers"][f][2]]["fid"] then
				if CGD[game._player.id]["petcage"][CGD[CGD[game._player.id]["followers"][f][2]]["fid"]] then
					CGD[game._player.id]["petcage"][CGD[CGD[game._player.id]["followers"][f][2]]["fid"]]["lvl"] = CGD[id]["lvl"]
					CGD[game._player.id]["petcage"][CGD[CGD[game._player.id]["followers"][f][2]]["fid"]]["cxp"] = CGD[id]["cxp"]
					CGD[game._player.id]["petcage"][CGD[CGD[game._player.id]["followers"][f][2]]["fid"]]["chp"] = CGD[id]["chp"]
				end
			end
		end
	end
end

function game._function.removeFollowers()
	for i = 1, #CGD do
		if CGD[i] then
			for f = 1, #CGD[game._player.id]["followers"] do
				if i == CGD[game._player.id]["followers"][f][2] then
					game._function.keepFollower(i)
					game._function.removeUnit(i)
					CGD[game._player.id]["followers"] = {}
				end
			end
		end
	end
end

local function doAfterDied(d, x)
	for f = 1, #d do
		if d[f] == "np" then -- Появляется портал
			game._function.addUnit(game._data.potralUnitId, x + 10,2)
			imageBuffer[#imageBuffer+1] = image.load(game._data.text.directory.."sprpic/"..gud[game._data.potralUnitId]["image"]..".pic")
			CGD[#CGD]["image"] = #imageBuffer
		elseif type(d[f]) == "table" and d[f][1] == "sp" and gud[d[f][2]]["nres"] then -- spawn
			game._function.spawnSingleUnit(d[f][2],x+game._function.random(-10,10),1)
		elseif type(d[f]) == "table" and d[f][1] == "cq" then -- cancel quest
			for i = 1, #d[f] - 1 do
				gqd[d[f][i+1]]["comp"] = 2
				for e = 1, #game._player.quests do
					if game._player.quests[#game._player.quests-e+1][1] == d[f][i+1] then
						tableRemove(game._player.quests,#game._player.quests-e+1)
					end
				end
			end
		end
	end
end

function game._function.getLootItems(fromID)
	local itemLoot = {}
	if CGD[fromID] then
		if gud[CGD[fromID]["id"]]["loot"]["drop"] then
			for f = 1, #gud[CGD[fromID]["id"]]["loot"]["drop"] do
				itemLoot[#itemLoot+1] = gud[CGD[fromID]["id"]]["loot"]["drop"][f]
			end
		end
		for f = 1, #lootdata[gud[CGD[fromID]["id"]]["loot"]["items"]] do
			itemLoot[#itemLoot+1] = lootdata[gud[CGD[fromID]["id"]]["loot"]["items"]][f]
		end
		-- рандомный лут с мобов
		itemLoot = getMixedSequence(itemLoot)
		local nitemloop = gud[CGD[fromID]["id"]]["tcdrop"] or 1 -- количество циклов, т.е. макс. количество предметов
		for l = 1, nitemloop do
			for f = 1, #itemLoot do
				if itemLoot[f][1] ~= nil and game._function.random(1,100000) <= itemLoot[f][2]*1000 then
					if game._function.random(1,100) >= game._parameter.lootItemImprovedChance then itemLoot[f][1] = createNewItem(itemLoot[f][1]) end
						game._function.addItem(itemLoot[f][1],1,true)
					break
				end
			end
		end
	else
		game._function.logtxt("getLootItems: ID не существует")
	end
end

function game._function.getLootExperience(fromID)
	if CGD[fromID] and gud[CGD[fromID]["id"]]["loot"] then
		return gud[CGD[fromID]["id"]]["loot"]["exp"]+mathCeil(game._function.random(-gud[CGD[fromID]["id"]]["loot"]["exp"]*0.1,gud[CGD[fromID]["id"]]["loot"]["exp"]*0.1))
	else
		game._function.logtxt("getLootExperience: ID не существует")
		return 0
	end
end

function game._function.getUnitMaxXP(id)
	local reqxp = 0
	for e = 1, CGD[id]["lvl"] do
		if e <= 10 then
			reqxp = mathFloor(reqxp + reqxp*(2/e) + 24*e^(1/e))
		elseif e > 20 and e < 30 then
			reqxp = mathFloor(reqxp + reqxp*(3/e) + 28*e^(1/e))
		elseif e >= 30 then
			reqxp = mathFloor(reqxp + reqxp*(4/e) + 32*e^(1/e))
		end
	end
	return mathMax(reqxp,1)
end

local function addUnitXP(id, value)
	local xpPlus, limit, i = value or 0, 50, 0
	if id then
		while i <= limit do
			CGD[id]["mxp"] = game._function.getUnitMaxXP(id)
			if xpPlus <= CGD[id]["mxp"] - CGD[id]["cxp"] then
				CGD[id]["cxp"] = CGD[id]["cxp"] + xpPlus
				break
			else
				if CGD[id]["summoner"] and CGD[CGD[id]["summoner"]]["lvl"] > CGD[id]["lvl"] then
					xpPlus = xpPlus - (CGD[id]["mxp"] - CGD[id]["cxp"])
					CGD[id]["cxp"] = 0
					CGD[id]["lvl"] = CGD[id]["lvl"] + 1
					game._function.updateUnitStats(id)
					CGD[id]["chp"] = CGD[id]["mhp"]
					i = i + 1
				else
					CGD[id]["cxp"] = CGD[id]["mxp"]
					break
				end
			end
		end
	else
		game._function.logtxt("addUnitXP: ID не существует")
	end
end

function game._function.huntingQuestProcessing(id)
	local var
	if CGD[id] then
		for f = 1, #game._player.quests do
			-- в квесте 1 моб
			if gqd[game._player.quests[f][1]]["type"] == 1 and type(game._player.quests[f][2]) == "number" then
				if CGD[id]["id"] == gqd[game._player.quests[f][1]]["targ"] and game._player.quests[f][3] == false then
					if game._player.quests[f][2] + 1 < gqd[game._player.quests[f][1]]["num"] then
						game._player.quests[f][2] = game._player.quests[f][2] + 1
					else
						gqd[game._player.quests[f][1]]["comp"] = 2
						game._player.quests[f][2] = gqd[game._player.quests[f][1]]["num"]
						game._player.quests[f][3] = true
						game._function.showMessage1('Задание "'..gqd[game._player.quests[f][1]]["name"]..'" выполнено!')
					end
				end
			-- в квесте > 1 моба
			elseif gqd[game._player.quests[f][1]]["type"] == 1 and type(game._player.quests[f][2]) == "table" then
				for j = 1, #gqd[game._player.quests[f][1]]["targ"] do
					if CGD[id]["id"] == gqd[game._player.quests[f][1]]["targ"][j] and game._player.quests[f][3] == false then
						if game._player.quests[f][2][j] < gqd[game._player.quests[f][1]]["num"][j] then
							game._player.quests[f][2][j] = game._player.quests[f][2][j] + 1
						end
					end
				end
				var = 0
				for j = 1, #gqd[game._player.quests[f][1]]["targ"] do
					if game._player.quests[f][2][j] == gqd[game._player.quests[f][1]]["num"][j] then
						var = var + 1
					end
				end
				if var == #gqd[game._player.quests[f][1]]["targ"] then
					if gqd[game._player.quests[f][1]]["comp"] == 1 then
						game._function.showMessage1('Задание "'..gqd[game._player.quests[f][1]]["name"]..'" выполнено!')
					end
					gqd[game._player.quests[f][1]]["comp"] = 2
					for j = 1, #gqd[game._player.quests[f][1]]["targ"] do
						game._player.quests[f][2][j] = gqd[game._player.quests[f][1]]["num"][j]
					end
					game._player.quests[f][3] = true
				end
			end
		end
	end
end

function game._function.killUnit(id)
	CGD[id]["living"] = false
	CGD[id]["resptime"] = gud[CGD[id]["id"]]["vresp"]
	CGD[id]["target"] = nil
	CGD[id]["effects"] = {}
	CGD[id]["chp"] = CGD[id]["mhp"]

	game._function.effect[2](id) -- тест
end

-- наносить урон по мобам
function game._function.makeDamage(id, damage)
	-- не упал
	if CGD[id]["chp"] > damage then
		CGD[id]["target"] = game._player.id
		CGD[id]["chp"] = CGD[id]["chp"] - damage
	-- упал
	elseif CGD[id]["chp"] <= damage then
		game._function.killUnit(id)
	-- выпадение лута
		game._function.getLootItems(id)
		game._function.huntingQuestProcessing(id)
		addXP(game._function.getLootExperience(id))
	if CGD[game._player.id]["followers"] and #CGD[game._player.id]["followers"] > 0 then
		for f = 1, #CGD[game._player.id]["followers"] do
		addUnitXP(CGD[game._player.id]["followers"][f][2], mathFloor(game._function.getLootExperience(id) / #CGD[game._player.id]["followers"]))
		end
	end

	local coinsLoot = gud[CGD[id]["id"]]["loot"]["coins"]
	local giveCoins = coinsLoot+mathCeil(coinsLoot*game._function.random(-(50+1.11^mathMin(CGD[id]["lvl"],35)),(50+1.11^mathMin(CGD[id]["lvl"],35)))/100)
	game._function.addCoins(giveCoins)

	CGD[id]["resptime"] = gud[CGD[id]["id"]]["vresp"]
	--game._function.console.debug("опыт +",expr,"монеты +",giveCoins)
	if id == CGD[game._player.id]["target"] then
		CGD[game._player.id]["target"] = nil
	end

	if gud[CGD[id]["id"]]["ifDied"] then
		doAfterDied(gud[CGD[id]["id"]]["ifDied"],CGD[id]["x"])
	end

	if gud[CGD[id]["id"]]["nres"] == true then
		gud[CGD[id]["id"]]["nres"] = false
	end

	game._gui.targetInfoPanel.showTargetInfo = false
	end
end

function game._function.enemyDamage(toID, fromID, damage) --)tipedm,dmplus
	if CGD[toID] and CGD[fromID] and damage then
		-- атака прерывает выкапывание чего-то там
		if toID == game._player.id and game._player.pickingUp then
			if CGD[game._player.id]["target"] == game._player.pckTarget then
				CGD[game._player.id]["target"] = nil
			end
			game._player.pckTarget = nil
			game._player.pickingUp = false
			game._player.pckTime, game._player.maxPckTime = 0, 0
			CGD[toID]["cmove"] = true
			CGD[toID]["image"] = 0
		end
		--
		if damage < CGD[toID]["chp"] then
			CGD[toID]["chp"] = CGD[toID]["chp"] - damage
			if toID == game._player.id then
				CGD[toID]["rage"] = 10
			end
			-- game._function.textmsg5("Урон " .. damage)
		else
			game._function.killUnit(toID)
			if CGD[fromID]["rtype"] == "p" and CGD[fromID]["summoner"] then
				addUnitXP(fromID, game._function.getLootExperience(toID))
				addXP(game._function.getLootExperience(toID))
				game._function.huntingQuestProcessing(toID)
			end
		end
		if toID ~= game._player.id then
			game._function.addUnitHitInfo(toID,"Урон "..mathCeil(damage))
		end
	else
		game._function.logtxt("enemyDamage: ошибка данных")
	end
end


-- Частицы (эксперимент)

function game._function.drawParticles()
	local x, y, dx, grav
	for i = 1, #particles do
		x, y = particles[i].x, particles[i].y
		dx = x + 75 - cGlobalx
		buffer.drawText(mathFloor(dx), mxh - mathFloor(y), particles[i].color, "▪")
		if not game._data.paused then
			if particles[i].my < 0 and y < 3 then
				particles[i].my = -particles[i].my * 0.5
				particles[i].color = 0x000000
			end
			particles[i].x = x + particles[i].mx
			particles[i].y = y + particles[i].my
			grav = particles[i].gravity
			if grav ~= 0 then
				particles[i].my = particles[i].my - grav
			end
		end
	end
end

local function addParticle(x, y, mx, my, lifeTime, color, gravity)
	local part = {
		x = x,
		y = y,
		mx = mx,
		my = my,
		life = lifeTime,
		color = color,
		gravity = gravity
	}
	table.insert(particles, part)
end

local function addParticles(x, y, mx, my, parts, lifeTime, gravity)
	for i = 1, parts do
		addParticle(x, y, mx, my, lifeTime, 0xff8080, gravity)
	end
end

-- Визуальный эффект
game._function.effect = {
	[1] = function(target, direction)
		local x, y = CGD[target]["x"], 10
		local parts = 1
		local mx
		if direction == 0 then
			mx = -1
		else
			mx = 1
		end
		local my, lifeTime = 0.1 + math.random(-1, 1), math.random(0, 2)
		addParticles(x, y, mx, my, parts, lifeTime, 0.1)
	end,
	[2] = function(target)
		local x, y = CGD[target]["x"], 10
		for i = 1, 10 do
			addParticle(x, y, math.random(-10, 10) / 10, 0, 2, 0xff8080, 0.1)
		end
	end
}

function game._function.enemySkill(id, target, sl, lvl)
	local damage, atck, dmgReduction = 0
	local isAvailable = false
	if CGD[target]["rtype"] == "p" or CGD[target]["rtype"] == "e" then
		isAvailable = true
	end
	if not ( CGD[id]["target"] and CGD[target] and CGD[id]["living"]) then
		isAvailable = false
	end

	if CGD[id]["rtype"] == "p" and CGD[id]["summoner"] and CGD[id]["summoner"] == target then
		isAvailable = false
	end
	if isAvailable and eusd[sl]["type"] == 1 and CGD[id]["ctck"] then
		-- Атака
		local dist = gud[CGD[id]["id"]]["atds"] + eusd[sl]["distance"]
		-- Слишком далеко, нужно подойти
		if game._function.getDistanceToId(target,id) > dist then
			if CGD[id]["x"] > CGD[target]["x"] then
				CGD[id]["spos"] = 0
				CGD[id]["mx"] = CGD[target]["x"] + CGD[target]["width"] + dist
			else
				CGD[id]["spos"] = 1
				CGD[id]["mx"] = CGD[target]["x"] - dist
			end
		-- Удар
		else
			if CGD[id]["x"] > CGD[target]["x"] then
				CGD[id]["spos"] = 0
			else
				CGD[id]["spos"] = 1
			end
			CGD[id]["mx"] = CGD[id]["x"]
			if eusd[sl]["typedm"] == 1 then
				atck = game._function.random(CGD[id]["mtk"][1] * 10, CGD[id]["mtk"][2] * 10) / 10
				dmgReduction = CGD[target]["mdef"] / (CGD[target]["mdef"]+CGD[id]["lvl"]*game._parameter.magicalDamageReductionMul)
			elseif eusd[sl]["typedm"] == 0 then
				atck = game._function.random(CGD[id]["ptk"][1] * 10, CGD[id]["ptk"][2] * 10) / 10
				dmgReduction = CGD[target]["pdef"] / (CGD[target]["pdef"]+CGD[id]["lvl"]*game._parameter.physicalDamageReductionMul)
			end
			atck = atck + game._function.random(eusd[sl]["damageinc"][lvl][1],eusd[sl]["damageinc"][lvl][2])*(1+CGD[id]["lvl"]*0.1)
			damage = mathMax(mathFloor(atck * (1 - dmgReduction)),1)
			game._function.enemyDamage(target, id, damage) -- Урон по цели
			game._function.effect[1](target, CGD[id]["spos"]) -- тест
			if not CGD[target]["target"] then
				CGD[target]["target"] = id
			end
			if eusd[sl]["eff"] then
				game._function.addUnitEffect(target,eusd[sl]["eff"][1],eusd[sl]["eff"][2],id)
			end
		end
	elseif eusd[sl]["type"] == 2 then
		-- Бафф
		game._function.addUnitEffect(id, eusd[sl]["eff"][1], eusd[sl]["eff"][2])
	end
end

function game._function.useSkill(skill)
local cskill = cPlayerSkills[game._player.actSkills[skill]][1]
local lvl = cPlayerSkills[game._player.actSkills[skill]][3]
local sTarget = CGD[game._player.id]["target"] or 0
local available = false
 if CGD[game._player.id]["inventory"]["weared"]["weapon"] ~= 0 then
  if gsd[cskill]["weaponreq"] then
   for f = 1, #gsd[cskill]["weaponreq"] do
    if gid[CGD[game._player.id]["inventory"]["weared"]["weapon"]]["subtype"] == gsd[cskill]["weaponreq"][f] then
    available = true
    break
    end
   end
  else
  available = true
  end
 end

 if CGD[game._player.id]["cint"] then
 sTarget = CGD[game._player.id]["cint"][2]
 end

 local isQuiet = function(i)
  local types = {"p","f","r","c"}
  for f = 1, #types do
   if i == types[f] then
   return true
   end
  end
 end

 local calcDamage = function(unit)
 local weaponDmg = 0
 local damage = 0
 local chchance = 1
  if gsd[cskill]["typedm"] == 0 then
  damage = damage + game._function.random(CGD[game._player.id]["ptk"][1]*10,CGD[game._player.id]["ptk"][2]*10)/10
  weaponDmg = game._function.random(game._player.statsPoints.vPdm1,game._player.statsPoints.vPdm2)
  elseif gsd[cskill]["typedm"] == 1 then
  damage = damage + game._function.random(CGD[game._player.id]["mtk"][1]*10,CGD[game._player.id]["mtk"][2]*10)/10
  weaponDmg = game._function.random(game._player.statsPoints.vMdm1,game._player.statsPoints.vMdm2)
  end
  if type(gsd[cskill]["basedmgmlt"]) == "table" then
  damage = damage + damage*gsd[cskill]["basedmgmlt"][lvl]*0.01
  elseif type(gsd[cskill]["basedmgmlt"]) == "number" then
  damage = damage + damage*gsd[cskill]["basedmgmlt"]*0.01
  end
  if gsd[cskill]["weapondmgmlt"] and CGD[game._player.id]["inventory"]["weared"]["weapon"] > 0 then
  damage = damage + weaponDmg*gsd[cskill]["weapondmgmlt"][lvl]*0.01
  end
  if gsd[cskill]["bseatckinc"] then
  damage = damage + damage*gsd[cskill]["bseatckinc"][lvl]*0.01
  end
  if gsd[cskill]["value"] then
  damage = damage + gsd[cskill]["value"][lvl]
  end
  if gsd[cskill]["typedm"] == 0 then
  damage = mathMax(damage*(1-CGD[sTarget]["pdef"]/(CGD[sTarget]["pdef"]+CGD[game._player.id]["lvl"]*30)),0.1)
  elseif gsd[cskill]["typedm"] == 1 then
  damage = mathMax(damage*(1-CGD[sTarget]["mdef"]/(CGD[sTarget]["mdef"]+CGD[game._player.id]["lvl"]*30)),0.1)
  end
  if game._function.random(1,100) <= CGD[game._player.id]["criticalhc"] then
   chchance = 2
   damage = damage * 2
  end
	-- Есть урон
  if damage > 0 then
   if chchance == 1 then
   game._function.addUnitHitInfo(unit,"Урон "..mathCeil(damage))
   --game._function.console.debug(unicode.sub(gud[CGD[unit]["id"]]["name"],1,15),"получил урон",damage)
   elseif chchance == 2 then
   game._function.addUnitHitInfo(unit,"Критический урон "..mathCeil(damage))
   end
   game._function.effect[1](sTarget, CGD[game._player.id]["spos"]) -- тест
  end
  return mathMax(damage,1)
 end

 if CGD[game._player.id]["ctck"] == false then
 available = false
 end

 if sTarget ~= 0 then
  if isQuiet(CGD[sTarget]["rtype"]) then
  available = false
  end
 end

 if available and sTarget ~= 0 and CGD[sTarget]["living"] and gsd[cskill]["type"] == 1 then
  if CGD[sTarget]["x"] > CGD[game._player.id]["x"] then
  CGD[game._player.id]["spos"] = 1
  else
  CGD[game._player.id]["spos"] = 0
  end
  if CGD[game._player.id]["cmp"] >= gsd[cskill]["manacost"][lvl] and cPlayerSkills[game._player.actSkills[skill]][2] == 0 and game._function.getDistanceToId(game._player.id,sTarget) <= vAttackDistance+gsd[cskill]["distance"] then
  CGD[game._player.id]["cmp"] = CGD[game._player.id]["cmp"] - gsd[cskill]["manacost"][lvl]
   if gsd[cskill]["action"] and gsd[cskill]["action"]["type"] == 1 then
	for f = 1, #CGD do
	 if CGD[f] and CGD[f]["living"] and game._function.getDistanceToId(sTarget,f) <= gsd[cskill]["action"]["dist"] and not isQuiet(CGD[f]["rtype"]) then
	 game._function.makeDamage(f, mathCeil(calcDamage(f)))

	  if gsd[cskill]["eff"] ~= nil then
      game._function.addUnitEffect(f,gsd[cskill]["eff"],cPlayerSkills[game._player.actSkills[skill]][3])
      end
	 end
	end
   else
   game._function.makeDamage(sTarget, mathCeil(calcDamage(sTarget)))
    if sTarget ~= 0 and gsd[cskill]["eff"] ~= nil then
    game._function.addUnitEffect(sTarget,gsd[cskill]["eff"],cPlayerSkills[game._player.actSkills[skill]][3])
    end
   end

   if CGD[game._player.id]["followers"] then
    for f = 1, #CGD[game._player.id]["followers"] do
	 if not CGD[CGD[game._player.id]["followers"][f][2]]["target"] then
	 CGD[CGD[game._player.id]["followers"][f][2]]["target"] = CGD[game._player.id]["target"]
	 end
	end
   end

  cPlayerSkills[game._player.actSkills[1]][2] = gsd[1]["reloading"]*10
  CGD[game._player.id]["image"] = -4
  pimg4t = 0
  cPlayerSkills[game._player.actSkills[skill]][2] = gsd[cskill]["reloading"]*10
  vtskillUsingMsg = 3
  skillUsingMsg[1] = gsd[cskill]["name"]
  end
 CGD[game._player.id]["rage"] = 10
 elseif gsd[cskill]["type"] == 3 and CGD[game._player.id]["cmp"] >= gsd[cskill]["manacost"][lvl] and cPlayerSkills[game._player.actSkills[skill]][2] == 0 then
 CGD[game._player.id]["cmp"] = CGD[game._player.id]["cmp"] - gsd[cskill]["manacost"][lvl]
 cPlayerSkills[game._player.actSkills[skill]][2] = gsd[cskill]["reloading"]*10
 if gsd[cskill]["eff"] ~= nil then game._function.addUnitEffect(game._player.id,gsd[cskill]["eff"],lvl) end
 skillUsingMsg[1] = gsd[cskill]["name"]
 end
end

function game._function.pickUpResource(id)
	if CGD[id] then
		game._player.pckTarget = id
		game._player.pickingUp = true
		local mpcktime = game._function.random(gud[CGD[game._player.pckTarget]["id"]]["mnprs"]*10,gud[CGD[game._player.pckTarget]["id"]]["mxprs"]*10)
		game._player.pckTime, game._player.maxPckTime = mpcktime, mpcktime
		CGD[game._player.id]["cmove"] = false
		CGD[game._player.id]["image"] = -1
		CGD[game._player.id]["mx"] = CGD[game._player.id]["x"]
	end
end

function game._function.getQuestReward(id)
	if gqd[id] then
		addXP(gqd[id]["qreward"]["xp"])
		CGD[game._player.id]["cash"] = CGD[game._player.id]["cash"] + gqd[id]["qreward"]["coins"]
		if gqd[id]["qreward"]["item"] then
			for u = 1, #gqd[id]["qreward"]["item"] do
				if type(gqd[id]["qreward"]["item"][u][1]) == "table" then
					for n = 1, #gqd[id]["qreward"]["item"][u] do
						game._gui.rewardChoice.buffer.items[n] = {}
						game._gui.rewardChoice.buffer.items[n][1] = gqd[id]["qreward"]["item"][u][n][1]
						game._gui.rewardChoice.buffer.items[n][2] = gqd[id]["qreward"]["item"][u][n][2]
						game._gui.rewardChoice.buffer.images[n] = image.load(game._data.text.directory.."itempic/"..game._data.itemIcons[gid[gqd[id]["qreward"]["item"][u][n][1]]["icon"]]..".pic")
					end
					game._data.windowThread = "rewardChoice"
				else
					game._function.addItem(gqd[id]["qreward"]["item"][u][1],gqd[id]["qreward"]["item"][u][2],true)
				end
			end
		end
	else
		game._function.logtxt("game._function.getQuestReward: ID не существует")
	end
end

function game._function.gatheringAction(id)
	pmov = 0
	usepmx = false
	if not gud[CGD[id]["id"]]["reqlvl"] or ( gud[CGD[id]["id"]]["reqlvl"] and gud[CGD[id]["id"]]["reqlvl"] <= CGD[game._player.id]["lvl"]) then
		if gud[CGD[id]["id"]]["reqquest"] then
			for m = 1, #game._player.quests do
				if game._player.quests[m][1] == gud[CGD[id]["id"]]["reqquest"] and game._player.quests[m][3] == false then
					game._function.pickUpResource(id)
				end
			end
		else
			game._function.pickUpResource(id)
		end
	elseif not gud[CGD[id]["id"]]["reqquest"] then
		game._function.showMessage1("Недостаточно опыта")
	end
end

local function getClose(id, cid, distance)
	if CGD[id]["x"] > mathFloor(CGD[cid]["x"]) + CGD[cid]["width"] then
		CGD[id]["mx"] = mathFloor(CGD[cid]["x"]) + CGD[cid]["width"] + game._function.roundupnum(distance)
	elseif CGD[id]["x"] + CGD[id]["width"] < mathFloor(CGD[cid]["x"]) then
		CGD[id]["mx"] = mathCeil(CGD[cid]["x"]) - CGD[id]["width"] - game._function.roundupnum(distance)
	end
end

function game._function.getRawCount(array)
	local count = 0
	for f, v in pairs(array) do
		count = count + 1
	end
	return count
end

function game._function.debugText()
	local text = {
		"#CGD = "..#CGD,
		"#gid = "..#gid,
		"#imageBuffer = "..game._function.getRawCount(imageBuffer),
		"#iconImageBuffer = "..game._function.getRawCount(iconImageBuffer),
	}
	for f = 1, #text do
		buffer.drawText(2,49-#text+f,0xffffff,text[f])
	end
end

game._gui.qPanel = {x=160, y=8, cx=0, w=0, h=0, cscroll=1, minimized = false, list={}, action={}}

function game._gui.qPanel.draw()
	local x, y = game._gui.qPanel.x, game._gui.qPanel.y
	local cl = nil
	local w = 0
	local cx
	if #game._gui.qPanel.list > 0 then
		for f = 1, #game._gui.qPanel.list do
			if unicode.len(game._gui.qPanel.list[f][1])+1 > w then
				w = unicode.len(game._gui.qPanel.list[f][1]) + 1
			end
		end

		game._gui.qPanel.w = mathMin(w, 45)

		cx = mathMin(x, mxw - game._gui.qPanel.w - 1)
		buffer.drawRectangle(cx,y,mathMax(game._gui.qPanel.w, 8), 1, 0x525252, 0, " ")
		-- if limg < 4 then
			-- cl = nil
		-- else
			-- cl = 50
		-- end
		if game._gui.qPanel.minimized == false then
			buffer.drawRectangle(cx, y + 1,mathMax(game._gui.qPanel.w, 8), #game._gui.qPanel.list, 0x828282, 0, " ", cl)
			for f = 1, #game._gui.qPanel.list do
				buffer.drawText(cx, y + f, game._gui.qPanel.list[f][2], game._gui.qPanel.list[f][1])
			end
		end
		buffer.drawText(cx, y, 0xEFEFEF, "Задания")

		if game._gui.qPanel.minimized == false then
			buffer.drawText(cx + w - 1, y, 0xEFEFEF,"^")
		else
			buffer.drawText(cx + w - 1, y, 0xEFEFEF,"V")
		end

		game._gui.qPanel.cx = cx
	end
end

game._gui.qPanel.action["touch"] = function(ev)
	local x, y, w = game._gui.qPanel.cx, game._gui.qPanel.y, game._gui.qPanel.w
	if ev[5] == 0 and clicked(ev[3], ev[4], x + w - 1, y, x + w - 1, y) then
		game._gui.qPanel.minimized = not game._gui.qPanel.minimized
	end
end

--[[
game._function.weaponImg = {
["sword"] = {
	0x787878,0,0," ", 0x787878,0,0," ", 0x787878,0,0," ", 0x787878,0,0," ", 0x787878,0,0," ", 0,0x787878,255,"▶", width = 6, height = 1
	},
}
]]--

local function drawPlayer()
	if CGD[game._player.id]["spos"] == 1 then
			buffer.drawImage(game._player.screenPosition, 49-CGD[game._player.id]["height"]-game._function.roundupnum(CGD[game._player.id]["y"]), imageBuffer[CGD[game._player.id]["image"]],true)
		--buffer.drawImage(game._player.screenPosition+7,40,game._function.weaponImg["sword"])
		else
			buffer.drawImage(game._player.screenPosition, 49-CGD[game._player.id]["height"]-game._function.roundupnum(CGD[game._player.id]["y"]), image.flipHorizontally(imageBuffer[CGD[game._player.id]["image"]]),true)
		end
end

local dping1, dping2, fpstclr, fpsrclr = 0, 0, 0, {{5,0xFF6D00},{9,0xFFB640},{15,0xFFFF40},{50,0x40FF40}}
local deltaT = 0

local function dmain()
	if game._data.windowThread ~= "inventory" and game._data.windowThread ~= "tradewindow" and game._data.windowThread ~= "craftwindow" and game._data.windowThread ~= "menu" then
		if game._config.debugMode == false then
			world[world.current].draw()
		else
			buffer.drawRectangle(1,1,mxw, mxh,0, 0, " ")
		end

		drawPlayer() -- игрок
		game._function.drawAllCGDUnits() -- все юниты
		game._function.drawParticles() -- все частицы
		if game._data.windowThread ~= "screen_save" then
			if CGD[game._player.id]["living"] then
				if game._data.windowThread ~= "pause" then
					game._gui.playerInfoPanel.draw()
				end
				if CGD[game._player.id]["target"] then
					game._gui.targetInfoPanel.draw()
				end
				game._gui.skillsTopPanel.draw()
				game._gui.followerInfo.draw()
				game._gui.qPanel.draw()
			end

			

			if game._data.messageTable1timer > 0 then
				buffer.drawText(9,49,0x929292,">"..( game._data.messageTable1[#game._data.messageTable1-1] or "" ))
				buffer.drawText(9,50,0xC7C7C7,">"..( game._data.messageTable1[#game._data.messageTable1] or "" ))
			end

			if smsg2time > 0 then
				buffer.drawText(80-unicode.len(sMSG2[#sMSG2])/2,12,0xD3D3D3,sMSG2[#sMSG2])
			end

			if smsg4time > 0 then
				buffer.drawText(2,13,0x9C9C9C,sMSG4[#sMSG4-2])
				buffer.drawText(2,14,0xACACAC,sMSG4[#sMSG4-1])
				buffer.drawText(2,15,0xBCBCBC,sMSG4[#sMSG4])
			end

			if #sMSG5 > 0 then
				for n = 1, 3 do
					if sMSG5[n] then
						buffer.drawText(game._player.screenPosition,47-CGD[game._player.id]["height"]-2-n,0xBCBCBC,sMSG5[n])
					end
				end
				smsg5time = smsg5time - 1
				if smsg5time <= 0 then
					table.remove(sMSG5,1)
				end
			end
		end
	end
	
	if game._data.windowThread == nil then buffer.drawText(156,2,0xffffff,"█ █"); buffer.drawText(156,3,0xffffff,"█ █")
	elseif game._data.windowThread == "pause" then game._gui.pauseMenu.draw()
	elseif game._data.windowThread == "inventory" then  game._function.inventory.draw()
	elseif game._data.windowThread == "dialog" then game._gui.NPCDialog.draw()
	elseif game._data.windowThread == "spdialog" then game._function.specialDialog.draw()
	elseif game._data.windowThread == "quests" then game._gui.questsList.draw()
	elseif game._data.windowThread == "console" then game._function.gameConsole.draw()
	elseif game._data.windowThread == "pstats" then game._gui.playerStats.draw()
	elseif game._data.windowThread == "tradewindow" then game._function.tradew.draw()
	elseif game._data.windowThread == "craftwindow" then game._function.craftw.draw()
	elseif game._data.windowThread == "game._function.ydw" then game._function.ydw.draw()
	elseif game._data.windowThread == "skillsWindow" then game._gui.playerSkills.draw()
	elseif game._data.windowThread == "menu" then game._gui.mainMenu.draw()
	elseif game._data.windowThread == "rewardChoice" then game._gui.rewardChoice.draw()
	end
	if game._config.debugMode == true then
		game._function.debugText()
	end
	--buffer.drawText(1,49,0xffffff,"delay: 1="..tostring(dping1).." 2="..tostring(dping2).." 3="..tostring(deltaT).." ms")
	for f = 1, #fpsrclr do
		if fpsrclr[f][1] >= cfps then
			fpstclr = fpsrclr[f][2]
			break
		end
	end

	buffer.drawText(1,50,fpstclr,"fps: "..tostring(cfps))
	usram = game._function.RAMInfo()
	buffer.drawText(160-#usram,50,0xC7C7C7,usram)

	buffer.drawChanges()
end

function game._function.mCheck()
	if computer.totalMemory() >= 2*1024^2 then return true end
	if computer.freeMemory() < 2^14 then return false end
end

function game._function.openInventory()
	game._data.windowThread = "inventory"
	iconImageBuffer[0]={}

	for il = 1, #game._data.emptyArmorPic do
		if game._function.mCheck() then
			iconImageBuffer[0][game._data.emptyArmorPic[il][1]] = image.load(game._data.text.directory..game._data.emptyArmorPic[il][2])
		end
	end

	for f = 1, #CGD[game._player.id]["inventory"]["bag"] do
		if CGD[game._player.id]["inventory"]["bag"][f][1] ~= 0 and CGD[game._player.id]["inventory"]["bag"][f][2] ~= 0 and gid[CGD[game._player.id]["inventory"]["bag"][f][1]] and game._function.mCheck() then
			iconImageBuffer[f] = image.load(game._data.text.directory.."itempic/"..game._data.itemIcons[gid[CGD[game._player.id]["inventory"]["bag"][f][1]]["icon"]]..".pic")
		end
	end

	for f = 1, #game._data.armorType do
		if CGD[game._player.id]["inventory"]["weared"][game._data.armorType[f]] ~= 0 and game._function.mCheck() then
			iconImageBuffer[game._data.armorType[f]] = image.load(game._data.text.directory.."itempic/"..game._data.itemIcons[gid[CGD[game._player.id]["inventory"]["weared"][game._data.armorType[f]]]["icon"]]..".pic")
		end
	end
end

function game._function.codeToSymbol(code)
	local symbol
	if code ~= 0 and code ~= 13 and code ~= 8 and code ~= 9 and code ~= 200 and code ~= 208 and code ~= 203 and code ~= 205 and not keyboard.isControlDown() then
		symbol = unicode.char(code)
		if keyboard.isShiftPressed then symbol = unicode.upper(symbol) end
	end
	return symbol
end

function game._function.getFileList(path)
	local list = fs.list(path)
	local array = {}

	for file in list do
		table.insert(array, file)
	end

	list = nil
	return array
end

function game._function.textInput(ev, inp, limit)
	local text = inp or ""
	if unicode.len(text) <= limit then
		if ev[1] == "key_down" then
			if ev[4] == 28 then
				return text
			elseif ev[4] == 14 and text ~= "" then
				return unicode.sub(text, 1, -2)
			else
				return text .. (game._function.codeToSymbol(ev[3]) or "")
			end
		elseif e[1] == "clipboard" then
			if e[3] then
				return text .. ev[3]
			end
		end
	else
		return text
	end
end

-- Иниц. новой игры
function game._function.initGame()

	game._player.quests = {}

	game._player.pickingUp = false

	game._gui.targetInfoPanel.showTargetInfo = false

	CGD = {}

	savedUnits = {}
	for f = 1, #world
		do
		savedUnits[f] = {}
	end

	world.current = 1

	game._function.addUnit(game._player.id,1,1)

	CGD[game._player.id]["inventory"] = {
		["weared"] = {
		["helmet"] = 0,
		["pendant"] = 0,
		["armor"] = 0,
		["robe"] = 0,
		["pants"] = 0,
		["weapon"] = game._config.startWeapon[gud[game._player.id]["class"]],
		["footwear"] = 0,
		["ring"] = 0},
		["bag"] = {}
	}

	for f = 1, game._parameter.inventorySize do
		CGD[game._player.id]["inventory"]["bag"][f] = {0,0}
	end

	CGD[game._player.id]["class"] = gud[game._player.id]["class"]
	CGD[game._player.id]["levelpoints"] = gud[game._player.id]["lvl"]-1
	CGD[game._player.id]["surv"] = gud[game._player.id]["surv"]
	CGD[game._player.id]["strg"] = gud[game._player.id]["strg"]
	CGD[game._player.id]["int"] = gud[game._player.id]["int"] 
	CGD[game._player.id]["agi"] = gud[game._player.id]["agi"]
	CGD[game._player.id]["criticalhc"] = 1
	CGD[game._player.id]["followers"] = {}
	CGD[game._player.id]["target"] = nil
	CGD[game._player.id]["rage"] = 0
	CGD[game._player.id]["cmp"] = 0
	CGD[game._player.id]["mmp"] = 0
	CGD[game._player.id]["cxp"] = 0
	CGD[game._player.id]["mxp"] = 0
	CGD[game._player.id]["cash"] = 0
	CGD[game._player.id]["cint"] = nil
	CGD[game._player.id]["vx"] = 0
	CGD[game._player.id]["vy"] = 0
	CGD[game._player.id]["petcage"] = {}

	--addXP(5000000) -- !!!!!!!!!!!!!

	cPlayerSkills = {}
	for f = 1, #playerParams[gud[game._player.id]["class"]]["skills"] do
	 cPlayerSkills[f] = {}
	 for n = 1, #playerParams[gud[game._player.id]["class"]]["skills"][f] do
	  cPlayerSkills[f][n] = playerParams[gud[game._player.id]["class"]]["skills"][f][n]
	 end
	end

	game._function.loadWorld(world.current)
	game._function.UpdatePlayerStats()
	game._function.maxXP()
	CGD[game._player.id]["chp"] = CGD[game._player.id]["mhp"]
	CGD[game._player.id]["cmp"] = CGD[game._player.id]["mmp"]
	game._data.windowThread = nil
	game._gui.mainMenu.obj = {}
	game._data.stopDrawing = false
	game._data.paused = false
end

local mainMenulist = {
	"Новая игра",
	"Загрузить игру",
	"Выйти из игры"
}

function game._gui.mainMenu.open(mode)
	game._data.paused = true
	game._data.windowThread = "menu"
	game._gui.mainMenu.obj.img = image.load(game._data.text.directory.."image/slg.pic")
	game._gui.mainMenu.mode = mode
end

game._gui.mainMenu.MenuAction = {
	[1]=function()
		game._gui.mainMenu.mode = 1
	end,
	[2]=function()
		game._gui.mainMenu.mode = 2
		game._gui.mainMenu[2].buff = game._function.getFileList(game._data.text.directory .. "saves")
		if game._gui.mainMenu[2].buff[1] then
			game._gui.mainMenu[2].targ = 1
		end
	end,
	[3]=function()
		game._data.inGame = false
	end,
}

function game._gui.mainMenu.draw()
	-- Фон
	buffer.drawRectangle(1, 1, mxw, mxh, 0x002440, 0, " ")
	buffer.drawRectangle(1, 44, mxw, 6, 0x222222, 0, " ")
	buffer.drawRectangle(1, 50, mxw, 1, 0x000000, 0, " ")
	if (game._gui.mainMenu.obj.img) then
		buffer.drawImage(game._gui.mainMenu.imgx, game._gui.mainMenu.imgy, game._gui.mainMenu.obj.img)
	end

	if math.random(1,5) == 5 then
		tableInsert(game._gui.mainMenu.obj,{x=math.random(4,156),y=50,vx=0.1,vy=-0.005*math.random(1,5)})
	end

	for n = 1, #game._gui.mainMenu.obj do
		game._gui.mainMenu.obj[n].vx = game._gui.mainMenu.obj[n].vx + math.random(-50,50)*0,1
	end


	local n
	for f = 1, #game._gui.mainMenu.obj do
		n = #game._gui.mainMenu.obj-f+1
		if game._gui.mainMenu.obj[n] then
			game._gui.mainMenu.obj[n].vy = game._gui.mainMenu.obj[n].vy - 0.01
			game._gui.mainMenu.obj[n].x = game._gui.mainMenu.obj[n].x + game._gui.mainMenu.obj[n].vx
			game._gui.mainMenu.obj[n].y = game._gui.mainMenu.obj[n].y + game._gui.mainMenu.obj[n].vy
			if game._gui.mainMenu.obj[n].y <= 0 then
				tableRemove(game._gui.mainMenu.obj,n)
			end
		end
	end

	for f = 1, #game._gui.mainMenu.obj do
		buffer.drawText(game._function.roundupnum(game._gui.mainMenu.obj[f].x),mxh-game._function.roundupnum(game._gui.mainMenu.obj[f].y),0x575757,"*")
	end


	local function drawButtons(x,y,array)
		for f = 1, #array do
			ccolor = array[f].bcolor
			if array[f].clicked and array[f].clicked == 1 then
				ccolor = array[f].ccolor
			end
			buffer.drawRectangle(x+array[f].x,y+array[f].y-1,array[f].w,array[f].h, ccolor, 0, " ")
			buffer.drawText(x+array[f].x+mathFloor(array[f].w/2-unicode.len(array[f].txt)/2),y+array[f].y+mathFloor(array[f].h/2)-1,array[f].fcolor,array[f].txt)
		end
	end

 if game._gui.mainMenu.mode == 0 then
 local x, y = mathFloor(mxw/2-game._gui.mainMenu.w/2), mathFloor(mxh/2-game._gui.mainMenu.h/2)
 game._gui.mainMenu.x, game._gui.mainMenu.y = x, y
 local title = "Главное меню"
 buffer.drawRectangle(x, y, game._gui.mainMenu.w, game._gui.mainMenu.h, 0x9D9D9D, 0, " ")
 buffer.drawText(x+mathFloor(game._gui.mainMenu.w/2-unicode.len(title)/2),y+1,0xffffff,title)
  for f = 1, #mainMenulist do
  buffer.drawRectangle(x+game._gui.mainMenu.bx, y+f*4, game._gui.mainMenu.w-game._gui.mainMenu.bx*2, game._gui.mainMenu.bh, 0x838383, 0, " ")
  buffer.drawText(x+mathMax(mathFloor((game._gui.mainMenu.w/2)-(unicode.len(mainMenulist[f])/2)),0),y+f*4+1,0xffffff,mainMenulist[f])
  end
 elseif game._gui.mainMenu.mode == 1 then
 local x, y = mathFloor(mxw/2-game._gui.mainMenu[1].w/2), mathFloor(mxh/2-game._gui.mainMenu[1].h/2)
 local cclolor
 game._gui.mainMenu[1].x, game._gui.mainMenu[1].y = x, y
 local title = "Создание персонажа"
 buffer.drawRectangle(x, y, game._gui.mainMenu[1].w, game._gui.mainMenu[1].h, 0x9D9D9D, 0, " ")
 buffer.drawText(x+mathFloor(game._gui.mainMenu[1].w/2-unicode.len(title)/2),y+1,0xffffff,title)
 drawButtons(x,y,game._gui.mainMenu[1].obj)
 elseif game._gui.mainMenu.mode == 2 then
 local x, y = mathFloor(mxw/2-game._gui.mainMenu[2].w/2), mathFloor(mxh/2-game._gui.mainMenu[2].h/2)
 local ccolor
 game._gui.mainMenu[2].x, game._gui.mainMenu[2].y = x, y
 local title = "Загрузить игру"
 buffer.drawRectangle(x, y, game._gui.mainMenu[2].w, game._gui.mainMenu[2].h, 0x9D9D9D, 0, " ")
 buffer.drawText(x+mathFloor(game._gui.mainMenu[2].w/2-unicode.len(title)/2),y+1,0xffffff,title)
 drawButtons(x,y,game._gui.mainMenu[2].obj)
  for f = 1, #game._gui.mainMenu[2].buff do
  ccolor = 0xffffff
   if f == game._gui.mainMenu[2].targ then
   ccolor = 0x00aa22
   end
  buffer.drawText(x+mathFloor(game._gui.mainMenu[2].w/2-unicode.len(game._gui.mainMenu[2].buff[f])/2),y+6+f*2-2,ccolor,game._gui.mainMenu[2].buff[f])
  end
 end
end

-- Кнопки в главном меню
game._gui.mainMenu.action["touch"] = function(ev)
	if game._gui.mainMenu.mode == 0 then
		for f = 1, #mainMenulist do
			if ev[5] == 0 and clicked(ev[3],ev[4],game._gui.mainMenu.x,game._gui.mainMenu.y+f*4-3,game._gui.mainMenu.x+game._gui.mainMenu.w-1,game._gui.mainMenu.y+f*4+2) then
				pcall(game._gui.mainMenu.MenuAction[f])
				ev[3], ev[4] = 0, 0
				break
			end
		end
	elseif game._gui.mainMenu.mode == 1 then
		for f = 1, #game._gui.mainMenu[1].obj do
			if ev[5] == 0 and game._gui.mainMenu[1].obj[f].type == 1 and clicked(ev[3],ev[4],game._gui.mainMenu[1].x+game._gui.mainMenu[1].obj[f].x,game._gui.mainMenu[1].y+game._gui.mainMenu[1].obj[f].y,game._gui.mainMenu[1].x+game._gui.mainMenu[1].obj[f].x+game._gui.mainMenu[1].obj[f].w-1,game._gui.mainMenu[1].y+game._gui.mainMenu[1].obj[f].y+game._gui.mainMenu[1].obj[f].h-1) then
				pcall(game._gui.mainMenu[1].obj[f].action)
			end
		end
	elseif game._gui.mainMenu.mode == 2 then
		for f = 1, #game._gui.mainMenu[2].obj do
			if ev[5] == 0 and game._gui.mainMenu[2].obj[f].type == 1 and clicked(ev[3],ev[4],game._gui.mainMenu[2].x+game._gui.mainMenu[2].obj[f].x,game._gui.mainMenu[2].y+game._gui.mainMenu[2].obj[f].y,game._gui.mainMenu[2].x+game._gui.mainMenu[2].obj[f].x+game._gui.mainMenu[2].obj[f].w-1,game._gui.mainMenu[2].y+game._gui.mainMenu[2].obj[f].y+game._gui.mainMenu[2].obj[f].h-1) then
				pcall(game._gui.mainMenu[2].obj[f].action)
			end
		end
		for f = 1, #game._gui.mainMenu[2].buff do
			if ev[5] == 0 and clicked(game._gui.mainMenu[2].x,game._gui.mainMenu[2].y+6+f*2-2,game._gui.mainMenu[2].x+game._gui.mainMenu[2].w-1,game._gui.mainMenu[2].y+6+f*2-2) then
				game._gui.mainMenu[2].targ = f
			end
		end
	end
end

game._gui.mainMenu.action["key_down"] = function(ev)
 if game._gui.mainMenu.mode == 1 then
 game._gui.mainMenu[1].obj[4].txt = game._function.textInput(ev, game._gui.mainMenu[1].obj[4].txt, 18)
 elseif game._gui.mainMenu.mode == 2 and game._gui.mainMenu[2].targ then
  if ev[4] == 200 and game._gui.mainMenu[2].targ > 1 then
  game._gui.mainMenu[2].targ = game._gui.mainMenu[2].targ - 1
  elseif ev[4] == 208 and game._gui.mainMenu[2].targ < #game._gui.mainMenu[2].buff then
  game._gui.mainMenu[2].targ = game._gui.mainMenu[2].targ + 1
  end
 end
end

local healthReg, manaReg

local function functionPS()
	local value, duration, efftype, itemLootarray, qwert, asdf, regenMultiplier, cl
	local uMoveRef = 8
	local deltan = 0
	while game._data.inGame do
		cfps = gamefps
		gamefps = 0
		if not game._data.paused then
			--deltan = os.clock()
			game._function.UpdatePlayerStats()
			-- вещи не достойные внимания ниже
			if CGD[game._player.id]["target"] and game._function.getDistanceToId(game._player.id,CGD[game._player.id]["target"]) > 99 then
				CGD[game._player.id]["target"] = nil
				game._gui.targetInfoPanel.showTargetInfo = false
			end
			if uMoveRef <= 0 then
				uMoveRef = 8
			end
			uMoveRef = uMoveRef - 1
			if vtskillUsingMsg > 0 then
				vtskillUsingMsg = vtskillUsingMsg - 1
			end
			regenMultiplier = 1
			if CGD[game._player.id]["rage"] > 0 then
				regenMultiplier = 0.1
				CGD[game._player.id]["rage"] = CGD[game._player.id]["rage"] - 1
			end

			-- Табличка о том, что вас добили
			if CGD[game._player.id]["living"] == false then
				game._data.windowThread = "game._function.ydw"
				game._data.paused = true
			end
			
			-- Табличка с заданиями (тест)
			game._gui.qPanel.list = {}
			for f = game._gui.qPanel.cscroll, mathMin(#game._player.quests,10) + game._gui.qPanel.cscroll do
				if game._player.quests[f] then
					if game._player.quests[f][3] == true then
						cl = 0x00C222
					else
						cl = 0xEFEFEF
					end
					game._gui.qPanel.list[#game._gui.qPanel.list+1] = {"→"..gqd[game._player.quests[f][1]]["name"],cl}
					if gqd[game._player.quests[f][1]]["type"] == 1 and type(gqd[game._player.quests[f][1]]["num"]) == "number" then
						game._gui.qPanel.list[#game._gui.qPanel.list+1] = {" "..gud[gqd[game._player.quests[f][1]]["targ"]]["name"].."("..game._player.quests[f][2].."/"..gqd[game._player.quests[f][1]]["num"]..")",cl}
					end
				end
			end

			-- кв на предметы
			for f = 1, #game._player.quests do
				if gqd[game._player.quests[f][1]]["type"] == 2 then
					game._player.quests[f][3] = false
					if type(gqd[game._player.quests[f][1]]["targ"][1]) == "number" then
						game._player.quests[f][2] = game._function.checkItemInBag(gqd[game._player.quests[f][1]]["targ"][1])
						if game._player.quests[f][2] >= gqd[game._player.quests[f][1]]["targ"][2] then
							game._player.quests[f][3] = true
						end
					else
						local comp = 0
						for i = 1, #gqd[game._player.quests[f][1]]["targ"] do
							game._player.quests[f][2][i] = game._function.checkItemInBag(gqd[game._player.quests[f][1]]["targ"][i][1])
							if game._player.quests[f][2][i] >= gqd[game._player.quests[f][1]]["targ"][i][2] then
								comp = comp + 1
							end
						end
						if comp == #gqd[game._player.quests[f][1]]["targ"] then
							game._player.quests[f][3] = true
						end
					end
				end
			end
			-- автоматическое завершение кв
			for f = 1, #game._player.quests do
				if gqd[game._player.quests[f][1]]["type"] == 3 and game._player.quests[f][3] == false then
					game._player.quests[f][3] = true
				end
			end
			-- восстановдение маны, здоровья в сек.
			manaReg = mathMax(0, 0.75 + (CGD[game._player.id]["lvl"] - 1) * 0.22 + CGD[game._player.id]["int"] * 0.1) * regenMultiplier
			healthReg = mathMax(0, 0.75 + (CGD[game._player.id]["lvl"] - 1) * 0.21 + CGD[game._player.id]["surv"] * 0.1) * regenMultiplier

			if CGD[game._player.id]["living"] then
				-- восстановление маны персонажа
				if CGD[game._player.id]["cmp"] < CGD[game._player.id]["mmp"] - manaReg then
					CGD[game._player.id]["cmp"] = CGD[game._player.id]["cmp"] + manaReg
				else
					CGD[game._player.id]["cmp"] = CGD[game._player.id]["mmp"]
				end
				-- восстановление здоровья персонажа
				if CGD[game._player.id]["chp"] < CGD[game._player.id]["mhp"] - healthReg then
					CGD[game._player.id]["chp"] = CGD[game._player.id]["chp"] + healthReg
				else
					CGD[game._player.id]["chp"] = CGD[game._player.id]["mhp"]
				end
			end
			-- респавн во всех измерениях
			for f = 1, #savedUnits do
				if f ~= world.current and savedUnits[f] then
					for n = 1, #savedUnits[f] do
						if savedUnits[f][n][4] > 0 then
							savedUnits[f][n][4] = savedUnits[f][n][4] - 1
						end
					end
				end
			end
			-- обслуживание союзников
			if CGD[game._player.id]["followers"] then
				for f = 1, #CGD[game._player.id]["followers"] do
					if not CGD[CGD[game._player.id]["followers"][f][2]]["target"] and game._function.getDistanceToId(CGD[game._player.id]["followers"][f][2], game._player.id) > 10 then
						if game._function.getDistanceToId(CGD[game._player.id]["followers"][f][2], game._player.id) > 160 then
							CGD[CGD[game._player.id]["followers"][f][2]]["x"] = CGD[game._player.id]["x"] + math.random(-10,10)
							CGD[CGD[game._player.id]["followers"][f][2]]["mx"] = CGD[CGD[game._player.id]["followers"][f][2]]["x"]
						else
							getClose(CGD[game._player.id]["followers"][f][2], game._player.id, 8)
						end
					end
					--if CGD[CGD[game._player.id]["followers"][f][2]]["target"] and not CGD[CGD[CGD[game._player.id]["followers"][f][2]]["target"]]["living"] then
					--	CGD[CGD[game._player.id]["followers"][f][2]]["target"] = nil
					--end
					if not CGD[CGD[game._player.id]["followers"][f][2]]["target"] then
						game._function.addHealth(CGD[game._player.id]["followers"][f][2], CGD[CGD[game._player.id]["followers"][f][2]]["mhp"] * 0.01)
					end
				end
			end

			for f = 1, #CGD do
				if CGD[f] then
				-- рандомное движение мобов
					if uMoveRef == 0 then
						if CGD[f]["rtype"] == "e" and CGD[f]["living"] and game._function.random(1,3) == 3 and game._function.getDistanceToId(game._player.id,f) <= 384 then
							CGD[f]["mx"] = CGD[f]["sx"] + game._function.random(-8, 8)
						end
					end
				-- моб подходит и бьёт игрока
					if --[[isRtype(f, "e", "p") ]] (CGD[f]["rtype"] == "e" or CGD[f]["rtype"] == "p") and CGD[f]["target"] and f ~= game._player.id then
						if gud[CGD[f]["id"]]["skill"] then
							qwert = {gud[CGD[f]["id"]]["skill"][#gud[CGD[f]["id"]]["skill"]][1],gud[CGD[f]["id"]]["skill"][#gud[CGD[f]["id"]]["skill"]][2]}
							asdf = getMixedSequence(gud[CGD[f]["id"]]["skill"])
							for o = 1, #asdf do
								if game._function.random(1,100) <= asdf[o][3] then
									qwert = {asdf[o][1],asdf[o][2]}
									break
								end
							end
						else
							qwert = {1,1}
						end
						game._function.enemySkill(f, CGD[f]["target"], qwert[1], qwert[2])
					end
					qwert = nil

					if CGD[f]["target"] and not CGD[CGD[f]["target"]]["living"] then
						CGD[f]["target"] = nil
					end

					if CGD[f]["rtype"] == "e" then
					-- произвольное восстановление жс на 5%/сек.
						if CGD[f]["сhp"] ~= CGD[f]["mhp"] and CGD[f]["living"] and not CGD[f]["target"] then
							if CGD[f]["chp"] + mathCeil(CGD[f]["mhp"] * 0.05) < CGD[f]["mhp"] then
								CGD[f]["chp"] = CGD[f]["chp"] + mathCeil(CGD[f]["mhp"] * 0.05)
							else
								CGD[f]["chp"] = CGD[f]["mhp"]
							end
						end
					-- респавн мобов
						if not CGD[f]["living"] and CGD[f]["resptime"] > 0 then
							CGD[f]["resptime"] = CGD[f]["resptime"] - 1
						elseif not CGD[f]["living"] and CGD[f]["resptime"] == 0 then
							CGD[f]["chp"] = CGD[f]["mhp"]
							CGD[f]["x"] = CGD[f]["sx"]
							CGD[f]["living"] = true
						end

						if CGD[f]["living"] and CGD[f]["target"] and game._function.getDistanceToId(game._player.id,f) > 60 then
							CGD[f]["target"] = nil
							CGD[f]["mx"] = CGD[f]["sx"]
						end

					-- агр мобов
						if CGD[f]["rtype"] == "e" and CGD[f]["living"] and gud[CGD[f]["id"]]["agr"] == 1 then
							for n = 1, #CGD do
								if CGD[n]["rtype"] == "p" and CGD[n]["living"] and game._function.getDistanceToId(n,f) <= 25 then
									CGD[f]["target"] = n
									break
								end
							end
						end
					-- самотаргет
						-- if CGD[game._player.id]["target"] == nil and CGD[f]["living"] then
							-- CGD[game._player.id]["target"] = f
						-- end
					end
					-- обслуживание всех эффектов на всех объектах
					CGD[f]["cmove"] = true
					CGD[f]["ctck"] = true
					if f ~= game._player.id and #CGD[f]["effects"] > 0 then
						game._function.updateUnitStats(f)
					end
					for eff = 1, #CGD[f]["effects"] do
						qwert = CGD[f]["effects"][#CGD[f]["effects"]-eff+1]
						if CGD[f]["living"] and qwert ~= nil then
							if ged[qwert[1]]["val"] then
								value = ged[qwert[1]]["val"][qwert[3]]
							end
							duration = ged[qwert[1]]["dur"][qwert[3]]
							efftype = ged[qwert[1]]["type"]
							if efftype == "hpi" then -- Увеличение хп на 'value' за 'duration' секунд
								if CGD[f]["chp"] + value/duration < CGD[f]["mhp"] then
									CGD[f]["chp"] = CGD[f]["chp"] + value/duration
								else
									CGD[f]["chp"] = CGD[f]["mhp"]
								end
							elseif efftype == "mpi" then -- Увеличение мп на 'value' за 'duration' секунд
								if CGD[f]["cmp"] and CGD[f]["mmp"] then
									CGD[f]["cmp"] = mathMax(mathMin(CGD[f]["cmp"] + value/duration,CGD[f]["mmp"]),0)
								end
							elseif efftype == "hpi%" then -- Увеличение макс. хп в %
								CGD[f]["chp"] = mathMin(CGD[f]["chp"] + CGD[f]["mhp"]*value*0.01,CGD[f]["mhp"])
							elseif efftype == "hpd" then -- Уменьшение хп на 'value' за 'duration' секунд
								if f == game._player.id or not qwert[4] then
									game._function.makeDamage(f,value/duration)
								else
									game._function.enemyDamage(f, fromID, value/duration)
								end
							elseif efftype == "pdfi%" then -- Увеличение физ. защиты в %
								CGD[f]["pdef"] = CGD[f]["pdef"]+mathCeil(value/100*CGD[f]["pdef"])
							elseif efftype == "mdfi%" then -- Увеличение маг. защиты в %
								CGD[f]["mdef"] = CGD[f]["mdef"]+mathCeil(value/100*CGD[f]["mdef"])
							elseif efftype == "stn" then -- Оглушение (нельзя двигаться и атаковать)
								CGD[f]["cmove"] = false
								CGD[f]["ctck"] = false
							elseif efftype == "ste" then -- Заморозка (нельзя двигаться)
								CGD[f]["cmove"] = false
							end
							if qwert ~= nil then
								qwert[2] = qwert[2] - 1
								if qwert[2] == 0 then -- Действие эффекта закончилось
									if game._gui.playerInfoPanel.effectDescription == qwert[1] then
										game._gui.playerInfoPanel.effectDescription = 0 -- Если было открыто описание, закрыть
									end
									tableRemove(CGD[f]["effects"],#CGD[f]["effects"]-eff+1)
								end
							end
						end
					end
				
				end -- if CGD[f] then ..

				-- надписи над головой
				if CGD[f]["tlinfo"] and #CGD[f]["tlinfo"] > 0 then
					if CGD[f]["tlinfo"][1] then
						tableRemove(CGD[f]["tlinfo"],1)
					end
				end
			end
		------------------------------------------------
			if game._data.messageTable1timer > 0 then
				game._data.messageTable1timer = game._data.messageTable1timer - 1
			end
			if smsg2time > 0 then
				smsg2time = smsg2time - 1
			end
			if smsg4time > 0 then
				smsg4time = smsg4time - 1
			end

		-- Удаление частиц
			local numParticles = #particles
			for i = numParticles, 1, -1 do
				if particles[i].life == 0 then
					tableRemove(particles, i)
				else
					particles[i].life = particles[i].life - 1
				end
			end

		--setScreenNewPosition() -- сдвиг камеры
			if sScreenTimer1 > 0 then sScreenTimer1 = sScreenTimer1 - 1 end

			if lostItem and not game._function.checkInventoryisFull() then -- дает предмет который не поместился в инвентарь
				game._function.addItem(lostItem[1],lostItem[2],true)
				lostItem = nil
			end
		-- Амулет, автовосстановление жс, мэ
			for f = 1, #CGD[game._player.id]["inventory"]["bag"] do
				if CGD[game._player.id]["inventory"]["bag"][f][1] > 0 and CGD[game._player.id]["inventory"]["bag"][f][2] > 0 and gid[CGD[game._player.id]["inventory"]["bag"][f][1]] and CGD[game._player.id]["living"] and gid[CGD[game._player.id]["inventory"]["bag"][f][1]]["type"] == 7 then
					if gid[CGD[game._player.id]["inventory"]["bag"][f][1]]["subtype"] == 1 and CGD[game._player.id]["chp"] <= CGD[game._player.id]["mhp"]*(gid[CGD[game._player.id]["inventory"]["bag"][f][1]]["props"]["r"]*0.01) then
						CGD[game._player.id]["chp"] = mathMin(CGD[game._player.id]["chp"]+CGD[game._player.id]["mhp"]*0.01*gid[CGD[game._player.id]["inventory"]["bag"][f][1]]["props"]["ics"],CGD[game._player.id]["mhp"])
						CGD[game._player.id]["inventory"]["bag"][f][2] = CGD[game._player.id]["inventory"]["bag"][f][2] - 1
						break
					elseif gid[CGD[game._player.id]["inventory"]["bag"][f][1]]["subtype"] == 2 and CGD[game._player.id]["cmp"] <= CGD[game._player.id]["mmp"]*(gid[CGD[game._player.id]["inventory"]["bag"][f][1]]["props"]["r"]*0.01) then
						CGD[game._player.id]["cmp"] = mathMin(CGD[game._player.id]["cmp"]+CGD[game._player.id]["mmp"]*0.01*gid[CGD[game._player.id]["inventory"]["bag"][f][1]]["props"]["ics"],CGD[game._player.id]["mmp"])
						CGD[game._player.id]["inventory"]["bag"][f][2] = CGD[game._player.id]["inventory"]["bag"][f][2] - 1
						break
					end
				end
			end

			--dping1 = mathFloor((os.clock() - deltan)*10000)/100
		end
		os.sleep(1)
	end
end

-- local function funcP4()
	-- local tblpbl
	-- while game._data.inGame do
		-- if not game._data.paused then
			-- for f = 1, #CGD do
				-- if CGD[f] then
				-- -- мобы бегают быстрее
					-- if CGD[f]["rtype"] == "e" and CGD[f]["living"] and CGD[f]["x"] ~= CGD[f]["mx"] and game._function.getDistanceToId(game._player.id,f) <= 256  and not gud[CGD[f]["id"]]["cmve"] and CGD[f]["cmove"] then
						-- tblpbl = 0.25
						-- if CGD[f]["target"] then
							-- tblpbl = 0.5
						-- end
						-- if game._function.getDistanceToId(game._player.id,f) >= gud[CGD[f]["id"]]["atds"]*2 then
							-- tblpbl = 1
						-- end
						-- game._function.moveToward(f, CGD[f]["mx"], 100, tblpbl)
					-- end

					-- if CGD[f]["rtype"] == "p" and f ~= game._player.id and CGD[f]["living"] and game._function.getDistanceToId(game._player.id,f) <= 256 and CGD[f]["x"] ~= CGD[f]["mx"] and not gud[CGD[f]["id"]]["cmve"] and CGD[f]["cmove"] then
						-- tblpbl = mathMax(game._function.getDistanceToId(f, game._player.id) / 20, 1)
						-- game._function.moveToward(f, CGD[f]["mx"], nil, tblpbl)
					-- end
				-- end
			-- end
		-- end
	-- os.sleep(0.25)
	-- end
-- end

local pimg4t = 0

local function funcP10()
	local dec = 0
	local deltan, tblpbl
	while game._data.inGame do
		if not game._data.paused then
			--deltan = os.clock()
				if dec == 0 then -- 1/10 сек
					if game._player.pickingUp then
						CGD[game._player.id]["mx"] = CGD[game._player.id]["x"]
						game._player.pckTime = game._player.pckTime - 1
						if CGD[game._player.id]["image"] ~= -1 then
							CGD[game._player.id]["image"] = -1
						end
					end
				-- копание тут
					if game._player.pickingUp and game._player.pckTime == 0 and game._player.pckTarget then
						CGD[game._player.id]["image"] = 0
						game._player.pickingUp = false
						itemLootarray = getMixedSequence(gud[CGD[game._player.pckTarget]["id"]]["items"])
						for item = 1, #itemLootarray do
							if itemLootarray[item][1] ~= nil and 1000-itemLootarray[item][2]*10 <= game._function.random(1,1000) then
								if game._function.random(1,15) == 5 then
									itemLootarray[item][1] = createNewItem(itemLootarray[item][1])
								end
								game._function.addItem(itemLootarray[item][1],1,true)
								break
							end
						end
						addXP(gud[CGD[game._player.pckTarget]["id"]]["exp"])
						game._function.addCoins(gud[CGD[game._player.pckTarget]["id"]]["coins"])
						CGD[game._player.id]["cmove"] = true
						CGD[game._player.pckTarget]["living"] = false
						CGD[game._player.pckTarget]["resptime"] = gud[CGD[game._player.pckTarget]["id"]]["vresp"]
						if game._player.pckTarget == CGD[game._player.id]["target"] then
							CGD[game._player.id]["target"] = nil
						end
					end
				-- умения перезаряжаются
					for f = 1, #game._player.actSkills do
						if game._player.actSkills[f] > 0 and cPlayerSkills[game._player.actSkills[f]][1] > 0 and cPlayerSkills[game._player.actSkills[f]][2] > 0 then
							cPlayerSkills[game._player.actSkills[f]][2] = mathMax(cPlayerSkills[game._player.actSkills[f]][2] - 1, 0)
						end
					end

					if CGD[game._player.id]["cint"] and CGD[game._player.id]["cint"][2] ~= 0 then
						if CGD[game._player.id]["cint"][1] == 1 and game._function.getDistanceToId(game._player.id,CGD[game._player.id]["cint"][2]) <= CGD[game._player.id]["cint"][3] then
							game._function.gatheringAction(CGD[game._player.id]["cint"][2])
							CGD[game._player.id]["cint"] = nil
						elseif CGD[game._player.id]["cint"][1] == 2 then
							if cPlayerSkills[game._player.actSkills[1]] and not game._player.pickingUp and CGD[CGD[game._player.id]["cint"][2]] and CGD[CGD[game._player.id]["cint"][2]]["living"] then
								if CGD[game._player.id]["cint"] and game._function.getDistanceToId(game._player.id,CGD[game._player.id]["cint"][2]) <= CGD[game._player.id]["cint"][3] then
									pmov = 0
									game._player.usepmx = false
									game._function.useSkill(CGD[game._player.id]["cint"][4] or 1)
									if CGD[game._player.id]["cint"] then
										CGD[game._player.id]["cint"][4] = 1
									end
								else
									getClose(game._player.id, CGD[game._player.id]["cint"][2], CGD[game._player.id]["cint"][3])
									game._player.usepmx = true
								end
							else
								CGD[game._player.id]["cint"] = nil
							end
						end
					end

					if CGD[game._player.id]["target"] and not CGD[CGD[game._player.id]["target"]]["living"] then
						CGD[game._player.id]["target"] = nil
					end

					-- что это такое?
					if CGD[game._player.id]["image"] == -4 then
						if pimg4t >= 2 then
							CGD[game._player.id]["image"] = 0
							pimg4t = 0
						end
						pimg4t = pimg4t + 1
					end
				end
				if dec > -1 then -- 1/20 сек.
					-- это работает при ctrl + стрелки или ctrl + A/D
					if game._player.usepmx and CGD[game._player.id]["x"] ~= CGD[game._player.id]["mx"] then
						game._function.playerAutoMove(mathFloor(CGD[game._player.id]["mx"]), 9999, 3)
					else
						game._player.usepmx = false
					end
					game._player.moveLock = false
					if CGD[game._player.id]["x"] <= world[world.current].limitL and pmov < 0 then
						game._player.moveLock = true
						CGD[game._player.id]["image"] = 0
					elseif CGD[game._player.id]["x"] >= world[world.current].limitR and pmov > 0 then
						game._player.moveLock = true
						CGD[game._player.id]["image"] = 0
					end
					-- ходьба и её отстойная анимация
					if not game._player.pickingUp and not game._player.moveLock and pmov ~= 0 and CGD[game._player.id]["cmove"] then
						if game._player.usepmx and CGD[game._player.id]["x"] == CGD[game._player.id]["mx"] then
							pmov = 0
							CGD[game._player.id]["mx"] = math.huge
						end
						CGD[game._player.id]["x"] = CGD[game._player.id]["x"] + pmov
						cGlobalx = cGlobalx + pmov
						cBackgroundPos = cBackgroundPos + pmov
						if game._function.cim <= 3 then
							CGD[game._player.id]["image"] = -3
						elseif game._function.cim > 3 and game._function.cim <= 6 then
							CGD[game._player.id]["image"] = 0
						else
							CGD[game._player.id]["image"] = -2
						end
						if game._function.cim > 9 then
							game._function.cim = 1
						end
						game._function.cim = game._function.cim + 1
					end

					--if CGD[game._player.id]["vx"] ~= 0 then CGD[game._player.id]["x"] = CGD[game._player.id]["x"] + CGD[game._player.id]["vx"] end
					if CGD[game._player.id]["y"] >= 1 then
						CGD[game._player.id]["vy"] = CGD[game._player.id]["vy"] - 0.15
					else
						CGD[game._player.id]["vy"] = 0
						CGD[game._player.id]["y"] = 1
					end
					if CGD[game._player.id]["vy"] ~= 0 then
						CGD[game._player.id]["y"] = CGD[game._player.id]["y"] + CGD[game._player.id]["vy"]
					end

					--____________________________________--

					for f = 1, #CGD do
						if CGD[f] then
						-- мобы бегают быстрее
							if CGD[f]["rtype"] == "e" and CGD[f]["living"] and CGD[f]["x"] ~= CGD[f]["mx"] and game._function.getDistanceToId(game._player.id,f) <= 256  and not gud[CGD[f]["id"]]["cmve"] and CGD[f]["cmove"] then
								tblpbl = 0.25
								if CGD[f]["target"] then
									tblpbl = 0.5
								end
								game._function.moveToward(f, CGD[f]["mx"], 160, tblpbl)
							end

							if CGD[f]["rtype"] == "p" and f ~= game._player.id and CGD[f]["living"] and game._function.getDistanceToId(game._player.id,f) <= 256 and CGD[f]["x"] ~= CGD[f]["mx"] and not gud[CGD[f]["id"]]["cmve"] and CGD[f]["cmove"] then
								tblpbl = 1
								game._function.moveToward(f, CGD[f]["mx"], nil, tblpbl)
							end
						end
					end

					--------------------------------------

				end
				
				--dping2 = mathFloor((os.clock() - deltan)*10000)/100
			end
		os.sleep(0.05)
		if dec == 0 then
			dec = 1
		else
			dec = 0
		end
	end
end

game._function.cim = 1
game._player.moveLock = false

local function screen()
	local deltaD = 0
	while game._data.inGame do
		if not game._data.stopDrawing then
			--deltaD = os.clock()
			dmain()
			--deltaT = mathFloor((os.clock() - deltaD)*10000)/100
			gamefps = gamefps + 1
		end
		os.sleep(0.000001)
	end
end

local function main()
	local ev
	while game._data.inGame do
		ev = table.pack(event.pull())
		if ev[1] == "key_down" then
			if ev[4] == 44 then
				game._data.inGame = false
			end

			if (ev[4] == game._parameter.keys.right1 or ev[4] == game._parameter.keys.right2) and not game._data.paused and CGD[game._player.id]["x"] <= world[world.current].limitR and CGD[game._player.id]["cmove"] and CGD[game._player.id]["cmove"] then -- вправо
				CGD[game._player.id]["cint"] = nil
				game._player.usepmx = false
				if keyboard.isAltDown() then
					CGD[game._player.id]["mx"] = world[world.current].limitR
					game._player.usepmx = true
				else
					pmov = 3
					CGD[game._player.id]["spos"] = 1
					game._function.keyactionmove = true
				end
			elseif (ev[4] == game._parameter.keys.left1 or ev[4] == game._parameter.keys.left2) and not game._data.paused and CGD[game._player.id]["x"] >= world[world.current].limitL and CGD[game._player.id]["cmove"] and CGD[game._player.id]["cmove"] then -- влево
				CGD[game._player.id]["cint"] = nil
				game._player.usepmx = false
				if keyboard.isAltDown() then
					CGD[game._player.id]["mx"] = world[world.current].limitL
					game._player.usepmx = true
				else
					pmov = -3
					CGD[game._player.id]["spos"] = 0
					game._function.keyactionmove = true
				end
			end
			--
			if game._data.windowThread == "console" then
				game._function.gameConsole.action["key_down"](ev)
			elseif game._data.windowThread == "menu" then
				game._gui.mainMenu.action["key_down"](ev)
			end

			-- Нажатие клавиши 'B'
			if game._data.windowThread == nil and ev[4] == game._parameter.keys.openInventory then
				game._data.paused = true
				game._function.openInventory()
			elseif game._data.windowThread == "inventory" and ev[4] == game._parameter.keys.closeInventory then
				game._data.paused = false; game._data.windowThread = nil
				iconImageBuffer = {}
				showItemData = false
			end

			if game._data.windowThread == nil and not game._data.paused then

				if ev[4] >= 2 and ev[4] <= 7 then
					for f = 1, 6 do
						if ev[4] == f + 1 and CGD[game._player.id]["target"] and game._player.actSkills[f] > 0 and cPlayerSkills[game._player.actSkills[f]] and cPlayerSkills[game._player.actSkills[f]][3] > 0 and not game._player.pickingUp then
							if gsd[cPlayerSkills[game._player.actSkills[f]][1]]["type"] == 1 then
								vAttackDistance = vAttackDistance or 8
								if game._function.getDistanceToId(game._player.id,CGD[game._player.id]["target"]) > game._function.getPlayerAtdsBySkill(f) then
									CGD[game._player.id]["cint"] = {2,CGD[game._player.id]["target"],game._function.getPlayerAtdsBySkill(f),f}
								else
									game._function.useSkill(f)
									CGD[game._player.id]["cint"] = {2,CGD[game._player.id]["target"],game._function.getPlayerAtdsBySkill(f),f}
									game._player.usepmx = false
									pmov = 0
									CGD[game._player.id]["mx"] = CGD[game._player.id]["x"]
									break
								end
							elseif gsd[cPlayerSkills[game._player.actSkills[f]][1]]["type"] == 3 then
								game._function.useSkill(f)
								CGD[game._player.id]["cint"] = nil
								pmov = 0
								break
							end
						end
					end
				end
				-- Нажатие клавиши 'E'
				if ev[4] == game._parameter.keys.interact and CGD[game._player.id]["target"] then
					-- на нпс
					if CGD[CGD[game._player.id]["target"]]["rtype"] == "f" and game._function.getDistanceToId(game._player.id, CGD[game._player.id]["target"]) <= 40 then
						game._gui.NPCDialog.start(CGD[game._player.id]["target"])
					-- на ресурс
					elseif CGD[CGD[game._player.id]["target"]]["rtype"] == "r" and not game._player.pickingUp then
						if game._function.getDistanceToId(game._player.id,CGD[game._player.id]["target"]) <= 11 then
							game._function.gatheringAction(CGD[game._player.id]["target"])
						else
							CGD[game._player.id]["cint"] = {1,CGD[game._player.id]["target"],5}
							getClose(game._player.id, CGD[game._player.id]["target"], 5)
							game._player.usepmx = true
						end
					-- на портал
					elseif CGD[CGD[game._player.id]["target"]]["rtype"] == "c" and not game._player.pickingUp and game._function.getDistanceToId(game._player.id,CGD[game._player.id]["target"]) <= 10 then
						if gud[CGD[CGD[game._player.id]["target"]]["id"]]["tlp"] == "r" then
							game._function.loadWorld(world[world.current].drespawn)
						elseif type(gud[CGD[CGD[game._player.id]["target"]]["id"]]["tlp"]) == "table" then
							game._function.teleport(gud[CGD[CGD[game._player.id]["target"]]["id"]]["tlp"][2],gud[CGD[CGD[game._player.id]["target"]]["id"]]["tlp"][1])
						end
					end
				end
				-- пробел
				if ev[4] == game._parameter.keys.jump then
					if CGD[game._player.id]["y"] <= 1 and not game._player.pickingUp then
						CGD[game._player.id]["vy"] = 1.5
					end
				end

				-- Нажатие клавиши 'O'
				if ev[4] == game._parameter.keys.spawn then
					if #CGD[game._player.id]["followers"] > 0 then
						game._function.removeFollowers()
					else
						game._function.addFollower(1)
					end
				end

				-- Нажатие клавиши 'K'
				if ev[4] == game._parameter.keys.followerAction then
					for f = 1, #CGD[game._player.id]["followers"] do
						CGD[CGD[game._player.id]["followers"][f][2]]["target"] = CGD[game._player.id]["target"]
					end
				end

				-- Нажатие клавиши 'T'
				if ev[4] == game._parameter.keys.hp then
					for f = 1, #CGD[game._player.id]["inventory"]["bag"] do
						if CGD[game._player.id]["inventory"]["bag"][f][1] > 0 and CGD[game._player.id]["inventory"]["bag"][f][2] > 0 and gid[CGD[game._player.id]["inventory"]["bag"][f][1]]["type"] == 4 and gid[CGD[game._player.id]["inventory"]["bag"][f][1]]["subtype"] == 1 and CGD[game._player.id]["lvl"] >= gid[CGD[game._player.id]["inventory"]["bag"][f][1]]["required"]["lvl"] then
							game._function.addUnitEffect(game._player.id,game._parameter.healthPotionEffectID,gid[CGD[game._player.id]["inventory"]["bag"][f][1]]["lvl"])
							CGD[game._player.id]["inventory"]["bag"][f][2] = CGD[game._player.id]["inventory"]["bag"][f][2] - 1
							break
						end
					end
				-- Нажатие клавиши 'Y'
				elseif ev[4] == game._parameter.keys.mp then
					for f = 1, #CGD[game._player.id]["inventory"]["bag"] do
						if CGD[game._player.id]["inventory"]["bag"][f][1] > 0 and CGD[game._player.id]["inventory"]["bag"][f][2] > 0 and gid[CGD[game._player.id]["inventory"]["bag"][f][1]]["type"] == 4 and gid[CGD[game._player.id]["inventory"]["bag"][f][1]]["subtype"] == 2 and CGD[game._player.id]["lvl"] >= gid[CGD[game._player.id]["inventory"]["bag"][f][1]]["required"]["lvl"] then
							game._function.addUnitEffect(game._player.id,game._parameter.manaPotionEffectID,gid[CGD[game._player.id]["inventory"]["bag"][f][1]]["lvl"])
							CGD[game._player.id]["inventory"]["bag"][f][2] = CGD[game._player.id]["inventory"]["bag"][f][2] - 1
							break
						end
					end
				end
			end
		end
		if ev[1] == "key_up" then
			if game._data.windowThread == nil then
				if ( ev[4] == game._parameter.keys.right1 or ev[4] == game._parameter.keys.right2 or ev[4] == game._parameter.keys.left1 or ev[4] == game._parameter.keys.left2 ) and not keyboard.isAltDown() then
					if not game._player.pickingUp then
						CGD[game._player.id]["image"] = 0
					end
					game._player.usepmx = false
					pmov = 0
				end
			end
		end
		if ev[1] == "touch" then

			--кнопка пауза
			if game._data.windowThread == nil and ev[5] == 0 and clicked(ev[3],ev[4],game._gui.pauseMenu.buttonX,game._gui.pauseMenu.buttonY,game._gui.pauseMenu.buttonX+2,game._gui.pauseMenu.buttonY+1) then
				game._data.windowThread = "pause"
				game._data.paused = true
			elseif ev[5] == 0 and game._data.windowThread == "pause" and clicked(ev[3],ev[4],game._gui.pauseMenu.buttonX,game._gui.pauseMenu.buttonY,game._gui.pauseMenu.buttonX+2,game._gui.pauseMenu.buttonY+1) then
				game._data.windowThread = nil
				game._data.paused = false
			end

			if game._data.windowThread == nil then
				--кнопка эксп
				if not game._data.paused then
					if clicked(ev[3],ev[4],game._gui.playerInfoPanel.x,game._gui.playerInfoPanel.y+3,game._gui.playerInfoPanel.x+game._gui.playerInfoPanel.w-1,game._gui.playerInfoPanel.y+3) then
						svxpbar = true
					else
						svxpbar = false
					end
				end

				--выделить себя
				if ev[5] == 0 and not game._data.paused and clicked(ev[3],ev[4],game._gui.playerInfoPanel.x,game._gui.playerInfoPanel.y,game._gui.playerInfoPanel.x+game._gui.playerInfoPanel.w-1,game._gui.playerInfoPanel.y+game._gui.playerInfoPanel.h-1) and game._data.windowThread == nil then
					CGD[game._player.id]["target"] = game._player.id
				end

				--выбрать цель
				if ev[5] == 0 and not game._data.paused and not clicked(ev[3],ev[4],1,1,mxw,8) then
					target(ev[3],ev[4])
				end

				if not game._data.paused then
					game._gui.playerInfoPanel.action["touch"](ev)
					game._gui.targetInfoPanel.action["touch"](ev)
					game._gui.followerInfo.action["touch"](ev)
					game._gui.qPanel.action["touch"](ev)
				end

			end

			if game._data.windowThread == "pause" then
				game._gui.pauseMenu.action["touch"](ev)
			elseif game._data.windowThread == "inventory" then
				game._function.inventory.action["touch"](ev)
			elseif game._data.windowThread == "dialog" then
				game._gui.NPCDialog.action["touch"](ev)
			elseif game._data.windowThread == "quests" then
				game._gui.questsList.action["touch"](ev)
			elseif game._data.windowThread == "console" then
				game._function.gameConsole.action["touch"](ev)
			elseif game._data.windowThread == "pstats" then
				game._gui.playerStats.action["touch"](ev)
			elseif game._data.windowThread == "tradewindow" then
				game._function.tradew.action["touch"](ev)
			elseif game._data.windowThread == "craftwindow" then
				game._function.craftw.action["touch"](ev)
			elseif game._data.windowThread == "game._function.ydw" then
				game._function.ydw.action["touch"](ev)
			elseif game._data.windowThread == "skillsWindow" then
				game._gui.playerSkills.action["touch"](ev)
			elseif game._data.windowThread == "menu" then
				game._gui.mainMenu.action["touch"](ev)
			elseif game._data.windowThread == "rewardChoice" then
				game._gui.rewardChoice.action["touch"](ev)
			end
		end
		if ev[1] == "scroll" then
			if game._data.windowThread == "console" then
				game._function.gameConsole.action["scroll"](ev)
			end
		end
	end
end


thread.init()					-- Инициализация корутина
buffer.setResolution(mxw, mxh)	-- Инициализация буфера

startScreen()					-- Чёрный экран с лого
game._function.initResources()			-- Инициализация данных

-- Начальное меню
game._gui.mainMenu.open(0)

-- Создание корутин
thread.create(main)
thread.create(screen)
thread.create(functionPS)
--thread.create(funcP4)
thread.create(funcP10)

thread.waitForAll()				-- Запуск корутин

--[[ Эта строка недостижима, пока корутины работают ]]--
gpu.setBackground(0x000000)
gpu.setForeground(0xffffff)
term.clear()
term.setCursor(1,1)
io.write("Wirthe16 — Onslaught of the wraiths "..game._function.getVersion())
