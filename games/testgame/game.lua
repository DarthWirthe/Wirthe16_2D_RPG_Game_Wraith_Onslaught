local term =      require "term"
local event =     require "event"
local image =     require "G_image"
local thread =    require "G_thread"
local unicode =   require "unicode"
local computer =  require "computer"
local keyboard =  require "keyboard"
local fs =        require "filesystem"
local ser = 	  require "serialization"
local buffer =    require "G_doubleBuffering"
local component = require "component"
local gpu =       component.gpu
local tableInsert, tableRemove, mathFloor, mathCeil, mathMin, mathMax = table.insert, table.remove, math.floor, math.ceil, math.min, math.max
local mxw, mxh = gpu.maxResolution()

local pScreenText = "(C) 2016-2018 Wirthe16"
local cScreenStat = "Загрузка..."
local preduprejdenie = ""
local vseNormalno = true
local dir = "/games/testgame/"
local logFile = "log.txt"
local debugMode = false
local paused = false
local cWindowTrd = nil
local showTargetInfo = false
local stopDrawing = false
local ingame = true
local cDialog = nil
local startBckgColour = 0x222222
local cp = {white = 0xffffff, blue = 0x3392ff, magenta = 0x996dbf, golden = 0xffff00, orange = 0xffb420, green = 0xff9200}
local cGlobalx, cBackgroundPos = 1, 1
local pSprPicPos = 75
local cTarget = 0
local targetQuest = 0
local pckTarget = 0
local pickingUp = false
local maxPckTime = 0
local pckTime = 0
local pmov = 0
local cItemRange = 200
local pID = 1
local bufferenv
local vAttackDistance
thread.init()
buffer.setResolution(mxw, mxh)

buffer.draw(true)

local gfunc = {}

gfunc.usepmx = false

gfunc.version = {1,2,7,6}

local gamefps, cfps, usram = 0, 0

local ank, lec, sle = 25, 1, 0.001

local limg = image.load(dir.."image/slg.pic")

local dopInfo = {
"Разрешение экрана только 160х50",
"DoubleBuffering lib — автор IgorTimofeev",
"Image lib, Сolor lib — автор IgorTimofeev",
"Thread lib — автор Zer0Galaxy",
}

function dopInfo.print()
 for f = 1, #dopInfo do
 buffer.text(2,48-#dopInfo+f,0xA7A7A7,dopInfo[f])
 end
end

for f = 1, ank do
buffer.square(1,1,160,50,startBckgColour)
buffer.text(2,2,0xA7A7A7,cScreenStat)
ank, lec = 80-mathFloor(limg.width/2),25-mathFloor(limg.height/2)
if f == 19 then ank = ank - 1; lec = lec + 1 end
if f == 24 then ank = ank + 1; lec = lec - 1 end
buffer.image(ank, lec, limg)
dopInfo.print()
buffer.draw()
os.sleep(sle)
end

ank, lec, sle, limg = nil

limg = mathCeil(computer.totalMemory()/1048576*10)/10

if mxw < 160 or mxh < 50 then 
vseNormalno = false 
preduprejdenie = 'Текущее разрешение экрана не соответствует требуемому.'
end

if limg > 0 and limg < 1.8 then
vseNormalno = false 
preduprejdenie = preduprejdenie..' оперативной памяти ('..limg..' МБ) недостаточно для нормальной работы программы.'
end

function gfunc.RAMInfo()
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

function gfunc.getVersion()
return "Версия "..gfunc.version[1].."."..gfunc.version[2].."."..gfunc.version[3].." Обновление "..gfunc.version[4]
end

local function writeLineToFile(path,strLine)
local file = io.open(path, 'a')
file:write(( strLine or "" ).."\n")
file:close()
end

function gfunc.logtxt(text)
writeLineToFile(dir..logFile,text)
end

local primaryError = _G.error

-- подмена функции ошибки
_G.error = function(text)
ingame = false
thread.killAll()
local file = io.open(dir..logFile, 'a')
file:write(( text or "" ).."\n")
file:close()
os.sleep(0.5)
gpu.setBackground(0x222222)
gpu.setForeground(0xffffff)
term.clear()
term.setCursor(1,2)
io.write("Текст ошибки сохранён в файл log.txt\n")
io.write("Ошибка:\n")
io.write(text.."\n")
_G.error = primaryError
primaryError = nil
gpu.setForeground(0xffffff)
print("Для продолжения нажмите любую клавишу...")
 while true do
 local ev = table.pack(event.pull())
  if ev[1] == "key_down" then
  computer.shutdown(true)
  break
  end
 end
end

function gfunc.dofile(path)
local file = io.open(path)
local h = file:read("*all")
file:close()
load(h)()
end

-- не функционирует
function gfunc.doScript(file)
local path = dir.."lua/"..file
 if fs.exists(path) then
 local success, err = pcall(gfunc.dofile,path)
 if not success then gfunc.logtxt("Ошибка "..path..": "..err) end
 else
 gfunc.logtxt("Не существует "..path)
 end
end

function gfunc.assert(...)
local result = true
local args = table.pack(...)
 for f = 1, #args / 2, 2 do
  if type(args[f-1]) ~= args[f] then
  result = false
  gfunc.logtxt(text)
  end
 end
return result
end

local loadedItemIcons = readFromFile(dir.."data/itempic.data")

local gud, gid, gqd, gsd, eusd, ged, baseWtype, lootdata = dofile(dir.."data/elements.data")

local world = dofile(dir.."data/levels.data")
world.current = 1
for f = 1, #world do
world[f].draw = load("local buffer=require('G_doubleBuffering');return function() "..world[f].draw.." end")()
end

-- gud = Различные объекты (нпс,порталы,монстры и т.д.) / массив
--[[ 
id: номер объекта.
name: имя объекта.
dtype: = 1 - физ. 2 - маг.
wtype: тип объекта. Отображается у НПС.
rtype: roletype, роль объекта: 'p' - игрок; 'f' - НПС; 'e' - объект, который можно атаковать; 
'r' - объект, который можно собрать, 'c' - телепорт.
loot: 'coins' - деньги; 'exp' - опыт; 'items' - список предметов; 'drop' - дополнительный лут.
lvl: уровень объекта.
image: привязанный спрайт.
skill: список умений.
vresp: время воскрешения, сек.
atds: дальность атаки.
quests: привязанный список заданий.
dialog: массив диалога из файла /data/dialogs.data.
agr: если true и rtype = 'e', то игрок будет атакован этим объектом.
nres: если false, то не может воскрешаться.
cmve: если true, то не может двигаться.
daft_klz: если = 'np', то спавнит портал в ближайшее поселение; 
если = 'sp', то спавнит объект с id, равным второму аргументу.
mhp: устанавливает максимальное значение здоровья.
hpmul: множитель максимального значения здоровья.
tlp: координаты телепортации (только если rtype = 'c')
]]--

for f = 1, #gud do
if gud[f]["name"] == "" then gud[f]["name"] = "Без названия" end
 if gud[f]["loot"] and not gud[f]["loot"]["exp"] then
 gud[f]["loot"]["exp"] = gud[f]["lvl"] * 5
 end
os.sleep()
end

-- gid = Различные предметы / массив

gfunc.watds = {[1]=10,[2]=12,[3]=10}
local weaponHitRate = {[1]=0.9,[2]=1,[3]=1.2}
local armorPhysicalDefenceMultiple, armorMagicalDefenceMultiple = {
["pendant"]=19.5,["ring"]=21.3,["robe"]=30.6, -- общее
["helmet"]=38.2,["armor"]=40.4,["pants"]=38.7,["footwear"]=37.3, -- фз
},{
["pendant"]=27.5,["ring"]=24.7,["robe"]=32.8, -- общее
["helmet"]=15.4,["armor"]=26.3,["pants"]=23.8,["footwear"]=11.5, -- мг
}
local nmlt = 1

for f = 1, #gid do
if gid[f]["props"] and type(gid[f]["props"]) == "table" and gid[f]["props"]["dds"] then gid[f]["name"] = string.rep("♦",#gid[f]["props"]["dds"])..gid[f]["name"] end
 if gid[f]["name"] == "" then gid[f]["name"] = "Без названия" end
 if gid[f]["type"] == "armors" then
  gid[f]["stackable"] = false
  if gid[f]["nmlt"] then nmlt = tonumber(gid[f]["nmlt"]) end
  if gid[f]["props"]["pdef"] == nil then
  gid[f]["props"]["pdef"] = mathCeil(9+gid[f]["lvl"]*armorPhysicalDefenceMultiple[gid[f]["subtype"]]*nmlt*mathMax((gid[f]["lvl"]^1.2/4),1))
  end
  if gid[f]["props"]["mdef"] == nil then
  gid[f]["props"]["mdef"] = mathCeil(9+gid[f]["lvl"]*armorMagicalDefenceMultiple[gid[f]["subtype"]]*nmlt*mathMax((gid[f]["lvl"]^1.2/4),1))
  end
 end
 if gid[f]["type"] == "weapon" then
 gid[f]["stackable"] = false
 end
nmlt = 1
os.sleep()
end

nmlt = nil

local mItemDataNum = #gid

-- gqd = база заданий / массив
--[[ 
descr-описание; gtext-текст в диалоге; atext-положительный ответ; rtext-отриц. ответ   
]]--

for f = 1, #gqd do
gqd[f]["qstgve"] = nil
gqd[f]["comp"] = 0
end

local cPlayerSkills = {
{1,0,1},{2,0,1},{3,0,1},{4,0,1},{5,0,0},{6,0,0},{7,0,0},{8,0,0},{9,0,0},{10,0,0}
}

local cUskills = {1,2,3,4,0,0}

local imageBuffer = {} -- буффер для изображений, чтобы не грузить процессор и диск | с версии 1.2.1

local iconImageBuffer = {} -- буффер для иконок предметов | с версии 1.2.1

local CGD = {} -- массив со всеми персонажами

local cUquests = {} -- структура -- [1] (и т.д.) = {1(id),0(прогресс),false(не выполнено/выполнено)} 

local function clicked(x,y,x1,y1,x2,y2)
 if x >= x1 and x <= x2 and y >= y1 and y <= y2 then 
 return true 
 end   
 return false
end

function gfunc.random(n1,n2,accuracy)
local ass = 10^(accuracy or 0)
return gfunc.roundupnum(math.random(n1*ass,n2*ass))/ass
end

function gfunc.getBrailleChar(n1, n1, n3, n4, n5, n6, n7, n8)
return unicode.char(10240+128*n8+64*n7+32*n6+16*n4+8*n1+4*n5+2*n3+n1)
end

function gfunc.unicodeframe(x,y,w,h,c)
buffer.text(x,y,c,"┌")
buffer.text(x+1,y,c,string.rep("─",w-2))
buffer.text(x+w-1,y,c,"┐")
 for f = 1, h-2 do
 buffer.text(x,y+f,c,"│")
 buffer.text(x+w-1,y+f,c,"│")
 end
buffer.text(x,y+h-1,c,"└")
buffer.text(x+1,y+h-1,c,string.rep("─",w-2))
buffer.text(x+w-1,y+h-1,c,"┘")
end

function gfunc.scolorText(x,y,col,str)
local dsymb = "^"
local pcl, cs, f, s = col, "", 1, 1
 while f <= unicode.len(str) do
 cs = unicode.sub(str,f,f)
  if cs ~= dsymb then
  buffer.text(x-1+s,y,pcl,cs)
  f = f + 1
  s = s + 1
  elseif cs == dsymb then
   if unicode.sub(str,f+1,f+6) == "native" then
   pcl = col
   else
   pcl = tonumber("0x"..unicode.sub(str,f+1,f+6))
   end
  f = f + 7
  end
 end
end

function gfunc.textWrap(text, limit) -- угадайте откуда взял
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

function gfunc.getDistance(from,x,y)
local x1, y1 = CGD[from]["x"], CGD[from]["y"]
	if x1 + CGD[from]["width"] < x then
	x1 = x1 + CGD[from]["width"]
	end
	return mathFloor(math.sqrt((x1-x)^2+(y1-( y or 1))^2)*10)/10
end

function gfunc.getDistanceToId(from,to)
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
cWindowTrd = "screen_save"
old_cgx, old_cbpos = cGlobalx, cBackgroundPos
sScreenTimerw = true
sScreenTimer1 = time
sScreenXValue = x
end

local function setScreenPosition(x)
local ncGlobalx, ncBackgroundPos = cGlobalx, cBackgroundPos
cGlobalx = x
cBackgroundPos = x
pSprPicPos = 75-gfunc.getDistance(1,x)
end

local function setScreenNormalPosition(ncGlobalx, ncBackgroundPos)
pSprPicPos = 75
cGlobalx, cBackgroundPos = ncGlobalx, ncBackgroundPos
sScreenTimerw = false
cWindowTrd = nil
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

local function movetoward(id, x, distanceLimit, step)
 if gfunc.getDistance(id,x) < distanceLimit and x < CGD[id]["x"] then
 CGD[id]["x"] = CGD[id]["x"] - step
 CGD[id]["spos"] = "l"
 elseif gfunc.getDistance(id,x) < distanceLimit and x > CGD[id]["x"] then
 CGD[id]["x"] = CGD[id]["x"] + step
 CGD[id]["spos"] = "r"
 end
end

function gfunc.playerAutoMove(x, distanceLimit, step)
local kx
 if gfunc.getDistance(pID,x) >= step and gfunc.getDistance(pID,x) < distanceLimit and x < CGD[pID]["x"] then
 CGD[pID]["spos"] = "l" 
 pmov = -step
 elseif gfunc.getDistance(pID,x) >= step and gfunc.getDistance(pID,x) < distanceLimit and x > CGD[pID]["x"] then
 CGD[pID]["spos"] = "r"
 pmov = step
 elseif gfunc.getDistance(pID,x) < step then
 pmov = 0
 gfunc.usepmx = false
 CGD[pID]["x"] = x
 CGD[pID]["mx"] = x
 cGlobalx = x
 cBackgroundPos = x
 CGD[pID]["image"] = 0
 end
end

function gfunc.roundupnum(num)
local res
 if num - mathFloor(num) < 0.5 then
 res = mathFloor(num)
 else
 res = mathCeil(num)
 end
return res
end

function gfunc.getPlayerAtdsBySkill(skill)
return ( vAttackDistance or 8 ) + gsd[cPlayerSkills[cUskills[skill]][1]]["distance"]
end

local function insertQuests(id,dialog)
local var, povar
local newDialog = dialog
local cQue = gud[CGD[id]["id"]]["quests"]
local insQuestDialog = true 
 if type(cQue) == "table" and cDialog["im"] ~= nil then
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
   for q = 1, #cUquests do
    if cUquests[q][1] == cQue[f] and cUquests[q][3] then
     if CGD[pID]["lvl"] < gqd[cQue[f]]["minlvl"] or gqd[cQue[f]]["comp"] or not gqd[cQue[f]]["comp"] then
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
  for f = 1, #cUquests do
   if cUquests[f][3] and CGD[cTarget]["id"] == gqd[cUquests[f][1]]["qr"] and newDialog[1]["dq"]~=nil then
   newDialog[1]["do"][#newDialog[1]["do"]+1] = {["text"]=gqd[cUquests[f][1]]["name"],["action"]="cmpquest",["do"]=cUquests[f][1]}
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

local sMSG1, smsg1time = {"",""}, 0

function gfunc.textmsg1(msg)
tableInsert(sMSG1,msg)
smsg1time = 8
end

local sMSG2, smsg2time = {""}, 0

function gfunc.textmsg2(msg)
tableInsert(sMSG2,msg)
smsg2time = 5
end

local sMSG3 = ""

function gfunc.textmsg3(msg)
sMSG3 = msg
end

local sMSG4, smsg4time = {"","",""}, 0

function gfunc.textmsg4(msg)
tableInsert(sMSG4,msg)
if #sMSG4 > 3 then tableRemove(sMSG4,1) end
smsg4time = 5
end

local sMSG5, smsg5time = {}, 0

function gfunc.textmsg5(msg)
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

gfunc.console={}
function gfunc.console.debug(...)
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

function gfunc.console.wError(e)
if type(e) == "string" then tableInsert(consoleArray,"!/"..e) end
end

-- функция чтобы поставить параметры мобов по умолчанию
function gfunc.unitRV(f)
 -- физдеф
CGD[f]["pdef"] = gud[CGD[f]["id"]]["pdef_con"] or 0
 -- магдеф
 CGD[f]["mdef"] = gud[CGD[f]["id"]]["mdef_con"] or 0
 -- физ атака
if gud[CGD[f]["id"]]["ptk_con"] then
CGD[f]["ptk"] = gud[CGD[f]["id"]]["ptk_con"]
else
CGD[f]["ptk"] = {0,0}
end
 -- маг атака
if gud[CGD[f]["id"]]["mtk_con"] then
CGD[f]["mtk"] = gud[CGD[f]["id"]]["mtk_con"]
else
CGD[f]["mtk"] = {0,0}
end
 -- макс жс
CGD[f]["mhp"] = gud[CGD[f]["id"]]["mhp_con"] or 0
end

function gfunc.addUnit(id,x,y)
CGD[#CGD+1] = {}
local new, cUSprite = #CGD
CGD[new]["sx"] = x
CGD[new]["mx"] = x
CGD[new]["x"] = x
CGD[new]["y"] = y
CGD[new]["id"] = gud[id]["id"]
CGD[new]["lvl"] = gud[id]["lvl"]
CGD[new]["spos"] = "r"
CGD[new]["image"] = 0
 if CGD[new]["image"] ~= nil then
 cUSprite = image.load(dir.."sprpic/"..gud[id]["image"]..".pic")
 CGD[new]["width"] = cUSprite.width
 CGD[new]["height"] = cUSprite.height
 end
 cUSprite = nil
CGD[new]["pdef"] = 0
CGD[new]["mdef"] = 0
CGD[new]["resptime"] = 0
CGD[new]["living"] = true
CGD[new]["cmove"] = true
CGD[new]["ctck"] = true
CGD[new]["rtype"] = gud[id]["rtype"]
CGD[new]["attPlayer"] = false
CGD[new]["tlinfo"] = {}
 if gud[id]["rtype"] == "f" then 
 CGD[new]["dialog"] = gud[id]["dialog"]
 end
CGD[new]["effects"] = {}
 -- консты
 if id ~= 1 and gud[CGD[new]["id"]]["rtype"] == "e" then
 local pmul, mmul 
 local idd = CGD[new]["id"]
 if not gud[idd]["dtype"] then
 pmul, mmul = 1, 1
 elseif gud[idd]["dtype"] == 1 then
 pmul, mmul = 1+0.01*(50/math.sqrt(gud[idd]["lvl"])), 1-0.01*(50/math.sqrt(gud[idd]["lvl"]))
 elseif gud[idd]["dtype"] == 2 then
 pmul, mmul = 1-0.01*(50/math.sqrt(gud[idd]["lvl"])), 1+0.01*(50/math.sqrt(gud[idd]["lvl"]))
 end
 -- физдеф
 if not gud[idd]["pdef"] then 
 gud[idd]["pdef_con"] = mathCeil((gud[idd]["lvl"]*19.84+(gud[idd]["lvl"]^2/1.5))*pmul)
 else gud[idd]["pdef_con"] = gud[idd]["pdef"] end
 -- магдеф
 if not gud[idd]["mdef"] then 
 gud[idd]["mdef_con"] = mathCeil((gud[idd]["lvl"]*18.31+(gud[idd]["lvl"]^2/1.5))*mmul) 
 else gud[idd]["mdef_con"] = gud[idd]["mdef"] end
 -- физ атака
 if not gud[idd]["ptk"] then gud[idd]["ptk_con"] = {
 mathCeil((1+gud[idd]["lvl"]^1.13)*pmul),
 mathCeil((3+gud[idd]["lvl"]^1.24)*pmul)
 }
 else gud[idd]["ptk_con"] = gud[idd]["ptk"] end
 -- маг атака
 if not gud[idd]["mtk"] then gud[idd]["mtk_con"] = {
 mathCeil((1+gud[idd]["lvl"]^1.23)*mmul),
 mathCeil((3+gud[idd]["lvl"]^1.34)*mmul)
 }
 else gud[idd]["mtk_con"] = gud[idd]["mtk"] end
 -- макс жс
 if not gud[idd]["mhp"] then
 gud[idd]["mhp_con"] = mathCeil(36+(gud[idd]["lvl"]-1)*36.3+((gud[idd]["lvl"]-1)^2-1)/2)
 else
 gud[idd]["mhp_con"] = gud[idd]["mhp"]
 end
 if gud[idd]["hpmul"] then
 gud[idd]["mhp_con"] = mathCeil(gud[idd]["mhp_con"] * gud[idd]["hpmul"])
 end
 end
gfunc.unitRV(new)
CGD[new]["chp"] = CGD[new]["mhp"]
gfunc.console.debug("Добавление","id:"..tostring(gud[id]["id"]),"имя:"..gud[id]["name"],"x:"..tostring(x),"y:"..tostring(y),"Gid:"..#CGD)
return new
end

gfunc.console.wError(preduprejdenie)

gfunc.console.debug("Загрузка ("..unicode.sub(os.date(), 1, -4)..")")

-- инвентарь полный / не полный
function gfunc.checkInventoryisFull()
local full = true
 for f = 1, #CGD[pID]["inventory"]["bag"] do
 if CGD[pID]["inventory"]["bag"][f][2] == 0 then full = false end
 end
return full
end


-- место в инвентаре, 0 = полный
function gfunc.checkInventorySpace()
local space = 0
 for f = 1, #CGD[pID]["inventory"]["bag"] do
 if CGD[pID]["inventory"]["bag"][f][1] == 0 then space = space + 1 end
 end
return space
end

local lostItem

local function addItem(itemid,num)
local vparInvEx = 0
local r = 0
 -- удалить ошибочные значения
 for f = 1, #CGD[pID]["inventory"]["bag"] do
  if CGD[pID]["inventory"]["bag"][f][2] == 0 then
  CGD[pID]["inventory"]["bag"][f][1] = 0
  if CGD[pID]["inventory"]["bag"][f][1] >= cItemRange then gid[CGD[pID]["inventory"]["bag"][f][1]] = nil end
  iconImageBuffer[f] = nil
  end
 end
 -- добавить нестакающийся предмет
 if gid[itemid] and not gid[itemid]["stackable"] then
  for f = 1, #CGD[pID]["inventory"]["bag"] do
   if CGD[pID]["inventory"]["bag"][f][1] == 0 then 
   vparInvEx = 1
   CGD[pID]["inventory"]["bag"][f][1] = itemid
   CGD[pID]["inventory"]["bag"][f][2] = num
    if cWindowTrd == "inventory" then
	iconImageBuffer[f] = image.load(dir.."itempic/"..loadedItemIcons[gid[CGD[pID]["inventory"]["bag"][f][1]]["icon"]]..".pic")
    end
   r = f
   break 
   end
  end
 end
 -- добавить стакающийся предмет
 if gid[itemid] and gid[itemid]["stackable"] and vparInvEx == 0 then
  for i = 1, #CGD[pID]["inventory"]["bag"] do
   -- сгруппировать одинаковые
   if CGD[pID]["inventory"]["bag"][i][1] == itemid then
   CGD[pID]["inventory"]["bag"][i][2] = CGD[pID]["inventory"]["bag"][i][2] + num
   vparInvEx = 1
   r = i
   break
   end
  end
  if vparInvEx == 0 then
   for i = 1, #CGD[pID]["inventory"]["bag"] do
    if CGD[pID]["inventory"]["bag"][i][1] == 0 or CGD[pID]["inventory"]["bag"][i][2] == 0 then
	CGD[pID]["inventory"]["bag"][i][1] = itemid
	CGD[pID]["inventory"]["bag"][i][2] = num
	vparInvEx = 1
    if cWindowTrd == "inventory" then
	iconImageBuffer[i] = image.load(dir.."itempic/"..loadedItemIcons[gid[CGD[pID]["inventory"]["bag"][i][1]]["icon"]]..".pic")
    end	
	r = i
	break
	end
   end
  end
 end
 if vparInvEx == 0 and gfunc.checkInventoryisFull() then
 lostItem = {itemid,num}
 gfunc.console.debug("Инвентарь переполнен")
 gfunc.textmsg1("Инвентарь переполнен!")
 end
 for f = 1, #CGD[pID]["inventory"]["bag"] do
  if CGD[pID]["inventory"]["bag"][f][1] ~= 0 and gid[CGD[pID]["inventory"]["bag"][f][1]] and not gid[CGD[pID]["inventory"]["bag"][f][1]]["stackable"] and CGD[pID]["inventory"]["bag"][f][2] > 1 then
  CGD[pID]["inventory"]["bag"][f][2] = 1
  end
 end
return r
end

local function getRandSeq(massiv) -- эта функция перемешивает значения массива (велосипед из костылей)
local new = {}
 for e = 1, #massiv do
 new[e] = "§"
 end
 for f = 1, #massiv do
 tableInsert(new,gfunc.random(1,#massiv),massiv[f])
 end
 for e = 1, #new do if new[#new-e+1] == "§" then tableRemove(new,#new-e+1) end end
return new
end
 
local function createNewItem(itemID)
local newItemID, hu = -1, 0
 while true do
 if not gid[cItemRange+hu] then newItemID = cItemRange+hu break end
 hu = hu + 1
 end
 if gid[itemID]["type"] == "armors" or gid[itemID]["type"] == "weapon" then
 gid[newItemID] = {}
 local list = {
	"name",
	"lvl",
	"type",
	"subtype",
	"reqlvl",
	"description",
	"stackable",
	"cost",
	"icon",
	"ncolor"
 }
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
		["weapon"] = 10 + level*2, -- %
		["armors"] = 80 + level*2 -- %
		},
	[2]={"sur+",
		["min"] = mathCeil(level/2),
		["max"] = level,
		["weapon"] = 40 + level*2,
		["armors"] = 50 + level*2
		},
	[3]={"str+",
		["min"] = mathCeil(level/2),
		["max"] = level,
		["weapon"] = 40 + level*2,
		["armors"] = 50 + level*2
		},
	[4]={"int+",
		["min"] = mathCeil(level/2),
		["max"] = level,
		["weapon"] = 40  + level*2,
		["armors"] = 50 + level*2
		},
	[5]={"pdm+",
		["min"] = 2+level*6+(level-3),
		["max"] = 2+level^1.2*8+(level-3),
		["weapon"] = 60 + level*2,
		["armors"] = 0,
		["sub"] = {1,2,3}
		},
	[6]={"mdm+",
		["min"] = 2+level*6+(level-3),
		["max"] = 2+level^1.2*8+(level-3),
		["weapon"] = 60 + level*2,
		["armors"] = 0,
		["sub"] = {"magical"}
		},
	[7]={"pdf+",
		["min"] = 5+(level-1)^2*3,
		["max"] = 5+(level-1)^2*5,
		["weapon"] = 0,
		["armors"] = 30 + level*2
		},
	[8]={"mdf+",
		["min"] = 5+(level-1)^2*3,
		["max"] = 5+(level-1)^2*5,
		["weapon"] = 0,
		["armors"] = 30 + level*2
		},
	[9]={"mp+",
		["min"] = 4+level^2,
		["max"] = 5+level^2*2,
		["weapon"] = 2 + level*2, -- %
		["armors"] = 20 + level*2 -- %
		},
	[10]={"chc+",
		["min"] = 1,
		["max"] = 2,
		["weapon"] = 10,
		["armors"] = 5
		},
	[11]={"hp%",
		["min"] = 5,
		["max"] = 5,
		["weapon"] = 0, -- %
		["armors"] = level-1 -- %
		},
	[12]={"mp%",
		["min"] = 5,
		["max"] = 5,
		["weapon"] = 0, -- %
		["armors"] = level-1 -- %
		},
	[13]={"hp%",
		["min"] = 10,
		["max"] = 10,
		["weapon"] = 0, -- %
		["armors"] = mathMax(level-2,0) -- %
		},
	[14]={"mp%",
		["min"] = 10,
		["max"] = 10,
		["weapon"] = 0, -- %
		["armors"] = mathMax(level-2,0) -- %
		},
	}
 local ddch, adnum, newDds, cccc, dt, value = {100,45,7.5,1,0.15}, 1, {}
 for f = 1, 5 do
  if gfunc.random(1,10^6)/10^4 <= ddch[6-f] then
  adnum = 6-f
  break
  end
 end
  while #newDds < mathMin(adnum,gid[itemID]["lvl"]) do
  cccc = false
   dt = gfunc.random(1,#props)
   if gfunc.random(1,10^5) <= props[dt][gid[itemID]["type"]]*10^3 then
   value = mathFloor(gfunc.random(props[dt]["min"]*10,props[dt]["max"]*10)/10)
	if props[dt]["sub"] then
	 for j = 1, #props[dt]["sub"] do
	  if gid[itemID]["subtype"] == props[dt]["sub"][j] then
	  cccc = true
	  end
	 end
	elseif value >= 1 then
	cccc = true
	end
   if cccc then tableInsert(newDds,{props[dt][1],mathFloor(value)}) end
   end
  end
  
 
  for r = 1, #newDds-1 do
   if gid[newItemID]["type"] == "weapon" and not gid[newItemID]["cchg"] then
    if gid[newItemID]["props"]["phisat"] then
	gid[newItemID]["props"]["phisat"][1] = mathFloor(gid[newItemID]["props"]["phisat"][1]*1.05)
	gid[newItemID]["props"]["phisat"][2] = mathFloor(gid[newItemID]["props"]["phisat"][2]*1.05)
	end
    if gid[newItemID]["props"]["magat"] then
	gid[newItemID]["props"]["magat"][1] = mathFloor(gid[newItemID]["props"]["magat"][1]*1.1)
	gid[newItemID]["props"]["magat"][2] = mathFloor(gid[newItemID]["props"]["magat"][2]*1.1)
	end
   elseif gid[newItemID]["type"] == "armors" and not gid[newItemID]["cchg"] then
    if gid[newItemID]["props"]["pdef"] then gid[newItemID]["props"]["pdef"] = mathFloor(gid[newItemID]["props"]["pdef"]*1.23) end
	if gid[newItemID]["props"]["mdef"] then gid[newItemID]["props"]["mdef"] = mathFloor(gid[newItemID]["props"]["mdef"]*1.23) end
   end
  end
  if gid[itemID]["ncolor"] == 0xffffff then
   if #newDds > 0 and #newDds < 3 then gid[newItemID]["ncolor"] = cp.blue
   elseif #newDds == 3 then gid[newItemID]["ncolor"] = cp.magenta
   elseif #newDds == 4 then gid[newItemID]["ncolor"] = cp.orange
   elseif #newDds >= 5 then gid[newItemID]["ncolor"] = cp.green
   end 
  end
 gid[newItemID]["props"]["dds"] = newDds
 gid[newItemID]["name"] = string.rep("♦",mathMin(#gid[newItemID]["props"]["dds"],5))..gid[newItemID]["name"]
 gid[newItemID]["cost"] = gid[itemID]["cost"]+mathCeil(gid[itemID]["cost"]/2*mathMin(#gid[newItemID]["props"]["dds"],5))
 gid[newItemID]["oid"] = itemID
 gid[newItemID]["id"] = newItemID
  if #newDds <= 0 or gid[itemID]["cchg"] then
  gid[newItemID] = nil
  return itemID
  else
  mItemDataNum = newItemID
  end
 else
 return itemID
 end
return newItemID
end

function gfunc.addUnitEffect(uID,eID,lvl)
local addne = true 
 if uID ~= nil and eID ~= nil and lvl ~= nil and eID >= 1 and eID <= #ged then
  for eff = 1, #CGD[uID]["effects"] do
   if CGD[uID]["effects"][eff][1] == eID then
   CGD[uID]["effects"][eff][2] = ged[eID]["dur"][lvl]
   addne = false
   break
   end
  end
 if addne then tableInsert(CGD[uID]["effects"],{eID,ged[eID]["dur"][lvl],lvl}) end
 else
 gfunc.console.wError('addUnitEffect: ошибка unitID, effID или lvl')
 end
end

local function inserttunitinfo(u,text)
tableInsert(CGD[u]["tlinfo"],text)
end

local function checkItemInBag(itemid)
local d = 0
 for f = 1, #CGD[pID]["inventory"]["bag"] do
  if CGD[pID]["inventory"]["bag"][f][1] == itemid then 
  d = d + CGD[pID]["inventory"]["bag"][f][2]
  end
 end
return d, itemid
end

function gfunc.setAllValuesInArrayTo(tabli,value)
local t = {}
 for k, v in pairs(tabli) do
 t[k] = value
 end
return t
end

local vaddsPnts = {vSur=0,vStr=0,vInt=0,vPdm=0,vMdm=0}

local weaponTypes = {"sword","spear","axe","magical"}

local witypes = {
	"helmet",
	"pendant",
	"armor",
	"pants",
	"footwear",
	"robe",
	"ring",
	"weapon"
}

local gitypes = {
	["headwear"]={"helmet","arcane headgear"},
	["necklace"]={"pendant"},
	["shirt"]={"armor","arcane robe"},
	["pants"]={"pants","arcane pants"},
	["footwear"]={"footwear","arcane footwear"},
	["manteau"]={"robe"},
	["ring"]={"ring","magic ring"},
	["weapon"]={"sword","spear","axe"},
}

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

function gfunc.getWItemType(subtype)
 for k, v in pairs(gitypes) do
  for f = 1, #v do
   if gitypes[k][f] == subtype then
   return k
   end
  end
 end
return ""
end

function gfunc.getWItemTypeName(subtype)
return gitypesNames[subtype] or ""
end

local v = {
["sur+"]=0,["str+"]=0,["int+"]=0,
["hp+"]=0,["mp+"]=0,["vPdm1"]=0,
["pdm+"]=0,["mdm+"]=0,["vMdm1"]=0,
["vPdm2"]=0,["vMdm2"]=0,["pdf+"]=0,
["mdf+"]=0,["chc+"]=0,["hp%"]=0,
["mp%"]=0,["pwd%"]=0,["mwd%"]=0}

function gfunc.playerRV()
v = gfunc.setAllValuesInArrayTo(v,0)
local buben, crit
 for f = 1, #witypes do
  if CGD[pID]["inventory"]["weared"][witypes[f]] ~= 0 and gid[CGD[pID]["inventory"]["weared"][witypes[f]]]["props"]["dds"] then
  buben = gid[CGD[pID]["inventory"]["weared"][witypes[f]]]["props"]["dds"]
   for e = 1, #buben do
   v[buben[e][1]] = v[buben[e][1]] + buben[e][2]
   end  
  end
  if CGD[pID]["inventory"]["weared"][witypes[f]] ~= 0 and gid[CGD[pID]["inventory"]["weared"][witypes[f]]]["type"] == "armors" then
  v["pdf+"] = v["pdf+"] + gid[CGD[pID]["inventory"]["weared"][witypes[f]]]["props"]["pdef"]
  v["mdf+"] = v["mdf+"] + gid[CGD[pID]["inventory"]["weared"][witypes[f]]]["props"]["mdef"] 
  end
 end
----
local wtp, slvl
 for f = 1, #cPlayerSkills do
 slvl = cPlayerSkills[f][3]
  if gsd[cPlayerSkills[f][1]]["type"] == "passive" and gsd[cPlayerSkills[f][1]]["action"].weaponreq then
   for w = 1, #gsd[cPlayerSkills[f][1]]["action"].weaponreq do
    if CGD[pID]["inventory"]["weared"]["weapon"] ~= 0 and gid[CGD[pID]["inventory"]["weared"]["weapon"]]["subtype"] == gsd[cPlayerSkills[f][1]]["action"].weaponreq then
	wtp = true
	end
   end
  else
  wtp = true
  end
  
  if slvl > 0 and gsd[cPlayerSkills[f][1]]["type"] == "passive" and v[gsd[cPlayerSkills[f][1]]["action"].etype] ~= nil and wtp then
  v[gsd[cPlayerSkills[f][1]]["action"].etype] = v[gsd[cPlayerSkills[f][1]]["action"].etype] + gsd[cPlayerSkills[f][1]]["value"][slvl]
  end
 end
 ----
 crit = 1 + mathFloor( (CGD[pID]["strength"]+v["str+"]) / 10)
 crit = crit + mathFloor( (CGD[pID]["intelligence"]+v["int+"]) / 10)
 v["vPdm1"], v["vPdm2"], v["vMdm1"], v["vMdm2"] = v["vPdm1"]+v["pdm+"], v["vPdm2"]+v["pdm+"], v["vMdm1"]+v["mdm+"], v["vMdm2"]+v["mdm+"]
 if CGD[pID]["inventory"]["weared"]["weapon"] > 0 then
  if gid[CGD[pID]["inventory"]["weared"]["weapon"]]["props"]["phisat"] then
  v["vPdm1"] = v["vPdm1"] + gid[CGD[pID]["inventory"]["weared"]["weapon"]]["props"]["phisat"][1]*(1+v["pwd%"]*0.01)
  v["vPdm2"] = v["vPdm2"] + gid[CGD[pID]["inventory"]["weared"]["weapon"]]["props"]["phisat"][2]*(1+v["pwd%"]*0.01)
  end
  if gid[CGD[pID]["inventory"]["weared"]["weapon"]]["props"]["magat"] then
  v["vMdm1"] = v["vMdm1"] + gid[CGD[pID]["inventory"]["weared"]["weapon"]]["props"]["magat"][1]*(1+v["mwd%"]*0.01)
  v["vMdm2"] = v["vMdm2"] + gid[CGD[pID]["inventory"]["weared"]["weapon"]]["props"]["magat"][2]*(1+v["mwd%"]*0.01)
 end
 v.vAtds = gfunc.watds[gid[CGD[pID]["inventory"]["weared"]["weapon"]]["subtype"]]
 gsd[1]["reloading"] = weaponHitRate[gid[CGD[pID]["inventory"]["weared"]["weapon"]]["subtype"]] or 1
 end
vaddsPnts.vSur, vaddsPnts.vStr, vaddsPnts.vInt, vaddsPnts.vPdm1, vaddsPnts.vMdm1, vaddsPnts.vPdm2, vaddsPnts.vMdm2 = v["sur+"], v["str+"], v["int+"], v["vPdm2"], v["vMdm1"], v["vPdm2"], v["vMdm2"]
CGD[pID]["mhp"] = mathCeil(((45+(CGD[pID]["survivability"]+v["sur+"])*15+(CGD[pID]["lvl"]-1)*28+v["hp+"]))*(1+v["hp%"]/100))
CGD[pID]["mmp"] = mathCeil(((28+(CGD[pID]["intelligence"]+v["int+"])*6+(CGD[pID]["lvl"]-1)*7+v["mp+"]))*(1+v["mp%"]/100))
CGD[pID]["ptk"] = {
mathFloor(1+(1+4*(CGD[pID]["strength"]+v["str+"])/100)*(CGD[pID]["lvl"]+v["vPdm1"])),
mathCeil(1+(1+4*(CGD[pID]["strength"]+v["str+"])/100)*(CGD[pID]["lvl"]+v["vPdm2"]))
}
CGD[pID]["mtk"] = {
mathFloor(1+(1+4*(CGD[pID]["intelligence"]+v["int+"])/100)*(CGD[pID]["lvl"]+v["vMdm1"])),
mathCeil(1+(1+4*(CGD[pID]["intelligence"]+v["int+"])/100)*(CGD[pID]["lvl"]+v["vMdm2"]))
}
CGD[pID]["pdef"] = mathFloor(30+((CGD[pID]["survivability"]+v["sur+"])/2+(CGD[pID]["strength"]+v["str+"])/4)*(CGD[pID]["lvl"]+v["pdf+"]/2))
CGD[pID]["armorpdef"] = v["pdf+"]
CGD[pID]["mdef"] = mathFloor(30+((CGD[pID]["survivability"]+v["sur+"])/2+(CGD[pID]["intelligence"]+v["int+"])/4)*(CGD[pID]["lvl"]+v["mdf+"]/2))
CGD[pID]["armormdef"] = v["mdf+"]
CGD[pID]["cmove"] = true
CGD[pID]["ctck"] = true
CGD[pID]["criticalhc"] = v["chc+"] + crit
vAttackDistance = v.vAtds
end

function gfunc.maxXP()
local reqxp = 0
 for e = 1, CGD[pID]["lvl"] do
  if e <= 15 then
  reqxp = mathFloor(reqxp + reqxp*(2/e) + 50*e^(1/e))
  elseif e > 15 and e < 30 then
  reqxp = mathFloor(reqxp + reqxp*(3/e) + 52*e^(1/e))
  elseif e >= 30 then
  reqxp = mathFloor(reqxp + reqxp*(4/e) + 54*e^(1/e))
  end
 end
CGD[pID]["mxp"] = mathMax(reqxp,1)
end

local function addXP(value)
local xpPlus, limit, i = value or 0, 50, 0
 while i <= limit do
  gfunc.maxXP()
  if xpPlus <= CGD[pID]["mxp"] - CGD[pID]["cxp"] then
  CGD[pID]["cxp"] = CGD[pID]["cxp"] + xpPlus
  break
  else 
  xpPlus = xpPlus - (CGD[pID]["mxp"] - CGD[pID]["cxp"])
  CGD[pID]["cxp"] = 0
  CGD[pID]["levelpoints"] = CGD[pID]["levelpoints"] + 1
  CGD[pID]["lvl"] = CGD[pID]["lvl"] + 1
  gfunc.textmsg1("Получен уровень " .. CGD[pID]["lvl"])
  gfunc.playerRV()
  CGD[pID]["chp"] = CGD[pID]["mhp"]
  CGD[pID]["cmp"] = CGD[pID]["mmp"]
  i = i + 1
  end
 end
 if cWindowTrd == nil and value ~= nil and value > 0 then
 gfunc.textmsg4("Опыт +"..value)
 end
end

local function addCoins(value)
CGD[pID]["cash"] = mathMax(CGD[pID]["cash"] + value, 0)
 if cWindowTrd == nil and value ~= nil and value > 0 then
 gfunc.textmsg4("Монеты +"..value.."("..CGD[pID]["cash"]..")")
 end
end

local function getQuest(quest)
tableInsert(cUquests,{quest,0,false})
 if type(gqd[quest]["targ"]) == "table" then
 cUquests[#cUquests][2] = {}
  for f = 1, #gqd[quest]["targ"] do
  cUquests[#cUquests][2][f] = 0
  end
 end
end

local function dmLoading()
buffer.square(1,1,160,50,startBckgColour)
buffer.text(2,2,0xA7A7A7,cScreenStat)
buffer.text(2,4,0xA7A7A7,world[world.current].name)
buffer.text(158-unicode.len(gfunc.getVersion()),48,0xA1A1A1,gfunc.getVersion())
buffer.text(158-unicode.len(pScreenText),49,0xB1B1B1,pScreenText)
dopInfo.print()
buffer.draw()
 if not vseNormalno then
 buffer.text(2,mathFloor(mxh/2),0xD80000,"Предупреждение:"..preduprejdenie)
 buffer.text(2,mathFloor(mxh/2)+1,0xD80000,"Продолжить загрузку? Y/N")
 buffer.draw()
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
buffer.draw()
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
	imageBuffer[#imageBuffer+1] = image.duplicate(image.load(dir.."sprpic/"..gud[unitID]["image"]..".pic"))
	tableInsert(bufferenv,{gud[unitID]["image"],#imageBuffer})
	return #imageBuffer
	end
end

function gfunc.loadWorld(id,unitList)
stopDrawing = true
paused = true
cWindowTrd = nil
cTarget = 0
cDialog = nil
paused = false
world.current = id
dmLoading()
consoleArray = {"Загрузка уровня id:"..id.." "..world[world.current].name.."..."}
local n = CGD[pID]
CGD = {}
CGD[pID] = n
CGD[pID]["x"], CGD[pID]["mx"], cGlobalx, cBackgroundPos = 1, 1, 1, 1
CGD[pID]["cmove"] = true
CGD[pID]["ctck"] = true
imageBuffer = {[-4]=image.load(dir.."sprpic/player_a1.pic"),[-3]=image.load(dir.."sprpic/player_s1.pic"),[-2]=image.load(dir.."sprpic/player_s2.pic"),[-1]=image.load(dir.."sprpic/player_pck.pic"),[0]=image.load(dir.."sprpic/player.pic")}
bufferenv = {}
local spx, npx = 0, 0
--
gpu.setForeground(0xAAAAAA)
term.setCursor(5,39)
io.write(string.rep("─",150))
term.setCursor(5,41)
io.write(string.rep("─",150))
gpu.setForeground(0xCCCCCC)
local cspawnl = unitList or world[id].spawnList
 for f = 1, #cspawnl do
  spx = cspawnl[f][2]
  -- if f > 1 and #cspawnl[f-1] ~= nil and cspawnl[f-1][4] == "p" then
  -- npx = npx + 45
  -- spx = npx
  -- elseif f > 1 and cspawnl[f-1][4] ~= nil and cspawnl[f-1][6] == "p" then
  -- npx = npx + cspawnl[f-1][4] * cspawnl[f-1][5] - cspawnl[f-1][5]
  -- spx = npx
  -- end
  if gud[cspawnl[f][1]]["nres"] ~= false then
   if cspawnl[f][4] == nil then
   gfunc.addUnit(cspawnl[f][1],spx,cspawnl[f][3])
   CGD[#CGD]["image"] = setImage(cspawnl[f][1])
   else
    for i = 1, cspawnl[f][4] do
    gfunc.addUnit(cspawnl[f][1],spx+i*cspawnl[f][5]-cspawnl[f][5],cspawnl[f][3])
    CGD[#CGD]["image"] = setImage(cspawnl[f][1])
    end 
   end
  os.sleep()
  end
 term.setCursor(5,40) 
  for n = 1,mathFloor(f*150/#cspawnl) do
  io.write("█")
  end
 end
paused = false
stopDrawing = false
gfunc.textmsg2(world[id].name)
end

function gfunc.teleport(x,tworld)
 if tworld and tworld ~= world[world.current] then
 gfunc.loadWorld(tworld)
 end
cGlobalx, cBackgroundPos, CGD[pID]["x"], CGD[pID]["mx"] = x or 1, x or 1, x or 1, x or 1
end

-- Сохранение игры

function gfunc.saveGame(savePath,filename)
 if not fs.exists(savePath) then
 fs.makeDirectory(savePath)
 end
local gd = {}
local qwertyn = 0
 for f = 1, 600 do
 if gid[cItemRange - 1 + f] then tableInsert(gd,gid[cItemRange - 1 + f]) end
 end
CGD[pID]["chp"] = mathFloor(CGD[pID]["chp"])
local f = io.open(savePath.."/"..filename, "w")
f:write("Wirthe16_WO_game_save_file\n")
f:write(ser.serialize(CGD[pID]),"\n") -- игрок
f:write(ser.serialize({world.current}),"\n") -- переменные
f:write(ser.serialize(cPlayerSkills),"\n")
f:write(ser.serialize(cUskills),"\n")
f:write(ser.serialize(gd),"\n") -- предметы из gid
f:write(ser.serialize(cUquests),"\n") -- задания
gd = {}
 for i = 1, #gqd do
  if gqd[i]["comp"] == true then
  tableInsert(gd,i)
  end
 end
f:write(ser.serialize(gd),"\n") -- выполненные/заблокированные задания
gd = {["u"]={},["t"]={}}
 for i = 2, #CGD do
 gd["u"][i-1] = {CGD[i]["id"],CGD[i]["x"],CGD[i]["y"]}
 gd["t"][i-1] = CGD[i]["resptime"]
 end
f:write(ser.serialize(gd),"\n") -- чек побитых монстров
gd = {}
 for i = 1, #gud do
 if gud[i]["nres"] == false then tableInsert(gd,i) end
 end
f:write(ser.serialize(gd)) -- чек нересп. монстров
f:close()
end

-- Загрузка игры

function gfunc.loadGame(savePath,filename)
 if fs.exists(savePath.."/"..filename) then
 paused = true
 stopDrawing = true
 lostItem = nil
 sMSG1 = {}
 imageBuffer = {}
 iconImageBuffer = {}
local tkt, tbl, yv = 0
 while true do
  if gid[cItemRange + tkt] then gid[cItemRange + tkt] = nil end
  tkt = tkt + 1
  if tkt >= 600 then break end
 end
 tbl = readFromFile(savePath.."/"..filename)
 yv = ser.unserialize(tbl[3])
 world.current = yv[1]
 CGD = {}
 CGD[pID] = ser.unserialize(tbl[2])
 CGD[pID]["image"] = 0
 local buben = CGD[pID]["x"]
 cPlayerSkills = ser.unserialize(tbl[4])
 cUskills = ser.unserialize(tbl[5])
 yv = ser.unserialize(tbl[6])
  for f = 1, #yv do
  gid[yv[f]["id"]] = yv[f]
   if gid[#gid]["oid"] then
   gid[#gid]["name"] = gid[gid[#gid]["oid"]]["name"]
   if gid[#gid]["props"] and type(gid[#gid]["props"]) == "table" and gid[#gid]["props"]["dds"] then for o = 1, #gid[#gid]["props"]["dds"] do gid[#gid]["name"] = "♦"..gid[#gid]["name"] end end
   mItemDataNum = mathMax(cItemRange - 1 + f, cItemRange)
   end
  end
 cUquests = ser.unserialize(tbl[7])
  for b = 1, #cUquests do
  gqd[cUquests[b][1]]["comp"] = false
  end
 yv = ser.unserialize(tbl[8])
  for f = 1, #yv do
  gqd[yv[f]]["comp"] = true
  end
 yv = ser.unserialize(tbl[10])
  for f = 1, #yv do
  gud[yv[f]]["nres"] = false
  end
 yv = ser.unserialize(tbl[9])
 gfunc.loadWorld(world.current,yv["u"] or world[world.current].spawnList)
 
  for f = 2, #yv["u"] do
   if CGD[f] then
    if yv["t"][f-1] > 0 then
	CGD[f]["resptime"] = yv["t"][f-1]
	CGD[f]["living"] = false
	else
	CGD[f]["resptime"] = 0
	CGD[f]["living"] = true
	end
   end
  end

 gfunc.teleport(buben)
 yv = nil
 tbl = nil
 end
targetQuest = 0
end

function gfunc.pbar(x,y,size,percent,color1,color2, text, textcolor, style)
local dw, c = mathMin(mathCeil(percent*size/100),size), 1
 if not style then
 buffer.square(x,y,size,1,color2)
 buffer.square(x,y,dw,1,color1)
 if text then buffer.text(x, y, textcolor, text) end
 elseif style == 1 then 
 buffer.square(x,y,size-1,1,color2)
 buffer.text(x+size-1,y,color2,"◤")
 if dw < size/4 or dw > size*0.75 then c = 1 else c = 0 end
 buffer.square(x,y,dw-c,1,color1)
 if dw < size/4 or dw > size*0.75 then buffer.text(x+dw-1,y,color1,"◤") end
 end
end

function gfunc.check_npc_dq(id)
local sdq = false
 if id > 0 and gud[id]["quests"] then
  for f = 1, #gud[id]["quests"] do
   if gqd[gud[id]["quests"][f]] and gqd[gud[id]["quests"][f]]["comp"] == 0 and CGD[pID]["lvl"] >= gqd[gud[id]["quests"][f]]["minlvl"] then
   sdq = true
   break
   end
  end
 end
return sdq
end

function gfunc.check_npc_cq(id)
local scq = false
 for f = 1, #cUquests do
  if gqd[cUquests[f][1]]["qr"] == id and cUquests[f][3] == true then
  scq = true
  break
  end
 end
return scq
end

function gfunc.drawAllCGDUnits()
local ccl, cx, cy, dx, dy, btname, vpercentr, halfWidth, subtextninfo
 for f = 2, #CGD do
 halfWidth = CGD[f]["width"]/2
 cx, cy = mathFloor(CGD[f]["x"]), mathFloor(CGD[f]["y"])
 dx,dy = cx+75-cGlobalx, 49-cy-CGD[f]["height"] 
  if CGD[f]["living"] and gfunc.getDistanceToId(pID,f) <= 95 then
   if CGD[f]["image"] ~= nil and CGD[f]["spos"] == "r" then
   buffer.image(dx,dy, imageBuffer[CGD[f]["image"]],true)
   elseif CGD[f]["image"] ~= nil and CGD[f]["spos"] == "l" then
   buffer.image(dx,dy, image.flipHorizontal(image.duplicate(imageBuffer[CGD[f]["image"]])),true)
   else buffer.text(dx,dy,0xcc2222,"ERROR")
   end
-- полоска хп над головой
   if CGD[f]["rtype"] == "e" and cTarget == f then
   gfunc.pbar(dx+mathFloor((halfWidth-8/2)), dy-2,8,mathCeil(CGD[f]["chp"])*100/CGD[f]["mhp"],0xFF0000,0x444444," ",0xffffff)
   buffer.text(mathFloor(dx+(halfWidth-8/2)+(mathFloor((8 / 2) - (unicode.len(tostring(mathCeil(CGD[f]["chp"]))) / 2)))),dy-2,0xffffff,tostring(mathCeil(CGD[f]["chp"])))  
-- прогресс в выкапывании
   elseif pickingUp and pckTarget == f and CGD[f]["rtype"] == "r" then
   vpercentr = mathCeil((maxPckTime-pckTime)*100/maxPckTime)
   gfunc.pbar(dx+mathFloor((halfWidth-8/2)),dy-2,8,vpercentr,0x009945,0x444444,vpercentr.."% ",0xffffff)
-- галочка над НПС
   elseif CGD[f]["rtype"] == "f" then
    if gfunc.check_npc_cq(CGD[f]["id"]) == true then
	ccl = 0x009922
	elseif gfunc.check_npc_dq(CGD[f]["id"]) == true then
	ccl = 0xDCBC12
	end
    if ccl then
	buffer.text(dx+mathFloor(halfWidth)-2,dy-5,ccl,"▔██▔")
    buffer.text(dx+mathFloor(halfWidth)-1,dy-4,ccl,"◤◥")   
    ccl = nil
	end
   end
-- имя над головой
   if cTarget == f and ( CGD[f]["rtype"] == "e" or CGD[f]["rtype"] == "f" ) then
	btname = tostring(gud[CGD[cTarget]["id"]]["name"])
	if unicode.len(btname) >= 24 then btname = unicode.sub(btname,1,24).."…" end
	buffer.text(mathFloor(dx+(halfWidth-24/2)+(mathFloor((24 / 2) - (unicode.len(btname) / 2)))),dy-3,0xffffff,btname)
   end
  end
-- надписи над головой
  if gfunc.getDistanceToId(pID,f) <= 95 then
  subtextninfo = ""
   for m = 1, 2 do
    if CGD[f]["tlinfo"][m] then
    subtextninfo = CGD[f]["tlinfo"][m]
    if unicode.len(tostring(CGD[f]["tlinfo"][m])) >= 24 then subtextninfo = unicode.sub(CGD[f]["tlinfo"][m][1],1,24).."…" end
    buffer.text(mathFloor(dx+(halfWidth-24/2)+(mathFloor((24 / 2) - (unicode.len(subtextninfo) / 2)))),dy-m-3,0xffffff,subtextninfo)
    end
   end
  end
 end
end

local function target(x,y)
 if cTarget ~= 1 and not showTargetInfo then 
 cTarget = 0
 end
 for f = 2, #CGD do
  if CGD[f]["living"] and clicked(x, y, mathFloor(CGD[f]["x"])+75-cGlobalx, 49-mathFloor(CGD[f]["y"])-2-CGD[f]["height"], mathFloor(CGD[f]["x"])+75-cGlobalx+CGD[f]["width"], 49-mathFloor(CGD[f]["y"])) then
  cTarget = f
  end
 end
end

----------------------------------Меню пауза-------------------------------------------------

local pauseMenulist = {
"Продолжить игру",
"Инвентарь",
"Умения персонажа",
"Характеристика",
"Текущие задания",
"Сохранить",
"Загрузить",
"Выйти из игры"
}

gfunc.pauseMenu = {x=1,y=1,w=25,h=5,buttonX=156,buttonY=2,action={}}

function gfunc.pauseMenu.draw()
local x, y = gfunc.pauseMenu.x, gfunc.pauseMenu.y
buffer.square(x, y, 30, 50, 0x9D9D9D)
buffer.text(13,2,0xffffff,"Пауза")
 for f = 1, #pauseMenulist do
 buffer.square(1, 1+f*4, 30, 3, 0x838383)
 buffer.set(1,3+f*4,0x959595,0x000000," ")
 buffer.text(mathMax(mathFloor((30/2)-(unicode.len(pauseMenulist[f])/2)),0),2+f*4,0xffffff,pauseMenulist[f])
 end
end

gfunc.pauseMenu.action["touch"] = function(ev)
 for f = 1, #pauseMenulist do
  if clicked(ev[3],ev[4],1,4+f*4-3,30,3+f*4) then
  gfunc.pauseMenuMenuAction[f]()
  ev[3], ev[4] = 0, 0
  break
  end
 end
end

local svxpbar = false

local vshowEffDescr, sEffdx, sEffdy = 0, 1, 1

-----------------------------------Панель информация о п------------------------------------------------

gfunc.playerInfoPanel = {x=1,y=1,w=25,h=5,action={}}

function gfunc.playerInfoPanel.draw()
local x, y, halfWidth = gfunc.playerInfoPanel.x, gfunc.playerInfoPanel.y, gfunc.playerInfoPanel.w / 2
buffer.square(x, y, gfunc.playerInfoPanel.w+2, 1, 0x8C8C8C)
buffer.square(x, y+gfunc.playerInfoPanel.h-1, gfunc.playerInfoPanel.w-2, 1, 0x8C8C8C)
buffer.text(x+gfunc.playerInfoPanel.w-2,y+gfunc.playerInfoPanel.h-1,0x8C8C8C,"◤")
local fxpdt = tostring(CGD[pID]["cxp"]).."/"..tostring(CGD[pID]["mxp"])
local percent3, roundPrc3 = math.modf(CGD[pID]["cxp"]*100/CGD[pID]["mxp"])
roundPrc3 = gfunc.roundupnum(roundPrc3*10)
buffer.text(x+1, y, 0xffffff, "Уровень "..CGD[pID]["lvl"])
local tpbar1 = mathFloor(CGD[pID]["chp"]).."/"..mathFloor(CGD[pID]["mhp"])
local tpbar2 = mathFloor(CGD[pID]["cmp"]).."/"..mathFloor(CGD[pID]["mmp"])
local tpbar3 = percent3.."."..roundPrc3.."% "
gfunc.pbar(x,y+1,gfunc.playerInfoPanel.w+2,mathFloor(CGD[pID]["chp"]*100/CGD[pID]["mhp"]),0xFF0000,0x5B5B5B," ", 0xffffff,1)
buffer.text(mathMax(mathFloor((halfWidth)-(#tpbar1/2)),0),y+1,0xffffff,tpbar1)
gfunc.pbar(x,y+2,gfunc.playerInfoPanel.w+1,mathFloor(CGD[pID]["cmp"]*100/CGD[pID]["mmp"]),0x0000FF,0x5B5B5B," ", 0xffffff,1)
buffer.text(mathMax(mathFloor((halfWidth)-(#tpbar2/2)),0),y+2,0xffffff,tpbar2)
gfunc.pbar(x,y+3,gfunc.playerInfoPanel.w,percent3,0xFFFF00,0x5B5B5B," ", 0x333333,1)
buffer.text(mathMax(mathFloor((halfWidth)-(#tpbar3/2)),0),y+3,0x333333,tpbar3)
if svxpbar then buffer.text(x+24-#fxpdt, y+3, 0x4F4F4F, fxpdt) end
 for f = 1, #CGD[pID]["effects"] do
  for h = 1, 2 do
   for w = 1, 3 do
   buffer.set(x+f*4-4+w,y+5+h,ged[CGD[pID]["effects"][f][1]]["i"][2*(3*(h-1)+w)-1],0xffffff,ged[CGD[pID]["effects"][f][1]]["i"][2*(3*(h-1)+w)])
   end
  end
 end
 if vshowEffDescr ~= 0 and CGD[pID]["effects"][vshowEffDescr]then
  buffer.square(sEffdx,sEffdy,mathMax(unicode.len(ged[CGD[pID]["effects"][vshowEffDescr][1]]["name"]),unicode.len(ged[CGD[pID]["effects"][vshowEffDescr][1]]["descr"])),2,0xA1A1A1,0xffffff," ")
  buffer.text(sEffdx,sEffdy,0xEDEDED,ged[CGD[pID]["effects"][vshowEffDescr][1]]["name"])
  buffer.text(sEffdx,sEffdy+1,0xCECECE,ged[CGD[pID]["effects"][vshowEffDescr][1]]["descr"])
 end
end

gfunc.playerInfoPanel.action["touch"] = function(ev)

end

------------------------------------Панель информация о цели-----------------------------------------------

gfunc.targetInfoPanel = {x=60,y=2,w=35,h=4,action={}}

function gfunc.targetInfoPanel.showInfo(x,y)
local cwtype = ""
if type(gud[CGD[cTarget]["id"]]["wtype"]) == "number" then
cwtype = baseWtype[gud[CGD[cTarget]["id"]]["wtype"]]
elseif type(gud[CGD[cTarget]["id"]]["wtype"]) == "string" then
cwtype = gud[CGD[cTarget]["id"]]["wtype"]
end
local sTInfoArray1 = {
	gud[CGD[cTarget]["id"]]["name"],
	"Тип: "..cwtype,
	"Респ: "..tostring(gud[CGD[cTarget]["id"]]["vresp"]).." секунд",
	"ID: "..tostring(CGD[cTarget]["id"]),
	"Физ.атака: "..CGD[cTarget]["ptk"][1].."-"..CGD[cTarget]["ptk"][2],
	"Маг.атака: "..CGD[cTarget]["mtk"][1].."-"..CGD[cTarget]["mtk"][2],
	"Физ.защита: "..tostring(CGD[cTarget]["pdef"].." ("..tostring(mathFloor(100*(CGD[cTarget]["pdef"]/(CGD[cTarget]["pdef"]+CGD[pID]["lvl"]*30)))).."%)"),
	"Маг.защита: "..tostring(CGD[cTarget]["mdef"].." ("..tostring(mathFloor(100*(CGD[cTarget]["mdef"]/(CGD[cTarget]["mdef"]+CGD[pID]["lvl"]*30)))).."%)"),
}
buffer.square(x, y, 27, 11, 0x6B6B6B)
gfunc.unicodeframe(x,y,27,11,0x808080)
 for f = 1, #sTInfoArray1 do
 buffer.text(x+1,y+f,0xffffff,unicode.sub(tostring(sTInfoArray1[f]),1,25))
 end
end

function gfunc.targetInfoPanel.draw()
local bl, typestr = false, {["nil"]="Обычный",["1"]="Физ.",["2"]="Маг."}
local x,y, halfWidth = gfunc.targetInfoPanel.x, gfunc.targetInfoPanel.y, gfunc.targetInfoPanel.w / 2
buffer.square(x, y, gfunc.targetInfoPanel.w, gfunc.targetInfoPanel.h-1, 0x9B9B9B)
buffer.square(x+1, y+3, gfunc.targetInfoPanel.w-2, 1, 0x9B9B9B)
buffer.text(x,y+3,0x9B9B9B,"◥")
buffer.text(x+gfunc.targetInfoPanel.w-1,y+3,0x9B9B9B,"◤")
if CGD[cTarget]["rtype"] == "e" or CGD[cTarget]["rtype"] == "p" or CGD[cTarget]["rtype"] == "m" then
local chp, mhp = CGD[cTarget]["chp"], CGD[cTarget]["mhp"] 
local namecolor, clvl, plvl = 0xffffff, CGD[cTarget]["lvl"], CGD[pID]["lvl"]
 if clvl >= plvl+2 and clvl <= plvl+4 then namecolor = 0xFFDB80
 elseif clvl >= plvl+5 and clvl <= plvl+7 then namecolor = 0xFF9200
 elseif clvl >= plvl+8 then namecolor = 0xFF1000
 elseif clvl <= plvl-2 and clvl >= plvl-5 then  namecolor = 0xBEBEBE
 elseif clvl <= plvl-6 then  namecolor = 0x00823A
 end

 if CGD[cTarget]["rtype"] == "e" then
 buffer.text(x+34-unicode.len(typestr[tostring(gud[CGD[cTarget]["id"]]["dtype"])]),y+3,0xffffff, typestr[tostring(gud[CGD[cTarget]["id"]]["dtype"])] )
 end
local pbtext, lbtext = gud[CGD[cTarget]["id"]]["name"], tostring(CGD[cTarget]["lvl"]).." уровень"
local percent = mathCeil(chp*100/mhp)
gfunc.unicodeframe(x,y,gfunc.targetInfoPanel.w,3,0xA2A2A2)
gfunc.pbar(x,y+1,gfunc.targetInfoPanel.w,percent,0xFF0000,0x5B5B5B," ", 0xffffff)
buffer.text(x + (mathMax(mathFloor((halfWidth) - (unicode.len(lbtext) / 2)), 0)), y+1, 0xffffff, lbtext)
buffer.text(x + (mathMax(mathFloor((halfWidth) - (unicode.len(pbtext) / 2)), 0)), y+2,namecolor,pbtext)
bl = true
elseif CGD[cTarget]["rtype"] == "f" then
local pntext, lbtext = gud[CGD[cTarget]["id"]]["wtype"], gud[CGD[cTarget]["id"]]["name"]
buffer.text(x,y,0x727272,"НИП")
buffer.text(x + (mathMax(mathFloor((halfWidth) - (unicode.len(lbtext) / 2)), 0)), y+1, 0xffffff, lbtext)
buffer.text(x + (mathMax(mathFloor((halfWidth) - (unicode.len(pntext) / 2)), 0)), y+2, 0xC8C8C8, pntext)
bl = false
elseif CGD[cTarget]["rtype"] == "r" then
buffer.text(x,y,0x727272,"Ресурс")
local pntext = "Нажмите 'E' чтобы собрать"
buffer.text(x + (mathMax(mathFloor((halfWidth) - (unicode.len(gud[CGD[cTarget]["id"]]["name"]) / 2)), 0)), y+1, 0xffffff, gud[CGD[cTarget]["id"]]["name"])
buffer.text(x + (mathMax(mathFloor((halfWidth) - (unicode.len(pntext) / 2)), 0)), y+2, 0x727272, pntext)
bl = false
elseif CGD[cTarget]["rtype"] == "c" then
local pntext = "Нажмите 'E' чтобы использовать"
buffer.text(x + (mathMax(mathFloor((halfWidth) - (unicode.len(gud[CGD[cTarget]["id"]]["name"]) / 2)), 0)), y+1, 0xffffff, gud[CGD[cTarget]["id"]]["name"])
buffer.text(x + (mathMax(mathFloor((halfWidth) - (unicode.len(pntext) / 2)), 0)), y+2, 0x727272, pntext)
bl = false
end
if bl then buffer.text(x+1,y+3,0xffffff,"О персонаже") end
 for f = 1, #CGD[cTarget]["effects"] do
  for h = 1, 2 do
   for w = 1, 3 do
   buffer.square(x+f*4-4+w,y+4+h,1,1,ged[CGD[cTarget]["effects"][f][1]]["i"][2*(3*(h-1)+w)-1],0xffffff,ged[CGD[cTarget]["effects"][f][1]]["i"][2*(3*(h-1)+w)])
   end
  end
 end
 if showTargetInfo then
 gfunc.targetInfoPanel.showInfo(x+1,y+4)
 end
end

-------------------------------Панель умений----------------------------------------------------

local vtskillUsingMsg, skillUsingMsg = 0, {}

gfunc.skillsTopPanel = {
	x=110,y=1,w=30,h=5,action={},
	t={
	{c = 0x614251, t = "/2"},
	{c = 0x0000FF, t = "*3"},
	{c = 0x008500, t = "@4"},
	{c = 0x8600A0, t = "&5"},
	{c = 0xEE0000, t = "!6"}
	}
}

function gfunc.skillsTopPanel.draw()
local x, y = gfunc.skillsTopPanel.x, gfunc.skillsTopPanel.y
buffer.square(x, y, gfunc.skillsTopPanel.w, gfunc.skillsTopPanel.h, 0x9B9B9B)
 for f = 1, #gfunc.skillsTopPanel.t do
 buffer.square(x+4+(f*5-5), y+1, 2, 1, gfunc.skillsTopPanel.t[f].c)
 buffer.text(x+4+(f*5-5), y+1, 0xffffff,gfunc.skillsTopPanel.t[f].t)
  if cUskills[f+1] > 0 then
  buffer.text(x+4+(f*5-5), y+2, 0xffffff, tostring(mathCeil(cPlayerSkills[cUskills[f+1]][2]/10)))
  end
 end
if vtskillUsingMsg > 0 then buffer.text(x+1,y+4,0xC1C1C1,skillUsingMsg[#skillUsingMsg]) end
end

-------------------------------Спонтанные диалоги----------------------------------------------------

local spdialogs = {
[1]={
	["text"]=string.rep("Текст. ",5),
	{["text"]="Продолжить1",["action"]="close"},
	{["text"]="Продолжить2",["action"]="close"},
	{["text"]="Продолжить3",["action"]="close"}
	}
}

gfunc.specialDialog = {w=160,h=12,current=1,trg=1,action={}}

function gfunc.specialDialog.draw()
local x, y = mathFloor(1+160/2-spDialog.w/2), 1+50-spDialog.h
buffer.square(x, y, spDialog.w, spDialog.h, 0x5E5E5E, nil, nil, 15)
buffer.square(x, y, spDialog.w, 1, 0x5E5E5E)
local num_h = mathCeil(unicode.len(spdialogs[spDialog.current]["text"])/(spDialog.w/2))
local text_y = 50-mathFloor(spDialog.h/2-num_h/2)
local ctext 
 for f = 1, num_h do
 ctext = unicode.sub(spdialogs[spDialog.current]["text"],spDialog.w/2*f-spDialog.w/2,spDialog.w/2*f)
 buffer.text(1+mathFloor(spDialog.w/2-unicode.len(ctext)/2), text_y+f-4, 0xEDEDED, ctext)
 end
 for f = 1, #spdialogs[spDialog.current] do
 ctext = spdialogs[spDialog.current][f]["text"]
 if spDialog.trg == f then buffer.square(x, text_y+f, spDialog.w, 1, 0x989898, nil, nil, 40) end
 buffer.text(1+mathFloor(spDialog.w/2-unicode.len(ctext)/2),text_y+f, 0xEDEDED, ctext)
 end
end

------------------------------Диалоги НПС-----------------------------------------------------

gfunc.npcDialog = {x=12,y=10,w=50,h=24,action={}}

function gfunc.npcDialog.draw(x,y)
local x, y, w, h = gfunc.npcDialog.x, gfunc.npcDialog.y, gfunc.npcDialog.w, gfunc.npcDialog.h
local isQnComp, isQcomp, sColor = false, false
insertQuests(cTarget,cDialog)
 for f = 1, #cDialog do
  if not cDialog[f] then
  tableRemove(cDialog,f)
  end
 end
 for f = 1, #cDialog do
  isQnComp = false
  if cDialog[#cDialog-f+1] ~= nil then
   if cDialog[#cDialog-f+1]["action"] == "qdialog" then
    for l = 1, #cUquests do
     if cUquests[l][1] == cDialog[#cDialog-f+1]["q"] and cUquests[l][3] == false then
     isQnComp = true
	 break
	 end
    end
   end
   if cDialog[#cDialog-f+1] ~= nil and cDialog[#cDialog-f+1]["action"] == "qdialog" then
    if isQnComp or gqd[cDialog[#cDialog-f+1]["q"]]["minlvl"] > CGD[pID]["lvl"] or gqd[cDialog[#cDialog-f+1]["q"]]["comp"] == true then
    tableRemove(cDialog,#cDialog-f+1)
    end
   elseif cDialog[#cDialog-f+1]["action"] == "setWorld" and CGD[pID]["lvl"] < cDialog[#cDialog-f+1]["reqlvl"] then
   cDialog[#cDialog-f+1]["text"] = unicode.sub(cDialog[#cDialog-f+1]["text"],1,unicode.len(cDialog[#cDialog-f+1]["text"])-#tostring(cDialog[#cDialog-f+1]["reqlvl"])-2)
   cDialog[#cDialog-f+1]["text"] = cDialog[#cDialog-f+1]["text"].." "..cDialog[#cDialog-f+1]["reqlvl"].."+"
   end
  end
 end
buffer.square(x, y, w, h, 0x9B9B9B)
buffer.square(x, y, w, 1, 0x606060)
buffer.square(x+1, y+1, w-2, 12, 0x7A7A7A)
buffer.square(x+1, y+14, w-2, 9, 0x7A7A7A)
buffer.text(x+w-1,y,0xffffff,"X")
local text1 = gud[CGD[cTarget]["id"]]["name"]
buffer.text(x+(mathMax(mathFloor((w / 2) - (unicode.len(text1) / 2)), 0)), y, 0xffffff, text1) 
local text2 = gfunc.textWrap(cDialog["text"],w-4)
 for f = 1, #text2 do
 buffer.text(x+2,y+1+f,0xffffff,text2[f])
 end
 for f = 1, #cDialog do
 sColor = 0xffffff
 isQnComp, isQcomp = false, false
  for l = 1, #cUquests do
   if cDialog[f] and cDialog[f]["action"] == "qdialog" then
   if cUquests[l][1] == cDialog[f]["q"] and not cUquests[l][3] then isQnComp = true end
   elseif cDialog[f] and cDialog[f]["action"] == "cmpquest" then 
   isQcomp = true
   end
  end 
  if isQnComp then
  sColor = 0x555555
  elseif isQcomp then
  sColor = 0x1AB235
  end
  if cDialog[f] then buffer.text(x+2,y+14+f,sColor,cDialog[f]["text"]) end
 end
end

gfunc.npcDialog.action["touch"] = function(ev)
local closeButtonX = gfunc.npcDialog.x+gfunc.npcDialog.w-1
 for f = 1, #cDialog do
  if cDialog[f]["action"] == "getquest" and gqd[cDialog[f]["do"]]["comp"] == true then
  tableRemove(cDialog[f])
  end
 end
   for f = 1, #cDialog do
    if ev[5] == 0 and clicked(ev[3],ev[4],gfunc.npcDialog.x+2,gfunc.npcDialog.y+14+f,gfunc.npcDialog.x+gfunc.npcDialog.w-2,gfunc.npcDialog.y+14+f) then
	 if cDialog[f]["action"] == "close" then
	 cWindowTrd = nil
	 cDialog = nil
	 paused = false
	 elseif cDialog[f]["action"] == "trade" then
	 gfunc.tradew.loaded = loadfile(dir.."data/trade.data")(cDialog[f]["do"])
	 gfunc.tradew.sect = 1
	 cWindowTrd = "tradewindow"
	 elseif cDialog[f]["action"] == "craft" then
	 gfunc.craftw.loaded = loadfile(dir.."data/manufacturing.data")(cDialog[f]["do"])
	 gfunc.craftw.sect = 1
	 cWindowTrd = "craftwindow"
	 elseif cDialog[f]["action"] == "dialog" then
	 cDialog = cDialog[f]["do"]
	 elseif cDialog[f]["action"] == "qdialog" and CGD[pID]["lvl"] >= gqd[cDialog[f]["q"]]["minlvl"] then
	 cDialog = cDialog[f]["do"]
	 elseif cDialog[f]["action"] == "getquest" and gqd[cDialog[f]["do"]]["comp"] == 0 and CGD[pID]["lvl"] >= gqd[cDialog[f]["do"]]["minlvl"] then
	 getQuest(cDialog[f]["do"])
	 gqd[cDialog[f]["do"]]["qstgve"] = CGD[cTarget]["id"]
	 gqd[cDialog[f]["do"]]["comp"] = false
	 cWindowTrd = nil
	 cDialog = nil
	 paused = false
	 elseif cDialog[f]["action"] == "cmpquest" then
	  for t = 1, #cUquests do
	   if cUquests[t][1] == cDialog[f]["do"] and cUquests[t][3] then
	    if gqd[cDialog[f]["do"]]["type"] == "f" then
		 for l = 1, #gqd[cDialog[f]["do"]]["targ"] do
		  for k = 1, #CGD[pID]["inventory"]["bag"] do
		   if CGD[pID]["inventory"]["bag"][k][1] == gqd[cDialog[f]["do"]]["targ"][l][1] and CGD[pID]["inventory"]["bag"][k][2] >= gqd[cDialog[f]["do"]]["targ"][l][2] then
		   CGD[pID]["inventory"]["bag"][k][2] = CGD[pID]["inventory"]["bag"][k][2] - gqd[cDialog[f]["do"]]["targ"][l][2]
		   end
		  end
		 end
		end
	   -- *награда за задание*
	    if gqd[cDialog[f]["do"]]["qreward"] then
		 if type(gqd[cDialog[f]["do"]]["qreward"]["item"]) == "table" and #gqd[cDialog[f]["do"]]["qreward"]["item"] <= gfunc.checkInventorySpace() then
		 gfunc.GetQuestReward(cDialog[f]["do"])	
		 tenb = true
		 elseif type(gqd[cDialog[f]["do"]]["qreward"]["item"]) == "table" and #gqd[cDialog[f]["do"]]["qreward"]["item"] > gfunc.checkInventorySpace() then
		 gfunc.textmsg1("Необходимо "..#gqd[cDialog[f]["do"]]["qreward"]["item"].." ячеек в инвентаре")
		 tenb = false
		 end
		 if gqd[cDialog[f]["do"]]["qreward"]["item"] == nil then tenb = true; gfunc.GetQuestReward(cDialog[f]["do"]) end
		end
		if tenb and not gqd[cDialog[f]["do"]]["fct"] then
	     if not gqd[cDialog[f]["do"]]["repeat"] then
		 gqd[cDialog[f]["do"]]["comp"] = true
	     else
		 gqd[cDialog[f]["do"]]["comp"] = 0
		 end
	    tableRemove(cUquests,t)
	    cWindowTrd = nil
	    cDialog = nil
	    paused = false
	    break
	    elseif tenb and gqd[cDialog[f]["do"]]["fct"] then
		 if gqd[cDialog[f]["do"]]["fct"] == "setquest" then
		  if not gqd[cDialog[f]["do"]]["repeat"] then
		  gqd[cDialog[f]["do"]]["comp"] = true
	      else
		  gqd[cDialog[f]["do"]]["comp"] = 0
		  end
		  getQuest(gqd[cDialog[f]["do"]]["value"])
		  gfunc.textmsg1("Задание '"..gqd[gqd[cDialog[f]["do"]]["value"]]["name"].."' получено") 
		  gqd[gqd[cDialog[f]["do"]]["value"]]["qstgve"] = CGD[cTarget]["id"]
		  gqd[gqd[cDialog[f]["do"]]["value"]]["comp"] = false
		  tableRemove(cUquests,t)
	      cWindowTrd = nil
	      cDialog = nil
	      paused = false
		  break
		 end
		end
	   end
	  end
	 elseif cDialog[f]["action"] == "setWorld" and CGD[pID]["lvl"] >= cDialog[f]["reqlvl"] then
	 gfunc.teleport(cDialog[f]["do"][2] or 1,cDialog[f]["do"][1] or 1)
	 end
	end
   end
 if clicked(ev[3],ev[4],closeButtonX,gfunc.npcDialog.y,closeButtonX,gfunc.npcDialog.y) then
 cWindowTrd = nil
 cDialog = nil
 paused = false   
 end
end


-----------------------------Окно инвентарь------------------------------------------------------

local awSutypeList = {
["helmet"] = "Шлем",
["armor"] = "Броня",
["pants"] = "Штаны",
["footwear"] = "Сапоги",
["pendant"] = "Кулон",
["robe"] = "Накидка",
["ring"] = "Кольцо",
[1] = "Меч",
[2] = "Копьё",
[3] = "Короткая секира",
}

local invTItem = 0
local invcTItem, invcTargetItem, showItemData = 0, 0, false
local invIdx, invIdy = 1, 1

local spisok1 = {
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
}

function gfunc.getItemInfo(id)
local info = {}
local function giiwcAdd(t,c) tableInsert(info,{tostring(t),c}) end
local itemtype, itemsubtype = gid[id]["type"], gid[id]["subtype"] 
giiwcAdd(gid[id]["name"], gid[id]["ncolor"])
 if itemtype == "armors" or itemtype == "weapon" then
 giiwcAdd(awSutypeList[itemsubtype], 0xBCBCBC)
 giiwcAdd("Уровень "..tostring(gid[id]["lvl"]), 0xffffff)
 end
 if itemtype == "weapon" then
 giiwcAdd("Скорость атаки: "..tostring(mathCeil((1/weaponHitRate[gid[id]["subtype"]])*10)/10).." уд./сек.", 0xEFEFEF)
 giiwcAdd("Дальность атаки: "..gfunc.watds[gid[id]["subtype"]], 0xEFEFEF)
 end
 if itemtype == "item" and itemsubtype == "res" then
 giiwcAdd("Уровень материала "..tostring(gid[id]["lvl"]), 0xffffff)
 end
 if itemtype == "armors" then
 if gid[id]["props"]["pdef"] ~= 0 then giiwcAdd("Защита +"..tostring(gid[id]["props"]["pdef"]), 0xEFEFEF) end
 if gid[id]["props"]["mdef"] ~= 0 then giiwcAdd("Магическая защита +"..tostring(gid[id]["props"]["mdef"]), 0xEFEFEF) end
 elseif itemtype == "weapon" then
 if gid[id]["props"]["phisat"] and gid[id]["props"]["phisat"] ~= 0 then giiwcAdd("Физическая атака "..gid[id]["props"]["phisat"][1].."-"..gid[id]["props"]["phisat"][2], 0xffffff) end
 if gid[id]["props"]["magat"] and gid[id]["props"]["magat"] ~= 0 then giiwcAdd("Магическая атака "..gid[id]["props"]["magat"][1].."-"..gid[id]["props"]["magat"][2], 0xffffff) end
 end
 if itemtype == "armors" or itemtype == "weapon" or itemtype == "potion" then
  if gid[id]["subtype"] == "health" then
  giiwcAdd("Восстановить "..tostring(ged[1]["val"][gid[id]["lvl"]]).." ед. здоровья за 10 секунд", 0xEFEFEF)
  elseif gid[id]["subtype"] == "mana" then
  giiwcAdd("Восстановить "..tostring(ged[2]["val"][gid[id]["lvl"]]).." ед. маны за 10 секунд", 0xEFEFEF)
  end
  if gid[id]["reqlvl"] > CGD[pID]["lvl"] then
  giiwcAdd("Требуемый уровень: "..gid[id]["reqlvl"], 0xFF0000)
  else
  giiwcAdd("Требуемый уровень: "..gid[id]["reqlvl"], 0xffffff)
  end
  if itemtype == "armors" or itemtype == "weapon" then
  local banan
   if gid[id]["props"]["dds"] ~= nil then
    for e = 1, #gid[id]["props"]["dds"] do
    banan = ""
     if gid[id]["props"]["dds"][e] and gid[id]["props"]["dds"][e][2] > 0 then
     if #spisok1[gid[id]["props"]["dds"][e][1]] >= 2 then banan = spisok1[gid[id]["props"]["dds"][e][1]][2] end
     giiwcAdd(spisok1[gid[id]["props"]["dds"][e][1]][1].." + "..gid[id]["props"]["dds"][e][2]..banan,cp.blue)
     end
    end
   end
  end
 end
 if gid[id]["description"] ~= "" then
  for f = 1, mathCeil(unicode.len(gid[id]["description"])/35) do
  giiwcAdd(unicode.sub(gid[id]["description"],1+f*35-35,f*35), 0xBCBCBC)
  end
 end
local v = ""
if invTItem > 1 then v = " ("..tostring(gid[id]["cost"]*invTItem)..")" end
giiwcAdd("Цена "..tostring(gid[id]["cost"])..v, 0xffffff)
return info
end

function gfunc.drawItemDescription(x,y,source)
 if not source then
 source = {{"Неправильный предмет",0xFF0000}}
 end
local hn, w, h = 0, 0, #source 
 for f = 1, #source do
 if unicode.len(source[f][1]) > w then w = unicode.len(source[f][1]) end
 end
 buffer.square(mathMin(x-1,159-w), mathMin(y-1,49-h), w+2, h+2, 0x6B6B6B)
 gfunc.unicodeframe(mathMin(x-1,159-w), mathMin(y-1,49-h), w+2, h+2, 0x808080)
  for f = 1, #source do
  gfunc.scolorText(mathMin(x,160-w),mathMin(y+f-1,50-h+f-1),source[f][2],source[f][1])
  end
end

local wItemTypes = {
	"helmet",
	"pendant",
	"armor",
	"robe",
	"pants",
	"weapon",
	"footwear",
	"ring",
}

local itemInfo

gfunc.inventory = {x=1,y=1,w=160,h=50,b1={x=2,y=47,w=14},action={}}

function gfunc.inventory.draw()
local x, y = gfunc.inventory.x, gfunc.inventory.y
local formula, xps, yps
local textRemoveItem = "Выбросить предмет(ы)"
buffer.square(x, y, gfunc.inventory.w, gfunc.inventory.h, 0x9B9B9B)
buffer.square(x, y, gfunc.inventory.w, 1, 0x525252)
buffer.square(x, y+49, gfunc.inventory.w, 1, 0x525252)
buffer.square(x, y+1, 105, 45, 0x767676)
buffer.square(x+106, y+1, 43, 45, 0x4A4A4A)
 for f = 1, 5 do
 buffer.square(x, y+1+(f*11-11), 105, 1, 0x4A4A4A)
 end
  for f = 1, 6 do
 buffer.square(x+(f*21-21), y+1, 1, 45, 0x4A4A4A)
 end
 for f = 1, 4 do
  for i = 1, 2 do
   if iconImageBuffer[0][wItemTypes[(f-1)*2+i]] then
   buffer.image(107+i*21-21, 3+f*11-11, iconImageBuffer[0][wItemTypes[(f-1)*2+i]])
   else
   buffer.square(107+i*21-21, 3+f*11-11, 20, 10, 0x00)
   end
  end
 end
buffer.text(x+1,y,0xC4C420,"●•. Монеты: "..tostring(CGD[pID]["cash"]))
buffer.text(x+75,y,0xffffff,"Инвентарь")
buffer.text(x+152,y,0xffffff,"Закрыть")
 for y1 = 1, 4 do
  for x1 = 1, 5 do
  formula, xps, yps = (y1-1)*5+x1, x+1+x1*21-21, y+2+y1*11-11
   if CGD[pID]["inventory"]["bag"][formula][1] ~= 0 and CGD[pID]["inventory"]["bag"][formula][2] ~= 0 then
    if iconImageBuffer[formula] then
	 if gid[CGD[pID]["inventory"]["bag"][formula][1]] then
	 buffer.image(xps, yps, iconImageBuffer[formula])
	  if CGD[pID]["inventory"]["bag"][formula][2] > 1 then
      buffer.square(xps, yps+9, #tostring(CGD[pID]["inventory"]["bag"][formula][2]), 1, 0x4A4A4A)
	  buffer.text(xps,yps+9,0xffffff,tostring(CGD[pID]["inventory"]["bag"][formula][2]))
      end
	 else
	 buffer.image(xps, yps, image.load(dir.."image/itemnotex.pic"))
	 end
    else
	buffer.square(xps, yps, 20, 10, 0x00)
	end
   end
  end
 end
 for y1 = 1, 4 do
  for x1 = 1, 2 do
   formula, xps, yps = (y1-1)*2+x1, 107+x1*21-21, 3+y1*11-11
   if CGD[pID]["inventory"]["weared"][wItemTypes[formula]] ~= 0 then
    if iconImageBuffer[wItemTypes[formula]] then
	 if gid[CGD[pID]["inventory"]["weared"][wItemTypes[formula]]] then
	 buffer.image(xps, yps, iconImageBuffer[wItemTypes[formula]])
	 else
	 buffer.image(xps, yps, image.load(dir.."image/itemnotex.pic"))
	 end
	else
	buffer.square(xps, yps, 20, 10, 0x00)
	end
   end
  end
 end
buffer.text(2,48,0x444444,sMSG3)
 if showItemData and invcTItem ~= 0 then
 buffer.square(gfunc.inventory.b1.x,gfunc.inventory.b1.y,unicode.len(textRemoveItem),1,0x3c539e)
 buffer.text(gfunc.inventory.b1.x,gfunc.inventory.b1.y,0xFEFEFE,textRemoveItem)
 -- описание
 gfunc.drawItemDescription(invIdx,invIdy,itemInfo)
 end
end


gfunc.inventory.action["touch"] = function(ev)
 if clicked(ev[3],ev[4],gfunc.inventory.x+gfunc.inventory.w-8,gfunc.inventory.y,gfunc.inventory.x+gfunc.inventory.w-1,gfunc.inventory.y) then
 cWindowTrd = "pause"
 iconImageBuffer = {}
 end
  -- кнопка выбросить предмет
  if showItemData and invcTargetItem ~= 0 and clicked(ev[3],ev[4],gfunc.inventory.b1.x,gfunc.inventory.b1.y,gfunc.inventory.b1.x+gfunc.inventory.b1.w,gfunc.inventory.b1.y) then
  -- чистка памяти при утрате предмета
   if CGD[pID]["inventory"]["bag"][invcTargetItem][1] >= cItemRange then 
   gid[CGD[pID]["inventory"]["bag"][invcTargetItem][1]] = nil 
   end
  -- пустая ячейка в инв.
  CGD[pID]["inventory"]["bag"][invcTargetItem] = {0,0}
  -- чистка ячейки буфера
  iconImageBuffer[invcTargetItem] = nil
  -- скрыть описание
  showItemData, invcTargetItem, itemInfo = false, 0, nil
  end
 local fbParam = true
 local nwitemuwr, xps, yps
  for f = 1, 4 do
   for i = 1, 5 do
   xps, yps = 2+i*21-21, 3+f*11-11
   formula = (f-1)*5+i
	if CGD[pID]["inventory"]["bag"][formula][1] ~= 0 and CGD[pID]["inventory"]["bag"][formula][2] ~= 0 then
     if clicked(ev[3],ev[4],xps,yps,xps+19,yps+9) then
	 pItem = gid[CGD[pID]["inventory"]["bag"][formula][1]]
	  if ev[5] == 0 then
	  invcTItem = CGD[pID]["inventory"]["bag"][formula][1]
	  invcTargetItem = formula
      invTItem = CGD[pID]["inventory"]["bag"][formula][2]
	  itemInfo = gfunc.getItemInfo(CGD[pID]["inventory"]["bag"][formula][1])
	  showItemData = true
      invIdx, invIdy = ev[3], ev[4]
	  fbParam = false
	  break
	  elseif ev[5] == 1 and gid[CGD[pID]["inventory"]["bag"][formula][1]] then
	   -- armors
	   if pItem["type"] == "armors" and CGD[pID]["lvl"] >= pItem["reqlvl"] then
		if CGD[pID]["inventory"]["weared"][pItem["subtype"]] == 0 then
	    CGD[pID]["inventory"]["weared"][pItem["subtype"]] = CGD[pID]["inventory"]["bag"][formula][1]
		iconImageBuffer[pItem["subtype"]] = image.load(dir.."itempic/"..loadedItemIcons[gid[CGD[pID]["inventory"]["bag"][formula][1]]["icon"]]..".pic")
		CGD[pID]["inventory"]["bag"][formula][1] = 0
		CGD[pID]["inventory"]["bag"][formula][2] = 0
		 if iconImageBuffer[formula] ~= nil then
		 iconImageBuffer[formula] = nil
		 end
	    else
		nwitemuwr = CGD[pID]["inventory"]["weared"][pItem["subtype"]]
		CGD[pID]["inventory"]["weared"][pItem["subtype"]] = CGD[pID]["inventory"]["bag"][formula][1]
		iconImageBuffer[gid[nwitemuwr]["subtype"]] = image.load(dir.."itempic/"..loadedItemIcons[gid[CGD[pID]["inventory"]["bag"][formula][1]]["icon"]]..".pic")
		CGD[pID]["inventory"]["bag"][formula][1] = nwitemuwr
		CGD[pID]["inventory"]["bag"][formula][2] = 1
		iconImageBuffer[formula] = image.load(dir.."itempic/"..loadedItemIcons[gid[nwitemuwr]["icon"]]..".pic")
		end
		-- weapon
	   elseif pItem["type"] == "weapon" and CGD[pID]["lvl"] >= pItem["reqlvl"] then
		if CGD[pID]["inventory"]["weared"]["weapon"] == 0 then
	    CGD[pID]["inventory"]["weared"]["weapon"] = CGD[pID]["inventory"]["bag"][formula][1]
		iconImageBuffer["weapon"] = image.load(dir.."itempic/"..loadedItemIcons[gid[CGD[pID]["inventory"]["bag"][formula][1]]["icon"]]..".pic")
		CGD[pID]["inventory"]["bag"][formula][1] = 0
		CGD[pID]["inventory"]["bag"][formula][2] = 0
		 if iconImageBuffer[formula] ~= nil then
		 iconImageBuffer[formula] = nil
		 end		 
		else
		nwitemuwr = CGD[pID]["inventory"]["weared"]["weapon"]
		CGD[pID]["inventory"]["weared"]["weapon"] = CGD[pID]["inventory"]["bag"][formula][1]
		iconImageBuffer["weapon"] = image.load(dir.."itempic/"..loadedItemIcons[gid[CGD[pID]["inventory"]["bag"][formula][1]]["icon"]]..".pic")
		CGD[pID]["inventory"]["bag"][formula][1] = nwitemuwr
		CGD[pID]["inventory"]["bag"][formula][2] = 1
		iconImageBuffer[formula] = image.load(dir.."itempic/"..loadedItemIcons[gid[nwitemuwr]["icon"]]..".pic")
		end
	   -- potion
	   elseif pItem["type"] == "chest" then
		for t = 1, #pItem["props"] do
		 if 10^3-pItem["props"][t][3]*10 <= gfunc.random(1,10^3) then
		 addItem(pItem["props"][t][1],pItem["props"][t][2])
		 break
		 end
		end
       gfunc.textmsg3("Использован предмет "..pItem["name"])
	   CGD[pID]["inventory"]["bag"][formula][2] = CGD[pID]["inventory"]["bag"][formula][2] - 1
		elseif pItem["type"] == "tlp" then
		CGD[pID]["x"], cGlobalx, cBackgroundPos = 1, 1, 1
		gfunc.textmsg3("Использован предмет "..pItem["name"])
		CGD[pID]["inventory"]["bag"][formula][2] = CGD[pID]["inventory"]["bag"][formula][2]	- 1	
		elseif pItem["type"] == "potion" and CGD[pID]["lvl"] >= pItem["reqlvl"] then
		 if pItem["subtype"] == "health" then
		 gfunc.addUnitEffect(pID,1,pItem["lvl"])
		 CGD[pID]["inventory"]["bag"][formula][2] = CGD[pID]["inventory"]["bag"][formula][2] - 1
		 elseif pItem["subtype"] == "mana" then
		 gfunc.addUnitEffect(pID,2,pItem["lvl"])
		 CGD[pID]["inventory"]["bag"][formula][2] = CGD[pID]["inventory"]["bag"][formula][2] - 1
		 end
		gfunc.textmsg3("Использован предмет "..pItem["name"])
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
     formula, xps, yps = (f-1)*2+i, 107+i*21-21, 3+f*11-11
	 if CGD[pID]["inventory"]["weared"][wItemTypes[formula]] ~= 0 then
      if clicked(ev[3],ev[4],xps,yps,xps+19,yps+9) then
	   if ev[5] == 0 then
	   invcTItem = CGD[pID]["inventory"]["weared"][wItemTypes[formula]]
	   invTItem = 1
	   showItemData = true
	   itemInfo = gfunc.getItemInfo(CGD[pID]["inventory"]["weared"][wItemTypes[formula]])
       invIdx, invIdy = ev[3], ev[4]
	   fbParam = false
	   break
	   else
       nwitemuwr = addItem(CGD[pID]["inventory"]["weared"][wItemTypes[formula]],1)
	   iconImageBuffer[nwitemuwr] = image.load(dir.."itempic/"..loadedItemIcons[gid[CGD[pID]["inventory"]["weared"][wItemTypes[formula]]]["icon"]]..".pic")
	   CGD[pID]["inventory"]["weared"][wItemTypes[formula]] = 0
	   	if iconImageBuffer[wItemTypes[formula]] ~= nil then
		iconImageBuffer[wItemTypes[formula]] = nil
		end	   
	   nwitemuwr = nil
	   end
	  end
	 end
	 if CGD[pID]["inventory"]["weared"][wItemTypes[formula]] == 0 then
	  if clicked(ev[3],ev[4],xps,yps,xps+19,yps+9) then
	   if ev[5] == 0 then
	   invcTItem = 1
	   showItemData = true
	   itemInfo = {{gfunc.getWItemTypeName(wItemTypes[formula]),0xFFFFFF}}
       invIdx, invIdy = ev[3], ev[4]
	   fbParam = false
	   end
	  end
	 end
    formula = nil
	end
   end
   if fbParam then
   invcTargetItem = 0
   invTItem = 0
   showItemData = false
   invIdx, invIdy = 1, 1
   end
 gfunc.playerRV()
end


-----------------------------Окно торговля------------------------------------------------------

function gfunc.genitiveWordEnding(rstring,number)
local numokn,numpokn,cletter = tonumber(string.sub(tostring(number),-1,-1)), tonumber(string.sub(tostring(number),-2,-2)), ""
 if numokn == 1 then 
 cletter = "а"
 elseif numokn >= 2 and numokn <= 4 then
 cletter = "ы"
 elseif numokn >= 5 and numokn <= 9 then
 cletter = ""
 end
if numpokn == 1 or numokn == 0 then cletter = "" end
return rstring..cletter
end

gfunc.tradew = {
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

gfunc.tradew.twx = mathFloor(80-gfunc.tradew.cWidth/2)
gfunc.tradew.twy = mathFloor(25-gfunc.tradew.cHeight/2)

function gfunc.tradew.draw()
local x, y = gfunc.tradew.x, gfunc.tradew.y
buffer.square(x, y, gfunc.tradew.w, gfunc.tradew.h, 0x9B9B9B)
buffer.square(x, y, gfunc.tradew.w, 1, 0x525252)
buffer.square(x, y+1, gfunc.tradew.w, 3, 0x747474)
local hclr
local t = "Торговля"
buffer.text(mathMax(80-(unicode.len(t)/2), 0), y, 0xffffff, t)
buffer.text(x+gfunc.tradew.w-9,y,0xffffff,"Закрыть")
buffer.text(x+1,y,0xffffff,"Монеты "..CGD[pID]["cash"])
hclr = {"Перейти к продаже","Перейти к покупке"}
buffer.square(x+118, y+1, unicode.len(hclr[gfunc.tradew.torg])+2, 3, 0x8a8a8a)
buffer.text(x+119, y+2,0xffffff,hclr[gfunc.tradew.torg])
 if gfunc.tradew.torg == 1 then
 buffer.text(x+1,y+3,0xC2C2C2,"Наименование")
 buffer.text(x+65,y+3,0xC2C2C2,"Цена за единицу")
  for f = 1, #gfunc.tradew.loaded do
  if gfunc.tradew.sect == f then hclr = 0x525252 else hclr = 0x606060 end
  buffer.square(x+1+f*26-26, y+1, 25, 1, hclr)
  buffer.text(x+1+f*26-26, y+1, 0xCCCCCC, unicode.sub(gfunc.tradew.loaded[f]["s_name"],1,25))
  end
  for f = 1, mathMin(#gfunc.tradew.loaded[gfunc.tradew.sect], 24) do
  if f+4*gfunc.tradew.tScrl-4 == gfunc.tradew.titem then buffer.square(x+1,y+4+f*2-2, 160, 3, 0x818181) end
  end
  for f = 1, mathMin(#gfunc.tradew.loaded[gfunc.tradew.sect]+1, 24) do
   buffer.text(x+1,y+4+f*2-2,0xffffff,"═")
   buffer.text(x+2,y+4+f*2-2,0xffffff,string.rep("─",157))
  end
  for f = 1, mathMin(#gfunc.tradew.loaded[gfunc.tradew.sect], 24) do
  buffer.text(x+1,y+4+f*2-1,0xffffff,gid[gfunc.tradew.loaded[gfunc.tradew.sect][f+4*gfunc.tradew.tScrl-4]["item"]]["name"])
  buffer.text(x+65,y+4+f*2-1,0xffffff,tostring(gfunc.tradew.loaded[gfunc.tradew.sect][f+4*gfunc.tradew.tScrl-4]["cost"])..gfunc.genitiveWordEnding(" монет",gfunc.tradew.loaded[gfunc.tradew.sect][f+4*gfunc.tradew.tScrl-4]["cost"]))
  end
  local tn = "Купить"
  if gfunc.tradew.titem > 0 then
  local clr, smx, smy = 0xCCCCCC, gfunc.tradew.twx, gfunc.tradew.twy
  buffer.square(smx, smy, gfunc.tradew.cWidth, gfunc.tradew.cHeight, 0x828282)
  gfunc.unicodeframe(smx, smy, gfunc.tradew.cWidth, gfunc.tradew.cHeight, 0x4c4c4c)
  buffer.square(smx-23, smy, 22, 12, 0x828282)
  buffer.image(smx-22, smy+1, iconImageBuffer[1])
  buffer.text(smx+gfunc.tradew.cWidth-2, smy, 0x4c4c4c, "X")
  buffer.text(smx+(gfunc.tradew.cWidth/2-unicode.len(gid[gfunc.tradew.loaded[gfunc.tradew.sect][gfunc.tradew.titem]["item"]]["name"])/2), smy+1, clr, gid[gfunc.tradew.loaded[gfunc.tradew.sect][gfunc.tradew.titem]["item"]]["name"])
  buffer.text(smx+1,smy+2, clr, "Покупка предмета")
  buffer.text(smx+1,smy+3, clr, "Количество:")
  buffer.square(smx+13, smy+3, #tostring(gfunc.tradew.titemcount)+4, 1, 0x616161)
  buffer.text(smx+13,smy+3, clr, "+ "..gfunc.tradew.titemcount.." -")
  buffer.text(smx+1,smy+4, clr, "Цена: "..gfunc.tradew.loaded[gfunc.tradew.sect][gfunc.tradew.titem]["cost"]..gfunc.genitiveWordEnding(" монет",gfunc.tradew.loaded[gfunc.tradew.sect][gfunc.tradew.titem]["cost"]))
  local td = clr
  if gfunc.tradew.titemcount*gfunc.tradew.loaded[gfunc.tradew.sect][gfunc.tradew.titem]["cost"] > CGD[pID]["cash"] then td = 0xb71202 end
  buffer.text(smx+1,smy+5, td, "Стоимость: "..tostring(gfunc.tradew.titemcount*gfunc.tradew.loaded[gfunc.tradew.sect][gfunc.tradew.titem]["cost"])..gfunc.genitiveWordEnding(" монет",gfunc.tradew.titemcount*gfunc.tradew.loaded[gfunc.tradew.sect][gfunc.tradew.titem]["cost"]))
  buffer.square(smx, smy+gfunc.tradew.cHeight, gfunc.tradew.cWidth, 3, 0x0054cb5)
  buffer.text(smx+(gfunc.tradew.cWidth/2-unicode.len(tn)/2), smy+gfunc.tradew.cHeight+1, clr, tn)
  gfunc.drawItemDescription(smx+gfunc.tradew.cWidth+2,smy+1,itemInfo)
  end
 elseif gfunc.tradew.torg == 2 then
  buffer.text(x+2,y+3,0xC2C2C2,"#")
  buffer.text(x+5,y+3,0xC2C2C2,"Наименование")
  buffer.text(x+50,y+3,0xC2C2C2,"Количество")
  buffer.text(x+70,y+3,0xC2C2C2,"Цена за единицу")
  gfunc.tradew.asmt = {}
  for f = 1, #CGD[pID]["inventory"]["bag"] do
   if CGD[pID]["inventory"]["bag"][f][1] ~= 0 and CGD[pID]["inventory"]["bag"][f][2] ~= 0 then
   tableInsert(gfunc.tradew.asmt,CGD[pID]["inventory"]["bag"][f])
   end
  end
  for f = 1, 25 do
  buffer.square(x+1,y+5+f*2-2,85,1,0x8C8C8C)
  end
  for f = 1, #gfunc.tradew.asmt do
  buffer.text(x+2,y+4+f,0xDDDDDD,tostring(f))
  buffer.text(x+5,y+4+f,gid[gfunc.tradew.asmt[f][1]]["ncolor"],"► "..gid[gfunc.tradew.asmt[f][1]]["name"])
  buffer.text(x+50,y+4+f,0xDDDDDD,tostring(gfunc.tradew.asmt[f][2]))
  buffer.text(x+70,y+4+f,0xDDDDDD,gid[gfunc.tradew.asmt[f][1]]["cost"]..gfunc.genitiveWordEnding(" монет",gid[gfunc.tradew.asmt[f][1]]["cost"]))
  end
   if gfunc.tradew.titem > 0 then
   local ttext = "Продать предмет"
   buffer.square(90, 6, 22, 12, 0x828282)
   buffer.image(91, 7, iconImageBuffer[1])
   gfunc.drawItemDescription(91,20,itemInfo)
   buffer.text(118,6,0xffffff,"Количество")
   buffer.square(118, 7, 10, 3, 0x828282)
   buffer.text(119,8,0xffffff,"┼")
   buffer.text(126,8,0xffffff,"—")
   buffer.text(121,9,0xffffff,"Макс.")
   buffer.square(121, 8, 4, 1, 0x717171)
   buffer.text(121,8,0xffffff,tostring(gfunc.tradew.titemcount))
   buffer.square(130, 7, unicode.len(ttext)+2, 3, 0x00447C)
   buffer.text(131,8,0xffffff,ttext)
   end
 end
end

gfunc.tradew.action["touch"] = function(ev)
 if ev[5] == 0 and clicked(ev[3],ev[4],gfunc.tradew.x+gfunc.tradew.w-8,gfunc.tradew.y,gfunc.tradew.x+gfunc.tradew.w-1,gfunc.tradew.y) then
 gfunc.tradew.titem = 0
 gfunc.tradew.titemcount = 1
 gfunc.tradew.sect = 1
 gfunc.tradew.tScrl = 1
 gfunc.tradew.torg = 1
 gfunc.tradew.asmt = {}
 cWindowTrd = nil
 cDialog = nil
 paused = false
 itemInfo = nil
 end
    if ev[5] == 0 and gfunc.tradew.torg == 1 and gfunc.tradew.titem == 0 and clicked(ev[3],ev[4],119,2,136,4) then 
	gfunc.tradew.torg = 2 
	gfunc.tradew.titem = 0
    elseif ev[5] == 0 and gfunc.tradew.torg == 2 and clicked(ev[3],ev[4],119,2,136,4) then
	gfunc.tradew.torg = 1 
	gfunc.tradew.titem = 0
	gfunc.tradew.titemcount = 1
    iconImageBuffer = {}
	end
   if gfunc.tradew.torg == 2 then
    for f = 1, #gfunc.tradew.asmt do
	 if ev[5] == 0 and clicked(ev[3],ev[4],2,5+f,85,5+f) then
	 iconImageBuffer[1] = image.load(dir.."itempic/"..loadedItemIcons[gid[gfunc.tradew.asmt[f][1]]["icon"]]..".pic")
	 itemInfo = gfunc.getItemInfo(gfunc.tradew.asmt[f][1])
	 gfunc.tradew.titem = f
	 gfunc.tradew.titemcount = 1
	 end
	end
	if gfunc.tradew.titem > 0 then
	 if ev[5] == 0 then
	  if clicked(ev[3],ev[4],119,8,119,8) and gfunc.tradew.titemcount < gfunc.tradew.asmt[gfunc.tradew.titem][2] then
	  gfunc.tradew.titemcount = gfunc.tradew.titemcount + 1
	  elseif clicked(ev[3],ev[4],126,8,126,8) and gfunc.tradew.titemcount > 1 then
	  gfunc.tradew.titemcount = gfunc.tradew.titemcount - 1
	  elseif clicked(ev[3],ev[4],121,9,125,9) then
	  gfunc.tradew.titemcount = gfunc.tradew.asmt[gfunc.tradew.titem][2]
	  end
	  if clicked(ev[3],ev[4],130,7,145,9) then
	   for d = 1, #CGD[pID]["inventory"]["bag"] do
		if CGD[pID]["inventory"]["bag"][d][1] == gfunc.tradew.asmt[gfunc.tradew.titem][1] then 
		CGD[pID]["cash"] = CGD[pID]["cash"] + gfunc.tradew.titemcount*gid[gfunc.tradew.asmt[gfunc.tradew.titem][1]]["cost"]
		CGD[pID]["inventory"]["bag"][d][2] = CGD[pID]["inventory"]["bag"][d][2] - gfunc.tradew.titemcount
		for h = 1, #CGD[pID]["inventory"]["bag"] do if CGD[pID]["inventory"]["bag"][h][2] <= 0 then CGD[pID]["inventory"]["bag"][h][1] = 0 end end
		iconImageBuffer = {}
		gfunc.tradew.titem = 0
		gfunc.tradew.titemcount = 1
	    break
		end
	   end
	  end
	 end
	end
   elseif gfunc.tradew.torg == 1 and gfunc.tradew.titem == 0 then
    for c = 1, #gfunc.tradew.loaded do
	 if ev[5] == 0 and clicked(ev[3],ev[4],2+c*26-26, 2, 2+c*25, 2) then
	 gfunc.tradew.sect = c
	 break
	 end
	end
	for c = 1, mathMin(#gfunc.tradew.loaded[gfunc.tradew.sect], 24) do
     if clicked(ev[3],ev[4],2,5+c*2-2,160,5+c*2) then
	 gfunc.tradew.titem = c+4*gfunc.tradew.tScrl-4
	 itemInfo = gfunc.getItemInfo(gfunc.tradew.loaded[gfunc.tradew.sect][gfunc.tradew.titem]["item"])
	 iconImageBuffer = {[1]=image.load(dir.."itempic/"..loadedItemIcons[gid[gfunc.tradew.loaded[gfunc.tradew.sect][gfunc.tradew.titem]["item"]]["icon"]]..".pic")}
	 break
	 end
    end
   elseif gfunc.tradew.torg == 1 and gfunc.tradew.titem > 0 then
    if ev[5] == 0 and gid[gfunc.tradew.loaded[gfunc.tradew.sect][gfunc.tradew.titem]["item"]]["stackable"] and gfunc.tradew.titemcount < 100 and clicked(ev[3],ev[4],gfunc.tradew.twx+13, gfunc.tradew.twy+3,gfunc.tradew.twx+13, gfunc.tradew.twy+3) then -- +
    gfunc.tradew.titemcount = gfunc.tradew.titemcount + 1
    elseif ev[5] == 0 and gfunc.tradew.titemcount > 1 and clicked(ev[3],ev[4],gfunc.tradew.twx+16+#tostring(gfunc.tradew.titemcount), gfunc.tradew.twy+3,gfunc.tradew.twx+16+#tostring(gfunc.tradew.titemcount), gfunc.tradew.twy+3) then -- -
    gfunc.tradew.titemcount = gfunc.tradew.titemcount - 1
    end
    -- купить
	if clicked(ev[3],ev[4],gfunc.tradew.twx,gfunc.tradew.twy+gfunc.tradew.cHeight,gfunc.tradew.twx+gfunc.tradew.cWidth,gfunc.tradew.twy+gfunc.tradew.cHeight+3) and CGD[pID]["cash"] >= gfunc.tradew.titemcount*gfunc.tradew.loaded[gfunc.tradew.sect][gfunc.tradew.titem]["cost"] then
	CGD[pID]["cash"] = CGD[pID]["cash"] - gfunc.tradew.titemcount*gfunc.tradew.loaded[gfunc.tradew.sect][gfunc.tradew.titem]["cost"]
	addItem(gfunc.tradew.loaded[gfunc.tradew.sect][gfunc.tradew.titem]["item"],gfunc.tradew.titemcount)
	gfunc.tradew.titem = 0
	gfunc.tradew.titemcount = 1	
	iconImageBuffer = {}
	end
	-- закрыть
	if clicked(ev[3],ev[4],gfunc.tradew.twx+gfunc.tradew.cWidth-2, gfunc.tradew.twy, gfunc.tradew.twx+gfunc.tradew.cWidth-2, gfunc.tradew.twy) then
	gfunc.tradew.titem = 0
	gfunc.tradew.titemcount = 1
	iconImageBuffer = {}
	end
   end
end

-----------------------------Окно создание------------------------------------------------------

gfunc.craftw = {
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
	cHeight = 15
}

gfunc.craftw.twx = mathFloor(80-gfunc.craftw.cWidth/2)
gfunc.craftw.twy = mathFloor(25-gfunc.craftw.cHeight/2)

function gfunc.craftw.draw()
local x, y = gfunc.craftw.x, gfunc.craftw.y
buffer.square(x, y, gfunc.craftw.w, gfunc.craftw.h, 0x9B9B9B)
buffer.square(x, y, gfunc.craftw.w, 1, 0x525252)
buffer.square(x, y+1, gfunc.craftw.w, 3, 0x747474)
local t = "Создание предметов"
buffer.text(mathMax(80-(unicode.len(t)/2), 0), y, 0xffffff, t)
buffer.text(x+1,y+3,0xC2C2C2,"Наименование")
buffer.text(x+65,y+3,0xC2C2C2,"Шанс создания")
buffer.text(x+130,y+3,0xC2C2C2,"Цена")
buffer.text(x+gfunc.craftw.w-9,y,0xffffff,"Закрыть")
buffer.text(x+1,y+2,0xffffff,"Монеты "..CGD[pID]["cash"])
local t1, hclr
 for f = 1, #gfunc.craftw.loaded do
 t1 = unicode.sub(gfunc.craftw.loaded[f]["s_name"],1,25)
 if gfunc.craftw.sect == f then hclr = 0x525252 else hclr = 0x606060 end
 buffer.square(x+1+f*26-26, y+1, 25, 1, hclr)
 buffer.text(x+1+f*26-26, y+1, 0xCCCCCC, t1)
 end
 for f = 1, mathMin(#gfunc.craftw.loaded[gfunc.craftw.sect], 24) do
 if f+4*gfunc.craftw.tScrl-4 == gfunc.craftw.titem then buffer.square(x+1,y+4+f*2-2, 160, 3, 0x818181) end
 end
  for f = 1, mathMin(#gfunc.craftw.loaded[gfunc.craftw.sect]+1, 24) do
   buffer.text(x+1,y+4+f*2-2,0xffffff,"═")
   buffer.text(x+2,y+4+f*2-2,0xffffff,string.rep("─",157))
  end
 for f = 1, mathMin(#gfunc.craftw.loaded[gfunc.craftw.sect], 24) do
 buffer.text(x+1,y+4+f*2-1,0xffffff,gid[gfunc.craftw.loaded[gfunc.craftw.sect][f+4*gfunc.craftw.tScrl-4]["item"]]["name"])
 buffer.text(x+65,y+4+f*2-1,0xffffff,tostring(gfunc.craftw.loaded[gfunc.craftw.sect][f+4*gfunc.craftw.tScrl-4]["chance"]).."%")
 buffer.text(x+130,y+4+f*2-1,0xffffff,tostring(gfunc.craftw.loaded[gfunc.craftw.sect][f+4*gfunc.craftw.tScrl-4]["cost"])..gfunc.genitiveWordEnding(" монет",gfunc.craftw.loaded[gfunc.craftw.sect][f+4*gfunc.craftw.tScrl-4]["cost"]))
 end
 if gfunc.craftw.titem ~= 0 then
 local clr, smx, smy = 0xCCCCCC, gfunc.craftw.twx, gfunc.craftw.twy
 buffer.square(smx, smy, gfunc.craftw.cWidth, gfunc.craftw.cHeight, 0x828282)
 gfunc.unicodeframe(smx, smy, gfunc.craftw.cWidth, gfunc.craftw.cHeight, 0x4c4c4c)
 buffer.square(smx-23, smy, 22, 12, 0x828282)
 buffer.image(smx-22, smy+1, iconImageBuffer[1])
 buffer.text(smx+gfunc.craftw.cWidth-2, smy, 0x4c4c4c, "X")
 buffer.text(smx+(mathFloor(gfunc.craftw.cWidth/2-unicode.len(gid[gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["item"]]["name"])/2)), smy+1, clr, gid[gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["item"]]["name"])
 buffer.text(smx+1,smy+2, clr, "Создание предмета")
 buffer.text(smx+1,smy+3, clr, "Количество:")
 buffer.square(smx+13, smy+3, #tostring(gfunc.craftw.titemcount)+4, 1, 0x616161)
 buffer.text(smx+13,smy+3, clr, "+ "..gfunc.craftw.titemcount.." -")
 local td
 if gfunc.craftw.titemcount*gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["cost"] <= CGD[pID]["cash"] then td = clr else td = 0xb71202 end
 buffer.text(smx+1,smy+4, td, "Стоимость: "..tostring(gfunc.craftw.titemcount*gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["cost"])..gfunc.genitiveWordEnding(" монет",gfunc.craftw.titemcount*gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["cost"]))
 buffer.text(smx+1,smy+5, clr, "Шанс создания: "..gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["chance"].."%")
 buffer.text(smx+1,smy+6, clr, "Шанс улучшения: "..tostring(gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["achance"]).."%")
 buffer.text(smx+1,smy+7, clr, "Требуются предметы:")
 local tcl, tcc = nil, 0
  for i = 1, mathMin(#gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["recipe"], 5) do
  if checkItemInBag(gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["recipe"][i][1]) >= gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["recipe"][i][2]*gfunc.craftw.titemcount then tcl = 0xdcdcdc; tcc = tcc + 1 else tcl = 0x575757 end
  buffer.text(smx+1,smy+7+i, tcl, "▸"..gid[gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["recipe"][i][1]]["name"].." ("..gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["recipe"][i][2]*gfunc.craftw.titemcount..")")
  end
 tcl = 0x0054cb5
 if #gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["recipe"] > tcc or td == 0xb71202 then tcl = 0x7B7B7B end
 buffer.square(smx, smy+gfunc.craftw.cHeight, gfunc.craftw.cWidth, 3, tcl)
 buffer.text(smx+18, smy+gfunc.craftw.cHeight+1, clr, "Создать предмет")
 gfunc.drawItemDescription(smx+gfunc.craftw.cWidth+2,smy+1,itemInfo)
 end
end

gfunc.craftw.action["touch"] = function(ev)
 if ev[5] == 0 and clicked(ev[3],ev[4],gfunc.craftw.x+gfunc.craftw.w-8,gfunc.craftw.y,gfunc.craftw.x+gfunc.craftw.w-1,gfunc.craftw.y) then
 gfunc.craftw.titem = 0
 gfunc.craftw.titemcount = 1
 gfunc.craftw.sect = 1
 gfunc.craftw.tScrl = 1
 cWindowTrd = nil
 cDialog = nil
 paused = false
 itemInfo = nil
 end  
   if gfunc.craftw.titem == 0 then
    for c = 1, #gfunc.craftw.loaded do
	 if ev[5] == 0 and clicked(ev[3],ev[4],2+c*26-26, 2, 2+c*25, 2) then
	 gfunc.craftw.sect = c
	 break
	 end
	end
	for c = 1, mathMin(#gfunc.craftw.loaded[gfunc.craftw.sect], 24) do
     if clicked(ev[3],ev[4],2,5+c*2-2,160,5+c*2) then
	 gfunc.craftw.titem = c+4*gfunc.tradew.tScrl-4
	 itemInfo = gfunc.getItemInfo(gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["item"])
	 iconImageBuffer[1] = image.load(dir.."itempic/"..loadedItemIcons[gid[gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["item"]]["icon"]]..".pic") 
	 break
	 end
    end
   else
    if ev[5] == 0 and gid[gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["item"]]["stackable"] and gfunc.craftw.titemcount < 100 and clicked(ev[3],ev[4],gfunc.craftw.twx+13, gfunc.craftw.twy+3,gfunc.craftw.twx+13, gfunc.craftw.twy+3) then
    gfunc.craftw.titemcount = gfunc.craftw.titemcount + 1
    elseif ev[5] == 0 and gfunc.craftw.titemcount > 1 and clicked(ev[3],ev[4],gfunc.craftw.twx+16+#tostring(gfunc.craftw.titemcount), gfunc.craftw.twy+3,gfunc.craftw.twx+16+#tostring(gfunc.craftw.titemcount), gfunc.craftw.twy+3) then
    gfunc.craftw.titemcount = gfunc.craftw.titemcount - 1
    end
    if clicked(ev[3],ev[4],gfunc.craftw.twx,gfunc.craftw.twy+gfunc.craftw.cHeight,gfunc.craftw.twx+gfunc.craftw.cWidth,gfunc.craftw.twy+gfunc.craftw.cHeight+3) and CGD[pID]["cash"] >= gfunc.craftw.titemcount*gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["cost"] then
	 -- нажатие на кнопку 'создать предмет'
	 checkVar1 = true
	 for i = 1, #gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["recipe"] do
	  if checkItemInBag(gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["recipe"][i][1]) < gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["recipe"][i][2]*gfunc.craftw.titemcount then
	  checkVar1 = false
	  end
	 end
	if gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["cost"] > CGD[pID]["cash"] then checkVar1 = false end
	 if checkVar1 then
	  for d = 1, #gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["recipe"] do
	   for i = 1, #CGD[pID]["inventory"]["bag"] do
	    if CGD[pID]["inventory"]["bag"][i][1] == gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["recipe"][d][1] then
	    CGD[pID]["inventory"]["bag"][i][2] = CGD[pID]["inventory"]["bag"][i][2] - gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["recipe"][d][2]*gfunc.craftw.titemcount
	    if CGD[pID]["inventory"]["bag"][i][2] == 0 then CGD[pID]["inventory"]["bag"][i][1] = 0 end
		break
		end
	   end
	  end
	 for d = 1, gfunc.craftw.titemcount do
	  Citem = gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["item"]
	  CGD[pID]["cash"] = CGD[pID]["cash"] - gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["cost"]
       if Citem ~= nil and 10^10-gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["chance"]*10^10 <= gfunc.random(1,10^10) then
       if 10^10-(gfunc.craftw.loaded[gfunc.craftw.sect][gfunc.craftw.titem]["achance"] or 0)*10^10 <= gfunc.random(1,10^10) then Citem = createNewItem(Citem) end
       addItem(Citem,1)
	   end
	  Citem = nil
	  end
	 gfunc.craftw.titem = 0
	 gfunc.craftw.titemcount = 1	 
	 iconImageBuffer = {}
	 end
	end
	if clicked(ev[3],ev[4],gfunc.craftw.twx+gfunc.craftw.cWidth-2, gfunc.craftw.twy,gfunc.craftw.twx+gfunc.craftw.cWidth-2, gfunc.craftw.twy) then
	gfunc.craftw.titem = 0
	gfunc.craftw.titemcount = 1
	iconImageBuffer = {}
	end
   end
end

-----------------------------Окно "YOU DEAD"------------------------------------------------------

gfunc.ydw = {
	w=40,
	h=24,
	action={},
	[1]={
		"Продолжить",
		f=function()
		local xpdec = mathFloor(CGD[pID]["mxp"]*gfunc.random(2*(10/math.sqrt(CGD[pID]["lvl"]))*100,5*(10/math.sqrt(CGD[pID]["lvl"]))*100)*0.0001)
		 for f=1,#CGD[pID]["inventory"]["bag"] do
		  if gfunc.random(0,100) <= 1 then
		  CGD[pID]["inventory"]["bag"][f][2] = 0
		  end
		 end
		gfunc.loadWorld(world[world.current].drespawn)
		gfunc.teleport(world[world.current].drx)
		gfunc.playerRV()
		CGD[pID]["chp"] = CGD[pID]["mhp"]
		CGD[pID]["cmp"] = CGD[pID]["mmp"]
		 if CGD[pID]["cxp"] > xpdec then
		 CGD[pID]["cxp"] = CGD[pID]["cxp"] - xpdec
		 end
		CGD[pID]["living"] = true
		cWindowTrd = nil
		paused = false
		end
		}
}

function gfunc.ydw.draw()
paused = true
cTarget = 0
cWindowTrd = "gfunc.ydw"
buffer.square(1, 1, 160, 50, 0x6B6B6B, nil, nil, 40)
local x, y = 160/2-gfunc.ydw.w/2, 50/2-gfunc.ydw.h/2
buffer.square(x, y, gfunc.ydw.w, gfunc.ydw.h, 0x7B7B7B, nil, nil, 25)
buffer.square(x-1, y+1, 1, gfunc.ydw.h-2, 0x7B7B7B, nil, nil, 25)
buffer.square(x+gfunc.ydw.w, y+1, 1, gfunc.ydw.h-2, 0x7B7B7B, nil, nil, 25)
local ydwTitle = "Персонаж помер"
buffer.text(x+gfunc.ydw.w/2-unicode.len(ydwTitle)/2,y+1,0xFCFCFC,ydwTitle)
 for f = 1, #gfunc.ydw do
 buffer.text(x+gfunc.ydw.w/2-unicode.len(gfunc.ydw[f][1])/2,y+2+f,0xCCCCCC,gfunc.ydw[f][1])
 end
end

gfunc.ydw.action["touch"] = function(ev)
 for e = 1, #gfunc.ydw do
  if clicked(ev[3],ev[4],160/2-gfunc.ydw.w/2,50/2-gfunc.ydw.h/2+2+e,160/2-gfunc.ydw.w/2+gfunc.ydw.w-1,50/2-gfunc.ydw.h/2+2+e) then
  pcall(gfunc.ydw[e].f)
  end
 end
end
   
-----------------------------Console window------------------------------------------------------

local cCnsScroll = 1

gfunc.gameConsole = {x=50,y=10,w=60,h=35,action={}}

function gfunc.gameConsole.draw()
local x, y, w, h = gfunc.gameConsole.x, gfunc.gameConsole.y, gfunc.gameConsole.w, gfunc.gameConsole.h
buffer.square(x, y, w, h, 0xABABAB)
buffer.square(x, y, w, 1, 0x525252)
buffer.square(x+1, y+1, w-2, h-4, 0x1A1A1A)
buffer.square(x+1, y+33, w-2, 1, 0x1A1A1A)
local bColor, bSub
local text1 = "debug"
buffer.text(x+(mathMax(mathFloor((w / 2) - (unicode.len(text1) / 2)), 0)), y, 0xffffff, text1)
buffer.text(x+59,y,0xffffff,"X")
 for f = 1, mathMin(#consoleArray,h-7) do
  if consoleArray[f+(cCnsScroll*4-4)] then
   if unicode.sub(consoleArray[f+(cCnsScroll*4-4)],1,2) == "!/" then 
   bColor = 0xFF0000
   bSub = 3
   else
   bColor = 0xffffff
   bSub = 1
   end
  buffer.text(x+2,y+2+f,bColor,unicode.sub(consoleArray[f+(cCnsScroll*4-4)],bSub,w-4))
  end
 end
end

gfunc.gameConsole.action["touch"] = function(ev)
 if ev[5] == 0 and clicked(ev[3],ev[4],gfunc.gameConsole.x+gfunc.gameConsole.w-1,gfunc.gameConsole.y,gfunc.gameConsole.x+gfunc.gameConsole.w-1,gfunc.gameConsole.y) then
 cWindowTrd = nil
 paused = false
 end
end

gfunc.gameConsole.action["scroll"] = function(ev)
local x, y, w, h = gfunc.gameConsole.x, gfunc.gameConsole.y, gfunc.gameConsole.w, gfunc.gameConsole.h
 if clicked(ev[3],ev[4],x,y,x+w-1,y+h-3) and ev[5] == 1 and cCnsScroll > 1 then
 cCnsScroll = cCnsScroll - 1
 elseif clicked(ev[3],ev[4],x,y,x+w-1,y+h-3) and ev[5] == -1 and mathCeil(cCnsScroll*4) < #consoleArray then
 cCnsScroll = cCnsScroll + 1
 end
end

gfunc.gameConsole.action["key_down"] = function(ev)
 if not paused and ev[4] == 46 then
 paused = true
 cCnsScroll = mathFloor(#consoleArray/4)
 cWindowTrd = "console"
 end
end

-----------------------------Окно список заданий------------------------------------------------------

gfunc.questsList = {x=30,y=12,w=100,h=30,action={}}

function gfunc.questsList.draw()
local x, y = gfunc.questsList.x, gfunc.questsList.y
buffer.square(x, y, 100, 30, 0xABABAB)
buffer.square(x, y, 100, 1, 0x525252)
buffer.text(x+45,y,0xffffff,"Задания")
buffer.text(x+92,y,0xffffff,"Закрыть")
buffer.square(x+2, y+2, 29, 27, 0x7A7A7A)
buffer.square(x+32, y+2, 66, 27, 0x7A7A7A)
 for f = 1, mathMin(#cUquests,25) do
 if cUquests[f][3] then buffer.text(x+2,y+2+f,0x00C222,"→") end
 buffer.text(x+3,y+2+f,0xDDDDDD,unicode.sub(gqd[cUquests[f][1]]["name"],1,28))
 end
 if targetQuest > 0 and cUquests[targetQuest] ~= nil then
 local qDeskList = {}
 local dstr = gfunc.textWrap(gqd[cUquests[targetQuest][1]]["descr"],63)
  for i = 1, #dstr do
  tableInsert(qDeskList, dstr[i])
  end
 local qInfoList = {}
  if gqd[cUquests[targetQuest][1]]["qreward"] then
  qInfoList = {
	"Награда:",
	"Монеты "..tostring(gqd[cUquests[targetQuest][1]]["qreward"]["coins"]),
	"Опыт "..tostring(gqd[cUquests[targetQuest][1]]["qreward"]["xp"]),
	}
  end
  tableInsert(qInfoList,1,"Описание:")
  for i = 1, #qDeskList do
   if qDeskList[i] ~= nil and qDeskList[i] ~= "" then
   tableInsert(qInfoList,i+1,qDeskList[i])
   end
  end

  -- q kill
  if gqd[cUquests[targetQuest][1]]["type"] == "k" then
   if type(gqd[cUquests[targetQuest][1]]["targ"]) == "number" then
   tableInsert(qInfoList,1,"► "..gud[gqd[cUquests[targetQuest][1]]["targ"]]["name"].." ("..cUquests[targetQuest][2].."/"..gqd[cUquests[targetQuest][1]]["num"]..")")
   else
    for j = 1, #gqd[cUquests[targetQuest][1]]["targ"] do
	tableInsert(qInfoList,1,"► "..gud[gqd[cUquests[targetQuest][1]]["targ"][j]]["name"].." ("..cUquests[targetQuest][2][j].."/"..gqd[cUquests[targetQuest][1]]["num"][j]..")")
	end
   end
  tableInsert(qInfoList,1,"Уничтожить: ")
  -- q find
  elseif gqd[cUquests[targetQuest][1]]["type"] == "f" then
   if type(gqd[cUquests[targetQuest][1]]["targ"][1]) == "number" then
   tableInsert(qInfoList,1,"► "..gid[gqd[cUquests[targetQuest][1]]["targ"]]["name"].." ("..cUquests[targetQuest][2].."/"..gqd[cUquests[targetQuest][1]]["num"]..")")
   else
    for j = 1, #gqd[cUquests[targetQuest][1]]["targ"] do
	tableInsert(qInfoList,1,"► "..gid[gqd[cUquests[targetQuest][1]]["targ"][j][1]]["name"].." ("..cUquests[targetQuest][2][j].."/"..gqd[cUquests[targetQuest][1]]["targ"][j][2]..")")
	end
   end
  tableInsert(qInfoList,1,"Найти предметы: ")
  end
   if gqd[cUquests[targetQuest][1]]["qr"] > 0 then
   tableInsert(qInfoList,1,"Задание закончено: "..gud[gqd[cUquests[targetQuest][1]]["qr"]]["name"])
   else
   tableInsert(qInfoList,1,"Задание закончено: автоматически")
   end
   if gqd[targetQuest]["qstgve"] then
   tableInsert(qInfoList,1,"Задание выдано: "..gud[gqd[cUquests[targetQuest][1]]["qstgve"]]["name"])
   end
  if gqd[cUquests[targetQuest][1]]["qreward"] and gqd[cUquests[targetQuest][1]]["qreward"]["item"] ~= nil then
  tableInsert(qInfoList,"Предмет:")
   for o = 1, #gqd[cUquests[targetQuest][1]]["qreward"]["item"] do
   tableInsert(qInfoList,unicode.sub(gid[gqd[cUquests[targetQuest][1]]["qreward"]["item"][o][1]]["name"].." ("..tostring(gqd[cUquests[targetQuest][1]]["qreward"]["item"][o][2])..")",1,45))
   end
  end
 local ub = ""
 if gqd[cUquests[targetQuest][1]]["repeat"] then ub = " (Повторяемое)" end
 buffer.text(x+33,y+3,0xffffff,unicode.sub(gqd[cUquests[targetQuest][1]]["name"]..ub,1,60))
  for f = 1, #qInfoList do
  buffer.text(x+33,y+3+f,0xffffff,qInfoList[f])
  end
 end
end

gfunc.questsList.action["touch"] = function(ev)
 if ev[5] == 0 and clicked(ev[3],ev[4],122,gfunc.questsList.y,129,gfunc.questsList.y) then
 cWindowTrd = "pause"
 end
 for f = 1, #cUquests do
  if cUquests[f] ~= nil and clicked(ev[3],ev[4],gfunc.questsList.x+3,gfunc.questsList.y+2+f,gfunc.questsList.x+30,gfunc.questsList.y+2+f) then
  someVar1 = false
  targetQuest = f
  break
  end
 if not someVar1 then targetQuest = 0 end
 end
end

-----------------------------Окно инфо о п------------------------------------------------------

gfunc.playerStats = {x=50,y=12,w=60,h=25,cPoints = {0,0,0,0},action={}}

function gfunc.playerStats.draw()
local x, y = gfunc.playerStats.x, gfunc.playerStats.y
buffer.square(x, y, gfunc.playerStats.w, gfunc.playerStats.h, 0xABABAB)
buffer.square(x, y, gfunc.playerStats.w, 1, 0x525252)
local someText = "Персонаж"
buffer.text(x+(mathMax(gfunc.playerStats.w/2-(unicode.len(someText)/2),0)),y,0xffffff,someText)
buffer.text(x+gfunc.playerStats.w-8,y,0xffffff,"Закрыть")
local info1 = {
	"Имя персонажа: "..gud[CGD[pID]["id"]]["name"],
	"Уровень: "..CGD[pID]["lvl"],
	"Здоровье: "..mathFloor(CGD[pID]["chp"]).."/"..mathFloor(CGD[pID]["mhp"]),
	"Мана: "..mathFloor(CGD[pID]["cmp"]).."/"..mathFloor(CGD[pID]["mmp"]),
	"Опыт: "..CGD[pID]["cxp"].."/"..CGD[pID]["mxp"].." ("..tostring(mathFloor(CGD[pID]["cxp"]*100/CGD[pID]["mxp"]*10)/10).."%)",
	"Физическая атака: "..CGD[pID]["ptk"][1].."-"..CGD[pID]["ptk"][2].." ("..mathCeil((vaddsPnts.vPdm1+vaddsPnts.vPdm2)/2).." от снаряжения)",
	"Магическая атака: "..CGD[pID]["mtk"][1].."-"..CGD[pID]["mtk"][2].." ("..mathCeil((vaddsPnts.vMdm1+vaddsPnts.vMdm2)/2).." от снаряжения)",
	"Физическая защита: "..CGD[pID]["pdef"].." ("..CGD[pID]["armorpdef"].." от снаряжения)",
	"Магическая защита: "..CGD[pID]["mdef"].." ("..CGD[pID]["armormdef"].." от снаряжения)",
	"Скорость атаки: "..tostring(mathCeil((1/gsd[1]["reloading"])*10)/10),
	"Вероятность нанесения критического удара: "..CGD[pID]["criticalhc"].."%",
}
 for f = 1, #info1 do
 buffer.text(x+3,y+1+f,0xffffff,info1[f])
 end
gfunc.playerStats.x1, gfunc.playerStats.y1 = x+3, y+14 
buffer.square(x+3, y+14, 37, 4, 0x898989)
buffer.text(x+4,y+14,0xffffff,"Очков для распределения "..CGD[pID]["levelpoints"])
buffer.text(x+4,y+15,0xEEEEEE,"Магия")
buffer.text(x+17,y+15,0xCECECE,tostring(CGD[pID]["intelligence"]+gfunc.playerStats.cPoints[1]+vaddsPnts.vInt))
buffer.text(x+4,y+16,0xEEEEEE,"Сила")
buffer.text(x+17,y+16,0xCECECE,tostring(CGD[pID]["strength"]+gfunc.playerStats.cPoints[2]+vaddsPnts.vStr))
buffer.text(x+4,y+17,0xEEEEEE,"Выносливость")
buffer.text(x+17,y+17,0xCECECE,tostring(CGD[pID]["survivability"]+gfunc.playerStats.cPoints[3]+vaddsPnts.vSur))
 for f = 1, 3 do
 buffer.square(x+20, y+14+f, 3, 1, 0x727272)
 buffer.text(x+21,y+14+f,0xEEEEEE,"+")
 buffer.square(x+24, y+14+f, 3, 1, 0x727272)
 buffer.text(x+25,y+14+f,0xEEEEEE,"-")
 end
 buffer.square(x+28, y+15, 9, 1, 0x737373)
 buffer.text(x+28,y+15,0xEEEEEE,"→Принять")
 buffer.square(x+28, y+17, 9, 1, 0x737373)
 buffer.text(x+28,y+17,0xEEEEEE,"×отменить")
end

gfunc.playerStats.action["touch"] = function(ev)
if ev[5] == 0 and clicked(ev[3],ev[4],gfunc.playerStats.x+gfunc.playerStats.w-8,gfunc.playerStats.y,gfunc.playerStats.x+gfunc.playerStats.w-1,gfunc.playerStats.y) then cWindowTrd = "pause" end
 for t = 1, 3 do
  if ev[5] == 0 and CGD[pID]["levelpoints"] > 0 and clicked(ev[3],ev[4],gfunc.playerStats.x1+17,gfunc.playerStats.y1+t,gfunc.playerStats.x1+20,gfunc.playerStats.y1+t) then
  gfunc.playerStats.cPoints[t] = gfunc.playerStats.cPoints[t] + 1
  CGD[pID]["levelpoints"] = CGD[pID]["levelpoints"] - 1
  gfunc.playerStats.cPoints[4] = gfunc.playerStats.cPoints[4] + 1
  elseif ev[5] == 0 and CGD[pID]["levelpoints"] > 0 and clicked(ev[3],ev[4],gfunc.playerStats.x1+22,gfunc.playerStats.y1+t,gfunc.playerStats.x1+25,gfunc.playerStats.y1+t) and gfunc.playerStats.cPoints[t] > 0 then
  gfunc.playerStats.cPoints[t] = gfunc.playerStats.cPoints[t] - 1
  CGD[pID]["levelpoints"] = CGD[pID]["levelpoints"] + 1
  gfunc.playerStats.cPoints[4] = gfunc.playerStats.cPoints[4] - 1	
  end
 end
 if ev[5] == 0 and clicked(ev[3],ev[4],gfunc.playerStats.x1+28,gfunc.playerStats.y1+1,gfunc.playerStats.x1+34,gfunc.playerStats.y1+1) then
 CGD[pID]["intelligence"] = CGD[pID]["intelligence"] + gfunc.playerStats.cPoints[1]
 CGD[pID]["strength"] = CGD[pID]["strength"] + gfunc.playerStats.cPoints[2]
 CGD[pID]["survivability"] = CGD[pID]["survivability"] + gfunc.playerStats.cPoints[3]
 gfunc.playerStats.cPoints = {0,0,0,0}
 gfunc.playerRV()
 elseif ev[5] == 0 and gfunc.playerStats.cPoints[4] > 0 and clicked(ev[3],ev[4],gfunc.playerStats.x1+28,gfunc.playerStats.y1+3,gfunc.playerStats.x1+34,gfunc.playerStats.y1+3) then
 CGD[pID]["levelpoints"] = CGD[pID]["levelpoints"] + gfunc.playerStats.cPoints[4]
 gfunc.playerStats.cPoints = {0,0,0,0}
 gfunc.playerRV()
 end
end

-----------------------------Окно список умений------------------------------------------------------

function gfunc.pSkillsPbar(x,y,number)
buffer.square(x, y, 46, 4, 0x8c8c8c)
local c
 for f = 1, 7 do
 c = 0x00CA85
  if f > number + 1 then c = 0xAAAAAA 
  elseif f == number + 1 then c = 0x0085CA
  end
 buffer.square(x+2+f*6-6, y+1, 5, 2, c)
 end
end

local stypes = {
["attack"] = "Атака",
["buff"] = "Бафф",
["passive"] = "Пассивный",
}

gfunc.playerSkills = {x=20,y=5,w=120,h=40,targ=0,action={}}

function gfunc.playerSkills.draw()
local x, y = gfunc.playerSkills.x, gfunc.playerSkills.y
buffer.square(x, y, gfunc.playerSkills.w, gfunc.playerSkills.h, 0xABABAB)
buffer.square(x, y, gfunc.playerSkills.w, 1, 0x525252)
buffer.text(x+57,y,0xffffff,"Умения")
buffer.text(x+112,y,0xffffff,"Закрыть")
buffer.square(x+1, y+2, 50, gfunc.playerSkills.h-3, 0x919191)
gfunc.playerRV()
local cnm = ""
local ntt, kfc, blbl, abc, rv
 for f = 1, #cPlayerSkills do
 if f == gfunc.playerSkills.targ then buffer.square(x+1, y+2+f*3-3, 50, 3, 0xABABAB); buffer.square(x+51, y+3+f*3-3, 1, 1, 0x919191); buffer.square(x+52, y+2+f*3-3, 1, 3, 0x919191) end
 cnm = gsd[cPlayerSkills[f][1]]["name"].." ("..cPlayerSkills[f][3].." ур.)"
 buffer.text(x+mathFloor(25-unicode.len(cnm)/2),y+3+f*3-3,0xffffff,cnm)
 end
buffer.square(x+53, y+2, 50, 37, 0x919191)
 if gfunc.playerSkills.targ ~= 0 then
 local slvl = mathMax(cPlayerSkills[gfunc.playerSkills.targ][3],1)
 blbl = gsd[cPlayerSkills[gfunc.playerSkills.targ][1]] 
  if ( blbl["type"] == "passive" and cPlayerSkills[gfunc.playerSkills.targ][3] < 7 ) or cPlayerSkills[gfunc.playerSkills.targ][3] < #blbl["manacost"] then
   buffer.square(x+55, y+30, 46, 8, 0xA3A3A3)
   local buben = {
   {"Улучшение умения • следующий уровень "..cPlayerSkills[gfunc.playerSkills.targ][3]+1,0xEFEFEF}
   }
   if blbl["reqlvl"] then
   tableInsert(buben,{"Требуемый уровень: "..blbl["reqlvl"][cPlayerSkills[gfunc.playerSkills.targ][3]+1],0xEFEFEF})
   if blbl["reqlvl"][cPlayerSkills[gfunc.playerSkills.targ][3]+1] > CGD[pID]["lvl"] then buben[#buben][2] = 0xEE1414 end
   end
   if blbl["reqcn"] then
   tableInsert(buben,{"Стоимость улучшения: "..blbl["reqcn"][cPlayerSkills[gfunc.playerSkills.targ][3]+1].." монет",0xEFEFEF})
   if blbl["reqcn"][cPlayerSkills[gfunc.playerSkills.targ][3]+1] > CGD[pID]["cash"] then buben[#buben][2] = 0xEE1414 end
   end
   if blbl["reqitem"] then
   tableInsert(buben,{"Требуемый предмет: "..gid[blbl["reqitem"][cPlayerSkills[gfunc.playerSkills.targ][3]+1][1]]["name"].."("..checkItemInBag(blbl["reqitem"][cPlayerSkills[gfunc.playerSkills.targ][3]+1][1]).."/"..blbl["reqitem"][cPlayerSkills[gfunc.playerSkills.targ][3]+1][2]..")",0xEFEFEF})
   if checkItemInBag(blbl["reqitem"][cPlayerSkills[gfunc.playerSkills.targ][3]+1][1]) < blbl["reqitem"][cPlayerSkills[gfunc.playerSkills.targ][3]+1][2] then buben[#buben][2] = 0xEE1414 end
   end
   for f = 1, #buben do
   buffer.text(x+57,y+30+f,buben[f][2],tostring(buben[f][1]))
   end
   abc = "Изучить умение"
   buffer.square(x+70, y+35, unicode.len(abc)+2, 3, 0x077DAC)
   buffer.text(x+71,y+36,0xCECECE,abc)
  end

 kfc = {["p"]="физического",["m"]="магического"}
 rv = {}
  if blbl["value"] then rv[1] = blbl["value"][slvl] else rv[1] = "" end
  if blbl["bseatckinc"] then rv[2] = blbl["bseatckinc"][slvl] else rv[2] = "" end
  if type(blbl["basedmgmlt"]) == "table" then rv[3] = blbl["basedmgmlt"][slvl]
  elseif type(blbl["basedmgmlt"]) == "number" then rv[3] = blbl["basedmgmlt"]
  else rv[3] = "" end
  if blbl["weapondmgmlt"] then rv[4] = blbl["weapondmgmlt"][slvl] else rv[4] = "" end
  if blbl["eff"] and ged[blbl["eff"]]["dur"] then rv[5] = ged[blbl["eff"]]["dur"][slvl] else rv[5] = "" end
  if blbl["eff"] and ged[blbl["eff"]]["val"] then rv[6] = math.abs(ged[blbl["eff"]]["val"][slvl]) else rv[6] = "" end
 slvl = cPlayerSkills[gfunc.playerSkills.targ][3]
 ntt = {
 ["a"]=kfc[blbl["typedm"]],
 ["b"]=rv[1],
 ["c"]=rv[2],
 ["i"]=rv[3],
 ["e"]=rv[4],
 ["d"]=rv[5],
 ["v"]=rv[6],
 }
 
 gfunc.pSkillsPbar(x+55,y+25,slvl)
 buffer.text(x+54,y+3,0xffffff,"•"..blbl["name"])
 buffer.text(x+54,y+4,0xffffff,"Тип: "..stypes[blbl["type"]])
  if slvl > 0 and ( blbl["type"] == "attack" or blbl["type"] == "buff" ) then
  buffer.text(x+54,y+5,0xffffff,"Уровень умения: "..slvl.." / "..#blbl["manacost"])
  buffer.text(x+54,y+6,0xffffff,"Использует маны: "..blbl["manacost"][slvl].." ед.")
  buffer.text(x+54,y+7,0xffffff,"Перезарядка: "..blbl["reloading"].." сек.")
   if blbl["type"] == "attack" then
   buffer.text(x+54,y+8,0xffffff,"Дальность: "..(blbl["distance"]+(vAttackDistance or 8)))
   end
  elseif slvl > 0 and blbl["type"] == "passive" then
  buffer.text(x+54,y+5,0xffffff,"Уровень умения: "..slvl.." / "..#blbl["value"])
  else
  buffer.text(x+54,y+5,0xCCCCCC,"Умение ещё не изучено")
  end
  abc = ""
  rv = 1
   for m = 1, unicode.len(blbl["descr"]) do
    if unicode.sub(blbl["descr"],rv,rv) ~="$" then 
	abc = abc..unicode.sub(blbl["descr"],rv,rv)
	rv = rv+1
    else
	abc = abc..tostring(ntt[unicode.sub(blbl["descr"],rv+1,rv+1)])
	rv = rv+2
	end
   end
  local cbc = gfunc.textWrap(abc,42)
   for f = 1, #cbc do
   buffer.text(x+54,y+9+f,0xffffff,tostring(cbc[f]))
   end
 buffer.text(x+105,y+3,0xffffff,"Установить")
 buffer.text(x+105,y+4,0xffffff,"на клавишу…")
  for p = 1, #gfunc.skillsTopPanel.t do
  slvl = gfunc.skillsTopPanel.t[p].c
   for n = 1, #cUskills do
   if cPlayerSkills[gfunc.playerSkills.targ][1] == cUskills[p+1] then slvl = 0xBBBBBB; break end
   end
  buffer.square(x+105, 6+y+4*p-4, 10, 3, slvl)
  buffer.text(x+109,6+y+4*p-3,0xffffff,tostring(p+1))
  end
 end
end

gfunc.playerSkills.action["touch"] = function(ev)
  if clicked(ev[3],ev[4],gfunc.playerSkills.x+112,gfunc.playerSkills.y,gfunc.playerSkills.x+119,gfunc.playerSkills.y) then cWindowTrd = "pause" end
   for e = 1, #cPlayerSkills do
    if ev[5] == 0 and clicked(ev[3],ev[4],gfunc.playerSkills.x+1, gfunc.playerSkills.y+2+e*3-3, gfunc.playerSkills.x+50, gfunc.playerSkills.y+2+e*3) then
    gfunc.playerSkills.targ = e
    end
   end
   if gfunc.playerSkills.targ > 0 then
    if ev[5] == 0 and clicked(ev[3],ev[4],gfunc.playerSkills.x+70,gfunc.playerSkills.y+35,gfunc.playerSkills.x+84,gfunc.playerSkills.y+37) and ( ( gsd[cPlayerSkills[gfunc.playerSkills.targ][1]]["type"] == "passive" and cPlayerSkills[gfunc.playerSkills.targ][3] < 7 ) or cPlayerSkills[gfunc.playerSkills.targ][3] < #gsd[cPlayerSkills[gfunc.playerSkills.targ][1]]["manacost"] ) then
    blbl, checkv1, checkv2 = gsd[cPlayerSkills[gfunc.playerSkills.targ][1]], true, {}
	 if blbl["reqlvl"] then
	  if blbl["reqlvl"][cPlayerSkills[gfunc.playerSkills.targ][3]+1] > CGD[pID]["lvl"] then 
	  checkv1 = false 
	  end	 
	 end
	 if blbl["reqcn"] then
	  if blbl["reqcn"][cPlayerSkills[gfunc.playerSkills.targ][3]+1] > CGD[pID]["cash"] then 
	  checkv1 = false 
	  else
	  checkv2.c = true
	  end	 
	 end
	 if blbl["reqitem"] then
	  if checkItemInBag(blbl["reqitem"][cPlayerSkills[gfunc.playerSkills.targ][3]+1][1]) < blbl["reqitem"][cPlayerSkills[gfunc.playerSkills.targ][3]+1][2] then
	  checkv1 = false 
	  else
	  checkv2.o, checkv2.i = checkItemInBag(blbl["reqitem"][cPlayerSkills[gfunc.playerSkills.targ][3]+1][1])
	  end	 
	 end
	 if checkv1 == true then
	  if checkv2.c then CGD[pID]["cash"] = CGD[pID]["cash"] - blbl["reqcn"][cPlayerSkills[gfunc.playerSkills.targ][3]+1] end
	  if checkv2.i then
	   for y = 1, #CGD[pID]["inventory"]["bag"] do
	    if CGD[pID]["inventory"]["bag"][y][1] == checkv2.i and CGD[pID]["inventory"]["bag"][y][2] >= checkv2.o then
		CGD[pID]["inventory"]["bag"][y][2] = CGD[pID]["inventory"]["bag"][y][2] - blbl["reqitem"][cPlayerSkills[gfunc.playerSkills.targ][3]+1][2]
		break
		end
	   end
	  end
	 cPlayerSkills[gfunc.playerSkills.targ][3] = cPlayerSkills[gfunc.playerSkills.targ][3] + 1
	 end
	blbl, checkv1, checkv2 = nil, nil, nil
	end
	blbl = false
    for p = 1, #cUskills do
	 if ev[5] == 0 and cPlayerSkills[gfunc.playerSkills.targ][1] > 1 and clicked(ev[3],ev[4],gfunc.playerSkills.x+105,gfunc.playerSkills.y+6+4*p-4,gfunc.playerSkills.x+115,gfunc.playerSkills.y+6+4*p-1) and cPlayerSkills[gfunc.playerSkills.targ][3] > 0 and gsd[cPlayerSkills[gfunc.playerSkills.targ][1]]["type"] ~= "passive" then
	  for n = 1, #cUskills do
	  if cUskills[n] == cPlayerSkills[gfunc.playerSkills.targ][1] then cUskills[n] = 0 end
      end
	 cUskills[p+1] = cPlayerSkills[gfunc.playerSkills.targ][1]
	 blbl = true
	 break
	 end
	end
   end
end

function gfunc.spawnSingleUnit(id,x,y)
local newID = gfunc.addUnit(id,x,y)
CGD[newID]["image"] = setImage(id)
end

local bce = {
	b = {},
	common = {
		[1]={{"#","#","#","#"},
			 {"#","0","0","#"},
			 {"#","#","#","#"},
			 c = 0x000000
			},

			}
}

function bce.bColorEffect(id,x,y)
bce.b[#bce+1] = {id,x,y}
end

function bce.bImagi()
 for f = 1, #bce.b do
  for h = 1, #bce.common[bce.b[f]["id"]] do
   for w = 1, #bce.common[bce.b[f]["id"]][h] do
    if bce.common[h][w] ~= 0 then
    buffer.set(bce.b[f][x]+w-1, bce.b[f][y]+h-1, bce.common[f].c)
    end
   end
  end
 end
end

local function dAfterkill(d,x)
 for f = 1, #d do
  if d[f] == "np" then -- create the portal
  gfunc.addUnit(43,x+10,2)
  imageBuffer[#imageBuffer+1] = image.duplicate(image.load(dir.."sprpic/"..gud[43]["image"]..".pic"))
  CGD[#CGD]["image"] = #imageBuffer
  elseif type(d[f]) == "table" and d[f][1] == "sp" and gud[d[f][2]]["nres"] then -- spawn
  gfunc.spawnSingleUnit(d[f][2],x+gfunc.random(-10,10),1)
  elseif type(d[f]) == "table" and d[f][1] == "cq" then -- cancel the quest
   for i = 1, #d[f] - 1 do
   gqd[d[f][i+1]]["comp"] = true
	for e = 1, #cUquests do
	if cUquests[#cUquests-e+1][1] == d[f][i+1] then tableRemove(cUquests,#cUquests-e+1) end
	end   
   end
  end
 end
end

local itemLoot

function gfunc.getLootItems(fromID)
itemLoot = {}
 if gud[CGD[fromID]["id"]]["loot"]["drop"] then
  for f = 1, #gud[CGD[fromID]["id"]]["loot"]["drop"] do
  itemLoot[#itemLoot+1] = gud[CGD[fromID]["id"]]["loot"]["drop"][f]
  end
 end
 for f = 1, #lootdata[gud[CGD[fromID]["id"]]["loot"]["items"]] do
 itemLoot[#itemLoot+1] = lootdata[gud[CGD[fromID]["id"]]["loot"]["items"]][f]
 end
 -- рандомный лут с мобов
itemLoot = getRandSeq(itemLoot)
local nitemloop = gud[CGD[fromID]["id"]]["tcdrop"] or 1 -- количество циклов, т.е. макс. количество предметов
 for l = 1, nitemloop do
  for f = 1, #itemLoot do
   if itemLoot[f][1] ~= nil and gfunc.random(1,10^5) <= itemLoot[f][2]*10^3 then
    if gfunc.random(1,100) >= 25 then itemLoot[f][1] = createNewItem(itemLoot[f][1]) end
   addItem(itemLoot[f][1],1)
   gfunc.console.debug('Получен предмет "'..gid[itemLoot[f][1]]["name"]..'"')
   gfunc.textmsg1('Получен предмет "'..gid[itemLoot[f][1]]["name"]..'"')
   break
   end
  end
 end
itemLoot = nil
end

-- наносить урон по мобам
function gfunc.makeDamage(id, damage)
local chchance, eeee = 1, nil
if gfunc.random(1,100) <= CGD[pID]["criticalhc"] then chchance = 2; damage = damage * 2 end
 -- не упал
 if CGD[id]["chp"] > damage then
 CGD[id]["attPlayer"] = true
 CGD[id]["chp"] = CGD[id]["chp"] - damage
 gfunc.console.debug(unicode.sub(gud[CGD[id]["id"]]["name"],1,15),"получил урон",damage)
 -- упал
 elseif CGD[id]["chp"] <= damage then
 CGD[id]["effects"] = {}
 CGD[id]["attPlayer"] = false
 gfunc.console.debug(unicode.sub(gud[CGD[id]["id"]]["name"],1,15),"получил урон",damage)
 CGD[id]["chp"] = 0
 CGD[id]["living"] = false
 CGD[id]["resptime"] = gud[CGD[id]["id"]]["vresp"]
 -- выпадение лута
 gfunc.getLootItems(id)
  for f = 1, #cUquests do
   -- в квесте 1 моб
   if gqd[cUquests[f][1]]["type"] == "k" and type(cUquests[f][2]) == "number" then
    if CGD[id]["id"] == gqd[cUquests[f][1]]["targ"] and cUquests[f][3] == false then
	 if cUquests[f][2] + 1 < gqd[cUquests[f][1]]["num"] then
	 cUquests[f][2] = cUquests[f][2] + 1
	 else
	 gqd[cUquests[f][1]]["comp"] = true
	 cUquests[f][2] = gqd[cUquests[f][1]]["num"]
	 cUquests[f][3] = true 
	 gfunc.textmsg1('Задание "'..gqd[cUquests[f][1]]["name"]..'" выполнено!')
	 end
    end
   -- в квесте > 1 моба
   elseif gqd[cUquests[f][1]]["type"] == "k" and type(cUquests[f][2]) == "table" then
	for j = 1, #gqd[cUquests[f][1]]["targ"] do
	 if CGD[id]["id"] == gqd[cUquests[f][1]]["targ"][j] and cUquests[f][3] == false then
	  if cUquests[f][2][j] < gqd[cUquests[f][1]]["num"][j] then
	  cUquests[f][2][j] = cUquests[f][2][j] + 1
	  end
	 end
	end
    eeee = 0
	for j = 1, #gqd[cUquests[f][1]]["targ"] do
	if cUquests[f][2][j] == gqd[cUquests[f][1]]["num"][j] then eeee = eeee + 1 end
	end
	if eeee == #gqd[cUquests[f][1]]["targ"] then
 	 if gqd[cUquests[f][1]]["comp"] == false then
	 gfunc.textmsg1('Задание "'..gqd[cUquests[f][1]]["name"]..'" выполнено!') 
	 end
	gqd[cUquests[f][1]]["comp"] = true
	for j = 1, #gqd[cUquests[f][1]]["targ"] do cUquests[f][2][j] = gqd[cUquests[f][1]]["num"][j] end
	cUquests[f][3] = true 	  
    end
   end
  end
 local expr = gud[CGD[id]["id"]]["loot"]["exp"]+mathCeil(gfunc.random(-gud[CGD[id]["id"]]["loot"]["exp"]*0.1,gud[CGD[id]["id"]]["loot"]["exp"]*0.1))
 addXP(expr)
 local coinsLoot = gud[CGD[id]["id"]]["loot"]["coins"]
 local giveCoins = coinsLoot+mathCeil(coinsLoot*gfunc.random(-(50+1.11^mathMin(CGD[id]["lvl"],35)),(50+1.11^mathMin(CGD[id]["lvl"],35)))/100)
 addCoins(giveCoins)
 
 CGD[id]["resptime"] = gud[CGD[id]["id"]]["vresp"]
 gfunc.console.debug("опыт +",expr,"монеты +",giveCoins)
 if id == cTarget then cTarget = 0 end
 showTargetInfo = false
 if gud[CGD[id]["id"]]["daft_klz"] then dAfterkill(gud[CGD[id]["id"]]["daft_klz"],CGD[id]["x"]) end
 if gud[CGD[id]["id"]]["nres"] == true then gud[CGD[id]["id"]]["nres"] = false end
 end
 if damage > 0 then 
  if chchance == 1 then
  inserttunitinfo(id,"Урон "..mathCeil(damage)) 
  elseif chchance == 2 then
  inserttunitinfo(id,"Критический урон "..mathCeil(damage))
  end
 end
bce.bColorEffect(1,85,38)
end

function gfunc.playerGetDamage(fromID,tipedm,dmplus)
 if CGD[fromID]["x"] > CGD[pID]["x"] then
 CGD[fromID]["spos"] = "l"
 else
 CGD[fromID]["spos"] = "r"
 end
 -- атака прерывает выкапывание чего-то там
 if pickingUp then
 if cTarget == pckTarget then cTarget = 0 end
 pckTarget = 0
 pickingUp = false
 pckTime, maxPckTime = 0, 0
 CGD[pID]["cmove"] = true
 CGD[pID]["image"] = 0
 end
 --
local atck, dmgRedu = gfunc.random(CGD[fromID]["ptk"][1]*10,CGD[fromID]["ptk"][2]*10)/10, CGD[pID]["pdef"]/(CGD[pID]["pdef"]+CGD[fromID]["lvl"]*30)
 if tipedm == "m" then
 atck = gfunc.random(CGD[fromID]["mtk"][1]*10,CGD[fromID]["mtk"][2]*10)/10
 dmgRedu = CGD[pID]["mdef"]/(CGD[pID]["mdef"]+CGD[fromID]["lvl"]*30)
 end
local damage = mathMax(mathFloor(mathMax((atck+dmplus)*(1-dmgRedu),0)),1)
if cTarget == 0 then cTarget = fromID end
 if damage < CGD[pID]["chp"] then
 CGD[pID]["chp"] = CGD[pID]["chp"] - damage
 CGD[pID]["rage"] = 10
 gfunc.textmsg5("Урон " .. damage)
 gfunc.console.debug(unicode.sub(gud[CGD[fromID]["id"]]["name"],1,20),"нанёс",tostring(damage):sub(1,10).."ед. урона ("..tipedm..")")
 else
 CGD[pID]["living"] = false
 end
return damage
end

function gfunc.enemySkill(enemy,sl,lvl)
 if eusd[sl]["type"] == 1 and CGD[enemy]["living"] and gfunc.getDistanceToId(pID,enemy) <= 60 and CGD[enemy]["attPlayer"] == true and CGD[enemy]["ctck"] then
  -- attack skill
  local dist = gud[CGD[enemy]["id"]]["atds"]+eusd[sl]["distance"]
  if gfunc.getDistanceToId(pID,enemy) > dist then
   if CGD[enemy]["x"] > CGD[pID]["x"] then
   CGD[enemy]["spos"] = "l"
   CGD[enemy]["mx"] = CGD[pID]["x"]+CGD[pID]["width"]+dist
   else
   CGD[enemy]["spos"] = "r"
   CGD[enemy]["mx"] = CGD[pID]["x"]-dist
   end
  else
  CGD[enemy]["mx"] = CGD[enemy]["x"]
  gfunc.playerGetDamage(enemy,eusd[sl]["typedm"],gfunc.random(eusd[sl]["damageinc"][lvl][1],eusd[sl]["damageinc"][lvl][2]))
   if eusd[sl]["eff"] then
   gfunc.addUnitEffect(pID,eusd[sl]["eff"][1],eusd[sl]["eff"][2])
   end
  end
 elseif eusd[sl]["type"] == 2 and CGD[enemy]["living"] and CGD[enemy]["attPlayer"] == true then
  -- buff skill
  gfunc.addUnitEffect(enemy,eusd[sl]["eff"][1],eusd[sl]["eff"][2])
 end
end

function gfunc.useSkill(skill)
local cskill = cPlayerSkills[cUskills[skill]][1]
local lvl = cPlayerSkills[cUskills[skill]][3]
local damage = 0
 if gsd[cskill]["type"] == "attack" and CGD[cTarget]["rtype"] ~= "p" and CGD[cTarget]["rtype"] ~= "f" and CGD[cTarget]["rtype"] ~= "r" and CGD[cTarget]["rtype"] ~= "c" then
  if CGD[cTarget]["x"] > CGD[pID]["x"] then
  CGD[pID]["spos"] = "r"
  else
  CGD[pID]["spos"] = "l"
  end
 local weaponDmg
   if gsd[cskill]["typedm"] == "p" then
   damage = damage + gfunc.random(CGD[pID]["ptk"][1]*10,CGD[pID]["ptk"][2]*10)/10
   weaponDmg = gfunc.random(vaddsPnts.vPdm1,vaddsPnts.vPdm2)
   elseif gsd[cskill]["typedm"] == "m" then
   damage = damage + gfunc.random(CGD[pID]["mtk"][1]*10,CGD[pID]["mtk"][2]*10)/10
   weaponDmg = gfunc.random(vaddsPnts.vMdm1,vaddsPnts.vMdm2)
   end  
   if type(gsd[cskill]["basedmgmlt"]) == "table" then damage = damage + damage*gsd[cskill]["basedmgmlt"][lvl]*0.01 
   elseif type(gsd[cskill]["basedmgmlt"]) == "number" then damage = damage + damage*gsd[cskill]["basedmgmlt"]*0.01 
   end  
   if gsd[cskill]["weapondmgmlt"] and CGD[pID]["inventory"]["weared"]["weapon"] > 0 then damage = damage + weaponDmg*gsd[cskill]["weapondmgmlt"][lvl]*0.01 end
   if gsd[cskill]["bseatckinc"] then damage = damage + damage*gsd[cskill]["bseatckinc"][lvl]*0.01 end
   if gsd[cskill]["value"] then damage = damage + gsd[cskill]["value"][lvl] end
  if gsd[cskill]["typedm"] == "p" then
  damage = mathMax(damage*(1-CGD[cTarget]["pdef"]/(CGD[cTarget]["pdef"]+CGD[pID]["lvl"]*30)),0.1)
  elseif gsd[cskill]["typedm"] == "m" then
  damage = mathMax(damage*(1-CGD[cTarget]["mdef"]/(CGD[cTarget]["mdef"]+CGD[pID]["lvl"]*30)),0.1)
  end
  if CGD[pID]["cmp"] >= gsd[cskill]["manacost"][lvl] and cPlayerSkills[cUskills[skill]][2] == 0 and gfunc.getDistanceToId(pID,cTarget) <= vAttackDistance+gsd[cskill]["distance"] then
  CGD[pID]["cmp"] = CGD[pID]["cmp"] - gsd[cskill]["manacost"][lvl]
  damage = mathMax(damage,1)
  gfunc.makeDamage(cTarget, mathFloor(damage))
  cPlayerSkills[cUskills[1]][2] = gsd[1]["reloading"]*10
  CGD[pID]["image"] = -4
  pimg4t = 0
  if cTarget ~= 0 and gsd[cskill]["eff"] ~= nil then gfunc.addUnitEffect(cTarget,gsd[cskill]["eff"],cPlayerSkills[cUskills[skill]][3]) end
  cPlayerSkills[cUskills[skill]][2] = gsd[cskill]["reloading"]*10
  vtskillUsingMsg = 3
  skillUsingMsg[1] = gsd[cskill]["name"]
  end
 CGD[pID]["rage"] = 10
 elseif gsd[cskill]["type"] == "buff" and CGD[pID]["cmp"] >= gsd[cskill]["manacost"][lvl] and cPlayerSkills[cUskills[skill]][2] == 0 then
 CGD[pID]["cmp"] = CGD[pID]["cmp"] - gsd[cskill]["manacost"][lvl]
 cPlayerSkills[cUskills[skill]][2] = gsd[cskill]["reloading"]*10
 if gsd[cskill]["eff"] ~= nil then gfunc.addUnitEffect(pID,gsd[cskill]["eff"],lvl) end
 skillUsingMsg[1] = gsd[cskill]["name"]
 end
end

function gfunc.pickUpResource(id)
pckTarget = id
pickingUp = true
local mpcktime = gfunc.random(gud[CGD[pckTarget]["id"]]["mnprs"]*10,gud[CGD[pckTarget]["id"]]["mxprs"]*10)
pckTime, maxPckTime = mpcktime, mpcktime
CGD[pID]["cmove"] = false
CGD[pID]["image"] = -1
CGD[pID]["mx"] = CGD[pID]["x"]
end

function gfunc.gatheringAction(id)
pmov = 0
usepmx = false
 if gud[CGD[id]["id"]]["reqquest"] then
  for m = 1, #cUquests do
   if cUquests[m][1] == gud[CGD[id]["id"]]["reqquest"] and cUquests[m][3] ~= true then
   gfunc.pickUpResource(id)
   end
  end
 else
 gfunc.pickUpResource(id)
 end
end

local function getClose(cpID, cid, distance)
 if CGD[cpID]["x"] > mathFloor(CGD[cid]["x"]) + CGD[cid]["width"] then
 CGD[cpID]["mx"] = mathFloor(CGD[cid]["x"]) + CGD[cid]["width"] + gfunc.roundupnum(distance)
 elseif CGD[cpID]["x"] + CGD[cpID]["width"] < mathFloor(CGD[cid]["x"]) then
 CGD[cpID]["mx"] = mathCeil(CGD[cid]["x"]) - CGD[cpID]["width"] - gfunc.roundupnum(distance)
 end
gfunc.usepmx = true
end

function gfunc.getRawCount(array)
local count = 0
 for f, v in pairs(array) do
 count = count + 1
 end
return count
end

function gfunc.debugText()
local text = {
	"#CGD = "..#CGD,
	"#gid = "..#gid,
	"#imageBuffer = "..gfunc.getRawCount(#imageBuffer),
	"#iconImageBuffer = "..gfunc.getRawCount(iconImageBuffer),
	}
 for f = 1, #text do
 buffer.text(2,49-#text+f,0xffffff,text[f])
 end
end

local qCompList = {x=160,y=8, cscroll=1}

function gfunc.questsCompList(x,y)
local tablo = {}
local cl
 for f = 1, mathMin(#cUquests,10) do
 cl = 0xEFEFEF
 if cUquests[f] then
  if cUquests[f][3] == true then cl = 0x00C222 end
  tablo[#tablo+1] = {"→"..gqd[cUquests[f][1]]["name"],cl}
   if gqd[cUquests[f][1]]["type"] == "k" and type(gqd[cUquests[f][1]]["num"]) == "number" then 
   tablo[#tablo+1] = {" "..gud[gqd[cUquests[f][1]]["targ"]]["name"].."("..cUquests[f][2].."/"..gqd[cUquests[f][1]]["num"]..")",cl}
   end
  end
 end
 local w = 0
 for f = 1, #tablo do
 if unicode.len(tablo[f][1])+1 > w then w = unicode.len(tablo[f][1])+1 end
 end
 local cx = mathMin(x,159-mathMin(w,45))
 if #cUquests > 0 then 
 buffer.square(cx,y,mathMax(mathMin(w,45),8),1,0x525252)
 cl = 50
 if limg < 4 then cl = nil end
 buffer.square(cx,y+1,mathMax(mathMin(w,45),8),#tablo,0x828282,nil,nil,cl)
 buffer.text(cx,y,0xEFEFEF,"Задания")
 end
 for f = 1, #tablo do
 buffer.text(cx,y+f,tablo[f][2],tablo[f][1])
 end
end
--[[
gfunc.weaponImg = {
["sword"] = {
	0x787878,0,0," ", 0x787878,0,0," ", 0x787878,0,0," ", 0x787878,0,0," ", 0x787878,0,0," ", 0,0x787878,255,"▶", width = 6, height = 1
	},
}
]]--

function gfunc.GetQuestReward(q)
addXP(gqd[q]["qreward"]["xp"])
CGD[pID]["cash"] = CGD[pID]["cash"] + gqd[q]["qreward"]["coins"]
 if gqd[q]["qreward"]["item"] then
  for u = 1, #gqd[q]["qreward"]["item"] do
  addItem(gqd[q]["qreward"]["item"][u][1],gqd[q]["qreward"]["item"][u][2])
  end
 end
end

local dping, fpstclr, fpsrclr = 0, 0, {{5,0xFF6D00},{9,0xFFB640},{15,0xFFFF40},{50,0x40FF40}}
local deltaT = 0

local function dmain()
 if cWindowTrd ~= "inventory" and cWindowTrd ~= "tradewindow" and cWindowTrd ~= "craftwindow" then
  if not debugMode then
  world[world.current].draw()
  else
  buffer.square(1,1,160,50,0x000000)
  end
 -- player
	if CGD[pID]["spos"] == "r" then 
	buffer.image(pSprPicPos, 48-CGD[pID]["height"], imageBuffer[CGD[pID]["image"]],true)
	--buffer.image(pSprPicPos+7,40,gfunc.weaponImg["sword"])
	else 
	buffer.image(pSprPicPos, 48-CGD[pID]["height"], image.flipHorizontal(image.duplicate(imageBuffer[CGD[pID]["image"]])),true)
	end 
 -- other units
 gfunc.drawAllCGDUnits()
  if cWindowTrd ~= "screen_save" then
   if CGD[pID]["living"] then
    if cWindowTrd ~= "pause" then
    gfunc.playerInfoPanel.draw()
    end
   if cTarget ~= 0 then gfunc.targetInfoPanel.draw() end
   gfunc.skillsTopPanel.draw()
   end
  gfunc.questsCompList(qCompList.x,qCompList.y)
  buffer.text(156,2,0xffffff,"█ █")
  buffer.text(156,3,0xffffff,"█ █")
   if smsg1time > 0 then
   buffer.text(9,49,0x929292,">"..( sMSG1[#sMSG1-1] or "" ))
   buffer.text(9,50,0xC7C7C7,">"..( sMSG1[#sMSG1] or "" ))
   end
   if smsg2time > 0 then
   buffer.text(80-unicode.len(sMSG2[#sMSG2])/2,12,0xD3D3D3,sMSG2[#sMSG2])
   end
   if smsg4time > 0 then
   buffer.text(2,13,0x9C9C9C,sMSG4[#sMSG4-2])
   buffer.text(2,14,0xACACAC,sMSG4[#sMSG4-1])
   buffer.text(2,15,0xBCBCBC,sMSG4[#sMSG4])
   end
   if #sMSG5 > 0 then
    for n = 1, 3 do
	 if sMSG5[n] then
	 buffer.text(pSprPicPos,47-CGD[pID]["height"]-2-n,0xBCBCBC,sMSG5[n])
	 end
	end
   smsg5time = smsg5time - 1
   if smsg5time <= 0 then table.remove(sMSG5,1) end
   end
  end
 end
	if cWindowTrd == "pause" then gfunc.pauseMenu.draw() 
	elseif cWindowTrd == "inventory" then  gfunc.inventory.draw()
	elseif cWindowTrd == "dialog" then gfunc.npcDialog.draw()
	elseif cWindowTrd == "spdialog" then gfunc.specialDialog.draw()
	elseif cWindowTrd == "quests" then gfunc.questsList.draw()
	elseif cWindowTrd == "console" then gfunc.gameConsole.draw()
	elseif cWindowTrd == "pstats" then gfunc.playerStats.draw()
	elseif cWindowTrd == "tradewindow" then gfunc.tradew.draw()
	elseif cWindowTrd == "craftwindow" then gfunc.craftw.draw()
	elseif not CGD[pID]["living"] then gfunc.ydw.draw()
	elseif cWindowTrd == "skillsWindow" then gfunc.playerSkills.draw()
	end
 if debugMode then
 gfunc.debugText()
 end
--buffer.text(1,49,0xffffff,"delay: "..tostring(dping).." "..tostring(deltaT).." ms")
for f = 1, #fpsrclr do if fpsrclr[f][1] >= cfps then fpstclr = fpsrclr[f][2]; break end end
buffer.text(1,50,fpstclr,"fps: "..tostring(cfps))
usram = gfunc.RAMInfo()
buffer.text(160-#usram,50,0xC7C7C7,usram)
buffer.draw()
end

function gfunc.mCheck()
if computer.totalMemory() >= 2*1024^2 then return true end
if computer.freeMemory() < 2^14 then return false end
end

local EmptyArmorSlotsList = {
	[1]={"helmet","image/gigd1.pic"},
	[2]={"armor","image/gigd2.pic"},
	[3]={"pants","image/gigd3.pic"},
	[4]={"footwear","image/gigd4.pic"},
	[5]={"weapon","image/gigd5.pic"},
	[6]={"pendant","image/gigd6.pic"},
	[7]={"robe","image/gigd7.pic"},
	[8]={"ring","image/gigd8.pic"},
}

function gfunc.openInventory()
cWindowTrd = "inventory"
iconImageBuffer[0]={}
 for il = 1, #EmptyArmorSlotsList do
  if gfunc.mCheck() then
  iconImageBuffer[0][EmptyArmorSlotsList[il][1]] = image.load(dir..EmptyArmorSlotsList[il][2])
  end
 end
 for f = 1, #CGD[pID]["inventory"]["bag"] do
  if CGD[pID]["inventory"]["bag"][f][1] ~= 0 and CGD[pID]["inventory"]["bag"][f][2] ~= 0 and gid[CGD[pID]["inventory"]["bag"][f][1]] and gfunc.mCheck() then
  iconImageBuffer[f] = image.load(dir.."itempic/"..loadedItemIcons[gid[CGD[pID]["inventory"]["bag"][f][1]]["icon"]]..".pic")
  end
 end
 for f = 1, #wItemTypes do
  if CGD[pID]["inventory"]["weared"][wItemTypes[f]] ~= 0 and gfunc.mCheck() then 
  iconImageBuffer[wItemTypes[f]] = image.load(dir.."itempic/"..loadedItemIcons[gid[CGD[pID]["inventory"]["weared"][wItemTypes[f]]]["icon"]]..".pic")
  end
 end
end

gfunc.pauseMenuMenuAction = {
[1]=function()
cWindowTrd = nil 
paused = false
end,
[2]=function()
gfunc.openInventory()
end,
[3]=function()
cWindowTrd = "skillsWindow"
end,
[4]=function()
cWindowTrd = "pstats"
end,
[5]=function()
cWindowTrd = "quests"
end,
[6]=function()
gfunc.saveGame(dir.."saves","save")
end,
[7]=function()
gfunc.loadGame(dir.."saves","save")
end,
[8]=function()
ingame = false
end,
}

gfunc.addUnit(pID,1,1)

CGD[pID]["inventory"] = {
["weared"] = {
["helmet"] = 0,
["pendant"] = 0,
["armor"] = 0,
["robe"] = 0,
["pants"] = 0,
["weapon"] = 7,
["footwear"] = 0,
["ring"] = 0},
["bag"] = {}
}
for f = 1, 20 do CGD[pID]["inventory"]["bag"][f] = {0,0} end

CGD[pID]["levelpoints"] = gud[1]["lvl"]-1
CGD[pID]["survivability"] = gud[1]["survivability"]
CGD[pID]["strength"] = gud[1]["strength"]
CGD[pID]["intelligence"] = gud[1]["intelligence"]
CGD[pID]["rage"] = 0
CGD[pID]["cmp"] = 0
CGD[pID]["mmp"] = 0
CGD[pID]["cxp"] = 0
CGD[pID]["mxp"] = 0
CGD[pID]["cash"] = 0
CGD[pID]["cint"] = nil
gfunc.loadWorld(world.current)
gfunc.playerRV()
gfunc.maxXP()
CGD[pID]["chp"] = CGD[pID]["mhp"]
CGD[pID]["cmp"] = CGD[pID]["mmp"]
dmain()

local uMoveRef = 1
local healthReg, manaReg

local function functionPS()
local value, duration, efftype, itemLootarray, qwert, regMultiplier
local deltan = 0
 while ingame do
 cfps = gamefps
 gamefps = 0
  if not paused then
  deltan = os.clock()
  gfunc.playerRV()
  -- вещи не достойные внимания ниже
  if cTarget ~= 0 and gfunc.getDistanceToId(pID,cTarget) > 99 then cTarget = 0; showTargetInfo = false end
  uMoveRef = uMoveRef - 1
  if vtskillUsingMsg > 0 then vtskillUsingMsg = vtskillUsingMsg - 1 end
  regMultiplier = 1
  if CGD[pID]["rage"] > 0 then
  regMultiplier = 0.1
  CGD[pID]["rage"] = CGD[pID]["rage"] - 1
  end
  -- кв на предметы
  for f = 1, #cUquests do
   if gqd[cUquests[f][1]]["type"] == "f" then
   cUquests[f][3] = false
    if type(gqd[cUquests[f][1]]["targ"][1]) == "number" then
    cUquests[f][2] = checkItemInBag(gqd[cUquests[f][1]]["targ"][1])
    if cUquests[f][2] >= gqd[cUquests[f][1]]["targ"][2] then cUquests[f][3] = true end
    else 
    local comp = 0
     for i = 1, #gqd[cUquests[f][1]]["targ"] do
	 cUquests[f][2][i] = checkItemInBag(gqd[cUquests[f][1]]["targ"][i][1])
	 if cUquests[f][2][i] >= gqd[cUquests[f][1]]["targ"][i][2] then comp = comp + 1 end
     end
    if comp == #gqd[cUquests[f][1]]["targ"] then cUquests[f][3] = true end
    end
   end
  end
  -- автоматическое завершение кв
  for f = 1, #cUquests do
  if gqd[cUquests[f][1]]["type"] == "t" and cUquests[f][3] == false then cUquests[f][3] = true end
  end
  -- восстановдение маны, здоровья в сек.
 manaReg = mathMin(0.75+(CGD[pID]["lvl"]-1)*0.22)*regMultiplier
 healthReg = mathMin(0.75+(CGD[pID]["lvl"]-1)*0.15)*regMultiplier

   if CGD[pID]["living"] then
    -- восстановление маны персонажа
	if CGD[pID]["cmp"] < CGD[pID]["mmp"] - manaReg then
    CGD[pID]["cmp"] = CGD[pID]["cmp"] + manaReg
	else
	CGD[pID]["cmp"] = CGD[pID]["mmp"]
    end
    -- восстановление здоровья персонажа
    if CGD[pID]["chp"] < CGD[pID]["mhp"] - healthReg then
    CGD[pID]["chp"] = CGD[pID]["chp"] + healthReg
    else
	CGD[pID]["chp"] = CGD[pID]["mhp"]
	end
   end

   for f = 2, #CGD do
    -- произвольное восстановление жс на 5%/сек.
	if not CGD[f]["attPlayer"] and CGD[f]["living"] then
	 if CGD[f]["chp"]+mathCeil(CGD[f]["mhp"]*0.05)<CGD[f]["mhp"] then 
	 CGD[f]["chp"]=CGD[f]["chp"]+mathCeil(CGD[f]["mhp"]*0.05)
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
	-- рандомное движение мобов
	if gfunc.getDistanceToId(pID,f) <= 384 and CGD[f]["rtype"] == "e" and CGD[f]["living"] and gfunc.random(1,3) == 3 and uMoveRef == 0 then
	CGD[f]["mx"] = CGD[f]["sx"] + gfunc.random(-8, 8)
	end
    -- моб подходит и бьёт игрока
	 if CGD[f]["rtype"] == "e" then
	  if gud[CGD[f]["id"]]["skill"] then
	  qwert = {gud[CGD[f]["id"]]["skill"][#gud[CGD[f]["id"]]["skill"]][1],gud[CGD[f]["id"]]["skill"][#gud[CGD[f]["id"]]["skill"]][2]}
	   for o = 1, #gud[CGD[f]["id"]]["skill"] do
	    if gfunc.random(1,100) <= gud[CGD[f]["id"]]["skill"][o][3] then
	    qwert = {gud[CGD[f]["id"]]["skill"][o][1],gud[CGD[f]["id"]]["skill"][o][2]}
	    break
	    end
	   end
	  else
	  qwert = {1,1}
	  end  
	 gfunc.enemySkill(f,qwert[1],qwert[2])
	 end
	qwert = nil
	if CGD[f]["living"] and CGD[f]["attPlayer"] == true and gfunc.getDistanceToId(pID,f) > 60  then
	CGD[f]["attPlayer"] = false
	CGD[f]["mx"] = CGD[f]["sx"]
	end
    -- агр мобов
	if CGD[f]["living"] and gud[CGD[f]["id"]]["agr"] == true and gfunc.getDistanceToId(pID,f) <= gud[CGD[f]["id"]]["atds"]*2 then
    CGD[f]["attPlayer"] = true
    end
	-- самотаргет
	if cTarget == 0 and CGD[f]["attPlayer"] == true then cTarget = f end	
    
	-- надписи над головой
    for m = 1, #CGD[f]["tlinfo"] do
     if CGD[f]["tlinfo"][1] then
	 tableRemove(CGD[f]["tlinfo"],1)
	 end
    end
   end
   -- обслуживание всех эффектов на всех объектах
   for f = 1, #CGD do
   CGD[f]["cmove"] = true
   CGD[f]["ctck"] = true
	if f > 1 then
	gfunc.unitRV(f)
	end
	for eff = 1, #CGD[f]["effects"] do
	 qwert = CGD[f]["effects"][#CGD[f]["effects"]-eff+1]
	 if CGD[f]["living"] and qwert ~= nil then
	  if ged[qwert[1]]["val"] then
	  value = ged[qwert[1]]["val"][qwert[3]]
	  end
	 duration = ged[qwert[1]]["dur"][qwert[3]]
	 efftype = ged[qwert[1]]["type"]
	  if efftype == "hpi" then
	   if CGD[f]["chp"] + value/duration < CGD[f]["mhp"] then
	   CGD[f]["chp"] = CGD[f]["chp"] + value/duration
	   else CGD[f]["chp"] = CGD[f]["mhp"]
	   end
	  elseif efftype == "mpi" then
	  CGD[pID]["cmp"] = mathMax(mathMin(CGD[pID]["cmp"] + value/duration,CGD[pID]["mmp"]),0)
	  elseif efftype == "hpi%" then
	  CGD[f]["chp"] = mathMin(CGD[f]["chp"] + CGD[f]["mhp"]*value*0.01,CGD[f]["mhp"])
	  elseif efftype == "hpd" then
      gfunc.makeDamage(f,value/duration)
	  elseif efftype == "pdfi%" then
	  CGD[f]["pdef"] = CGD[f]["pdef"]+mathCeil(value/100*CGD[f]["pdef"])
	  elseif efftype == "mdfi%" then
	  CGD[f]["mdef"] = CGD[f]["mdef"]+mathCeil(value/100*CGD[f]["mdef"])
	  elseif efftype == "stn" then
	  CGD[f]["cmove"] = false
	  CGD[f]["ctck"] = false
	  elseif efftype == "ste" then
	  CGD[f]["cmove"] = false
	  end
	  if qwert ~= nil then
	  qwert[2] = qwert[2] - 1  
	   if qwert[2] == 0 then
	    if vshowEffDescr == qwert[1] then
		vshowEffDescr = 0
		end
	   tableRemove(CGD[f]["effects"],#CGD[f]["effects"]-eff+1) 
	   end
	  end
	 end
	end
   end
   ------------------------------------------------
   if smsg1time > 0 then
   smsg1time = smsg1time - 1
   end
   if smsg2time > 0 then
   smsg2time = smsg2time - 1
   end
   if smsg4time > 0 then
   smsg4time = smsg4time - 1
   end
  if uMoveRef <= 0 then uMoveRef = 8 end

  setScreenNewPosition() -- сдвиг камеры
  if sScreenTimer1 > 0 then sScreenTimer1 = sScreenTimer1 - 1 end
 
	if lostItem and not gfunc.checkInventoryisFull() then -- дает предмет который не поместился в инвентарь
	addItem(lostItem[1],lostItem[2])
	lostItem = nil
	end
	-- автовосстановление жс, мэ
   for f = 1, #CGD[pID]["inventory"]["bag"] do
    if CGD[pID]["inventory"]["bag"][f][1] > 0 and gid[CGD[pID]["inventory"]["bag"][f][1]] and CGD[pID]["inventory"]["bag"][f][2] > 0 and CGD[pID]["living"] and gid[CGD[pID]["inventory"]["bag"][f][1]]["type"] == "elementmul" then
     if gid[CGD[pID]["inventory"]["bag"][f][1]]["subtype"] == "hp" and CGD[pID]["chp"] <= CGD[pID]["mhp"]*(gid[CGD[pID]["inventory"]["bag"][f][1]]["props"]["r"]*0.01) then
	 CGD[pID]["chp"] = mathMin(CGD[pID]["chp"]+CGD[pID]["mhp"]*0.01*gid[CGD[pID]["inventory"]["bag"][f][1]]["props"]["ics"],CGD[pID]["mhp"])
	 CGD[pID]["inventory"]["bag"][f][2] = CGD[pID]["inventory"]["bag"][f][2] - 1
	 break
	 elseif gid[CGD[pID]["inventory"]["bag"][f][1]]["subtype"] == "mp" and CGD[pID]["cmp"] <= CGD[pID]["mmp"]*(gid[CGD[pID]["inventory"]["bag"][f][1]]["props"]["r"]*0.01) then
	 CGD[pID]["cmp"] = mathMin(CGD[pID]["cmp"]+CGD[pID]["mmp"]*0.01*gid[CGD[pID]["inventory"]["bag"][f][1]]["props"]["ics"],CGD[pID]["mmp"])
	 CGD[pID]["inventory"]["bag"][f][2] = CGD[pID]["inventory"]["bag"][f][2] - 1
	 break
	 end
    end
   end
  --dping = mathFloor((os.clock() - deltan)*10000)/100
  end
 os.sleep(1) 
 end
end

local function funcP4()
local tblpbl
 while ingame do
  if not paused then
   for f = 2, #CGD do
    -- мобы бегают быстрее
	if CGD[f]["living"] and gfunc.getDistanceToId(pID,f) <= 256 and CGD[f]["x"] ~= CGD[f]["mx"] and not gud[CGD[f]["id"]]["cmve"] and CGD[f]["cmove"] then
	tblpbl = 0.25
	 if CGD[f]["attPlayer"] then 
	 tblpbl = 0.5 
	 if gfunc.getDistanceToId(pID,f) >= gud[CGD[f]["id"]]["atds"]*2 then tblpbl = 1 end
	 end	
	movetoward(f, CGD[f]["mx"], 100, tblpbl)
	end
   end
  end
 os.sleep(0.25)
 end
end

local pimg4t = 0

local function funcP10()
local dec = 0
local deltan
 while ingame do
 if not paused then
 deltan = os.clock()
  if dec == 0 then -- 1/10 сек
	if pickingUp then
	CGD[pID]["mx"] = CGD[pID]["x"]
	pckTime = pckTime - 1
	if CGD[pID]["image"] ~= -1 then CGD[pID]["image"] = -1 end
	end
	-- копание тут
	if pickingUp and pckTime == 0 then
	CGD[pID]["image"] = 0
	pickingUp = false
	itemLootarray = getRandSeq(gud[CGD[pckTarget]["id"]]["items"])
 	for item = 1, #itemLootarray do
	  if itemLootarray[item][1] ~= nil and 1000-itemLootarray[item][2]*10 <= gfunc.random(1,1000) then
      if gfunc.random(1,15) == 5 then itemLootarray[item][1] = createNewItem(itemLootarray[item][1]) end
      addItem(itemLootarray[item][1],1)
      gfunc.console.debug('Получен предмет "'..gid[itemLootarray[item][1]]["name"]..'"')
      gfunc.textmsg1('Получен предмет "'..gid[itemLootarray[item][1]]["name"]..'"')
      break
	  end
	 end
    addXP(gud[CGD[pckTarget]["id"]]["exp"])
    addCoins(gud[CGD[pckTarget]["id"]]["coins"])
    CGD[pID]["cmove"] = true
    CGD[pckTarget]["living"] = false
    CGD[pckTarget]["resptime"] = gud[CGD[pckTarget]["id"]]["vresp"]
    if pckTarget == cTarget then cTarget = 0 end
    end
	-- умения перезаряжаются
   for f = 1, #cUskills do
	if cUskills[f] > 0 and cPlayerSkills[cUskills[f]][1] > 0 and cPlayerSkills[cUskills[f]][2] > 0 then
	cPlayerSkills[cUskills[f]][2] = mathMax(cPlayerSkills[cUskills[f]][2] - 1, 0)
	end
   end
   
   if CGD[pID]["cint"] ~= nil and CGD[pID]["cint"][2] ~= 0 then
	if CGD[pID]["cint"][1] == 1 and gfunc.getDistanceToId(pID,CGD[pID]["cint"][2]) <= CGD[pID]["cint"][3] then
	gfunc.gatheringAction(CGD[pID]["cint"][2])
	CGD[pID]["cint"] = nil
	elseif CGD[pID]["cint"][1] == 2 then
	 if cPlayerSkills[cUskills[1]] and not pickingUp and CGD[CGD[pID]["cint"][2]]["living"] then
	  if gfunc.getDistanceToId(pID,CGD[pID]["cint"][2]) <= CGD[pID]["cint"][3] then
	   pmov = 0
	   gfunc.usepmx = false
       gfunc.useSkill(CGD[pID]["cint"][4] or 1)
	   if CGD[pID]["cint"][4] then tableRemove(CGD[pID]["cint"],4) end
	  else
	  getClose(pID, CGD[pID]["cint"][2], CGD[pID]["cint"][3])
	  end
	 else 
	 CGD[pID]["cint"] = nil
	 end
	end
   end
   
	-- что это такое?
   if CGD[pID]["image"] == -4 then
    if pimg4t >= 2 then
    CGD[pID]["image"] = 0
	pimg4t = 0
	end
	pimg4t = pimg4t + 1
   end
  end
  if dec > -1 then -- 1/20 сек.
	-- это работает при ctrl + стрелки или ctrl + A/D
   if gfunc.usepmx and CGD[pID]["x"] ~= CGD[pID]["mx"] then
   gfunc.playerAutoMove(mathFloor(CGD[pID]["mx"]), 9999, 3)
   else gfunc.usepmx = false
   end
   gfunc.pmovlck = false
   if CGD[pID]["x"] <= world[world.current].limitL and pmov < 0 then 
   gfunc.pmovlck = true
   CGD[pID]["image"] = 0
   elseif CGD[pID]["x"] >= world[world.current].limitR and pmov > 0 then 
   gfunc.pmovlck = true
   CGD[pID]["image"] = 0
   end
	-- ходьба и её отстойная анимация
   if not pickingUp and not gfunc.pmovlck and pmov ~= 0 and CGD[pID]["cmove"] then
     if gfunc.usepmx and CGD[pID]["x"] == CGD[pID]["mx"] then
	 pmov = 0
	 CGD[pID]["mx"] = math.huge
	 end
	CGD[pID]["x"] = CGD[pID]["x"] + pmov
    cGlobalx = cGlobalx + pmov
    cBackgroundPos = cBackgroundPos + pmov
    if gfunc.cim <= 3 then
    CGD[pID]["image"] = -3
    elseif gfunc.cim > 3 and gfunc.cim <= 6 then
    CGD[pID]["image"] = 0
    else
    CGD[pID]["image"] = -2
    end
   if gfunc.cim > 9 then gfunc.cim = 1 end
   gfunc.cim = gfunc.cim + 1  
   end
  end
 --dping = mathFloor((os.clock() - deltan)*10000)/100  
 end
 os.sleep(0.05)
 if dec == 0 then dec = 1 else dec = 0 end
 end
end

gfunc.cim = 1
gfunc.pmovlck = false

local function screen()
local deltaD = 0
 while ingame do
  if not stopDrawing then
  --deltaD = os.clock()
  dmain()
  --deltaT = mathFloor((os.clock() - deltaD)*10000)/100
  gamefps = gamefps + 1
  end
 os.sleep(10^-6)
 end
end

local function main()
local ev, vseffdescrig, pItem, mpcktime, checkVar1, tpskp, formula, Citem, blbl, checkv1, checkv2, someVar1, tenb
 while ingame do
 someVar1 = true
 ev = table.pack(event.pull())
 if ev[1] == "key_down" then
  if ev[4] == 44 then ingame = false end
  
  if (ev[4] == 205 or ev[4] == 32) and not paused and CGD[pID]["x"] <= world[world.current].limitR and CGD[pID]["cmove"] and CGD[pID]["cmove"] then -- вправо
   CGD[pID]["cint"] = nil
   gfunc.usepmx = false
   if keyboard.isAltDown() then
   CGD[pID]["mx"] = world[world.current].limitR
   gfunc.usepmx = true  
   else
   pmov = 3
   CGD[pID]["spos"] = "r"
   gfunc.keyactionmove = true
   end
  elseif (ev[4] == 203 or ev[4] == 30) and not paused and CGD[pID]["x"] >= world[world.current].limitL and CGD[pID]["cmove"] and CGD[pID]["cmove"] then -- влево
   CGD[pID]["cint"] = nil
   gfunc.usepmx = false
   if keyboard.isAltDown() then
   CGD[pID]["mx"] = world[world.current].limitL
   gfunc.usepmx = true
   else
   pmov = -3
   CGD[pID]["spos"] = "l"
   gfunc.keyactionmove = true
   end
  end
  if not paused and ev[4] >= 2 and ev[4] <= 7 then
   for f = 1, 6 do
	if ev[4] == f + 1 and cTarget ~= 0 and cUskills[f] > 0 and cPlayerSkills[cUskills[f]] and cPlayerSkills[cUskills[f]][3] > 0 and not pickingUp then
	 if gsd[cPlayerSkills[cUskills[f]][1]]["type"] == "attack" then
	  vAttackDistance = vAttackDistance or 8
	  if gfunc.getDistanceToId(pID,cTarget) > gfunc.getPlayerAtdsBySkill(f) then
	  CGD[pID]["cint"] = {2,cTarget,gfunc.getPlayerAtdsBySkill(f),f}
	  else
	  gfunc.useSkill(f)
	  CGD[pID]["cint"] = {2,cTarget,gfunc.getPlayerAtdsBySkill(f),f}
	  gfunc.usepmx = false
	  pmov = 0
	  CGD[pID]["mx"] = CGD[pID]["x"]
	  break
	  end
	 elseif gsd[cPlayerSkills[cUskills[f]][1]]["type"] == "buff" then
	 gfunc.useSkill(f)
	 CGD[pID]["cint"] = nil
	 pmov = 0
	 break
	 end
	end
   end
  end
  -- Нажатие клавиши 'E'
  if not paused and ev[4] == 18 and cTarget ~= 0 then
	-- на нпс
	if CGD[cTarget]["rtype"] == "f" and gfunc.getDistanceToId(pID,cTarget) <= 40 then
	CGD[pID]["mx"] = CGD[pID]["x"]
	paused = true
	cWindowTrd = "dialog"
	gfunc.dialogsdata, gfunc.gddnum = io.open(dir.."data/dialogs.data","r"), 1
	 for dnum in gfunc.dialogsdata:lines() do
	 if gfunc.gddnum == CGD[cTarget]["dialog"] then
	 cDialog = load("return "..dnum)()
	 break
	 end
	gfunc.gddnum = gfunc.gddnum + 1
	end
	gfunc.dialogsdata:close()
	gfunc.dialogsdata = nil
	cDialog["im"] = 0
	cDialog = insertQuests(cTarget,cDialog)
	-- на ресурс
	elseif CGD[cTarget]["rtype"] == "r" and not pickingUp then
	 if gfunc.getDistanceToId(pID,cTarget) <= 11 then
	 gfunc.gatheringAction(cTarget)
	 else
	 CGD[pID]["cint"] = {1,cTarget,5}
	 getClose(pID, cTarget, 5)
	 end
	-- на портал
	elseif CGD[cTarget]["rtype"] == "c" and not pickingUp and gfunc.getDistanceToId(pID,cTarget) <= 10 then
	 if gud[CGD[cTarget]["id"]]["tlp"] == "r" then
	 gfunc.loadWorld(world[world.current].drespawn)
	 elseif type(gud[CGD[cTarget]["id"]]["tlp"]) == "table" then
	 gfunc.teleport(gud[CGD[cTarget]["id"]]["tlp"][2],gud[CGD[cTarget]["id"]]["tlp"][1])
     end
	end
  end
  --
  gfunc.gameConsole.action["key_down"](ev)
  -- Нажатие клавиши 'B'
  if cWindowTrd == nil and not paused and ev[4] == 48 then
  paused = true; gfunc.openInventory()
  elseif cWindowTrd == "inventory" and ev[4] == 48 then
  paused = false; cWindowTrd = nil
  iconImageBuffer = {}
  showItemData = false
  end
  if not paused and cWindowTrd == nil then   
   for f = 1, #CGD[pID]["inventory"]["bag"] do
	if CGD[pID]["inventory"]["bag"][f][1] > 0 and CGD[pID]["inventory"]["bag"][f][2] > 0 and gid[CGD[pID]["inventory"]["bag"][f][1]]["type"] == "potion" and CGD[pID]["lvl"] >= gid[CGD[pID]["inventory"]["bag"][f][1]]["reqlvl"] then
	 -- Нажатие клавиши 'T'
	 if ev[4] == 20 and gid[CGD[pID]["inventory"]["bag"][f][1]]["subtype"] == "health" then
	 gfunc.addUnitEffect(pID,1,gid[CGD[pID]["inventory"]["bag"][f][1]]["lvl"])
	 CGD[pID]["inventory"]["bag"][f][2] = CGD[pID]["inventory"]["bag"][f][2] - 1
	 break
	 -- Нажатие клавиши 'Y'
	 elseif ev[4] == 21 and gid[CGD[pID]["inventory"]["bag"][f][1]]["subtype"] == "mana" then
	 gfunc.addUnitEffect(pID,2,gid[CGD[pID]["inventory"]["bag"][f][1]]["lvl"])
	 CGD[pID]["inventory"]["bag"][f][2] = CGD[pID]["inventory"]["bag"][f][2] - 1
	 break	  
	 end
	end
   end
  end
 end
 if ev[1] == "key_up" then
  if ( ev[4] == 205 or ev[4] == 32 or ev[4] == 203 or ev[4] == 30 ) and not keyboard.isAltDown()then
  if not pickingUp then CGD[pID]["image"] = 0 end
  gfunc.usepmx = false
  pmov = 0
  end
 end
 if ev[1] == "touch" then
  
  --кнопка эксп
  if cWindowTrd == nil and not paused then
   if clicked(ev[3],ev[4],gfunc.playerInfoPanel.x,gfunc.playerInfoPanel.y+3,gfunc.playerInfoPanel.x+gfunc.playerInfoPanel.w-1,gfunc.playerInfoPanel.y+3) then
   svxpbar = true
   else
   svxpbar = false
   end
  end
  
  --кнопка ифно о цели
  if cWindowTrd == nil and ev[5] == 0 and cTarget ~= 0 and gud[CGD[cTarget]["id"]]["rtype"] ~= "r" and gud[CGD[cTarget]["id"]]["rtype"] ~= "f" and clicked(ev[3],ev[4],60,5,71,5) then
  showTargetInfo = true
  elseif cWindowTrd == nil and cTarget ~= 0 and ev[5] == 0 and not clicked(ev[3],ev[4],60,5,71,5) then 
  showTargetInfo = false
  end
  
  --выделить себя
  if ev[5] == 0 and not paused and clicked(ev[3],ev[4],gfunc.playerInfoPanel.x,gfunc.playerInfoPanel.y,gfunc.playerInfoPanel.x+gfunc.playerInfoPanel.w-1,gfunc.playerInfoPanel.y+gfunc.playerInfoPanel.h-1) and cWindowTrd == nil then 
  cTarget = pID 
  end
  
  --кнопка пауза
  if ev[5] == 0 and cWindowTrd == nil and clicked(ev[3],ev[4],gfunc.pauseMenu.buttonX,gfunc.pauseMenu.buttonY,gfunc.pauseMenu.buttonX+2,gfunc.pauseMenu.buttonY+1) then
  cWindowTrd = "pause"
  paused = true
  elseif ev[5] == 0 and cWindowTrd == "pause" and clicked(ev[3],ev[4],gfunc.pauseMenu.buttonX,gfunc.pauseMenu.buttonY,gfunc.pauseMenu.buttonX+2,gfunc.pauseMenu.buttonY+1) then 
  cWindowTrd = nil 
  paused = false
  end
  
  --выбрать цель
  if ev[5] == 0 and not paused and not clicked(ev[3],ev[4],1,1,mxw,8) then 
  target(ev[3],ev[4])
  end
  
  --кликабельные иконки эф
  if ev[5] == 0 and not paused then
   vseffdescrig = false
   for f = 1, #CGD[pID]["effects"] do
    if clicked(ev[3],ev[4],gfunc.playerInfoPanel.x+f*4-4,gfunc.playerInfoPanel.y+gfunc.playerInfoPanel.h+1,gfunc.playerInfoPanel.x-1+f*4,gfunc.playerInfoPanel.y+gfunc.playerInfoPanel.h+2) then
	vshowEffDescr, sEffdx, sEffdy = f, ev[3], ev[4]+1
	vseffdescrig = true
	break
	end
   end
  if not vseffdescrig then vshowEffDescr = 0 end
  end
  
  if ev[5] == 0 and cWindowTrd == "pause" then
  gfunc.pauseMenu.action["touch"](ev)
  elseif cWindowTrd == "inventory" then
  gfunc.inventory.action["touch"](ev)
  elseif cWindowTrd == "dialog" then
  gfunc.npcDialog.action["touch"](ev)
  elseif cWindowTrd == "quests" then
  gfunc.questsList.action["touch"](ev)
  elseif cWindowTrd == "console" then
  gfunc.gameConsole.action["touch"](ev)
  elseif cWindowTrd == "pstats" then
  gfunc.playerStats.action["touch"](ev)
  elseif cWindowTrd == "tradewindow" then
  gfunc.tradew.action["touch"](ev)
  elseif cWindowTrd == "craftwindow" then
  gfunc.craftw.action["touch"](ev)
  elseif cWindowTrd == "gfunc.ydw" then
  gfunc.ydw.action["touch"](ev)
  elseif cWindowTrd == "skillsWindow" then
  gfunc.playerSkills.action["touch"](ev)
  end
 end
 if ev[1] == "scroll" then
  if cWindowTrd == "console" then
  gfunc.gameConsole.action["scroll"](ev)
  end
 end
 end
end

thread.create(main)
thread.create(screen)
thread.create(functionPS)
thread.create(funcP4)
thread.create(funcP10)

thread.waitForAll()

gpu.setBackground(0x000000)
gpu.setForeground(0xffffff)
term.clear()
term.setCursor(1,1)
io.write("Wirthe16 — Onslaught of the wraiths / Вторжение зла. "..gfunc.getVersion())
