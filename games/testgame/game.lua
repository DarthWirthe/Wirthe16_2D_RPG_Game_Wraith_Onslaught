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
local gpu =       require("component").gpu
local mxw, mxh = gpu.maxResolution()
local TextVersion = "Версия 1.4.4b"
local pScreenText = "(C) 2016-2017 Wirthe16"
local cScreenStat = "Загрузка..."
local preduprejdenie = ""
local vseNormalno = true
local dir = "/games/testgame/"
local LANGUAGE = "russian"
local debugMode = false
local device = "computer"

gpu.setResolution(mxw,mxh)

thread.init()

local gfunc = {}

local startBckgColour = 0x222222

local ank, lec, sle = 6, 1, nil

if device == "computer" then
ank, lec, sle = 35, 0.05, 0.01
end

local limg = image.load(dir.."image/slg.pic")

for f = 1, ank do
buffer.square(1,1,160,50,startBckgColour,0x000000," ")
buffer.text(2,2,0xA7A7A7,cScreenStat)
limg = image.brightness(limg,math.floor(1.5-lec*f))
buffer.image(80-limg.width/2,25-limg.height/2,limg)
buffer.draw()
os.sleep(sle)
end

ank, lec, sle = nil

limg = math.ceil(computer.totalMemory()/1048576*10)/10

if mxw < 160 or mxh < 50 then 
vseNormalno = false 
preduprejdenie = 'Видеокарта и монитор должны быть 3 уровня.'
end

if limg > 0 and limg < 1.8 then
vseNormalno = false 
preduprejdenie = preduprejdenie..' оперативной памяти ('..limg..' МБ) недостаточно для нормальной работы программы.'
end

local dopInfo = {
"Разрешение экрана только 160х50",
"DoubleBuffering lib by IgorTimofeev",
"Image lib и colorlib by IgorTimofeev",
"Thread lib by Zer0Galaxy",
}

local usram

local function sram()
return tostring(math.floor((computer.totalMemory()-computer.freeMemory())/1024)).." KB/"..tostring(math.ceil(computer.totalMemory()/1048576*10)/10).." MB"
end

local gamefps, cfps = 0, 0

local function readFromFile(path)
local file = io.open(path, 'r')
local array = {}
 for line in file:lines() do
  if line:sub(-1) == "\r" then
  line = line:sub(1, -2)
  end
 table.insert(array, line)
 end
file:close()
return array
end

local function loadLanguage(wPath)
if not fs.exists(wPath) then error("File not exists") end
local ptable = {}
local key, value, dmt1
local len = 0
local f = io.open(wPath, "r")
 for line in f:lines() do
 if not f then return nil end
 len = len + 1
 dmt1 = string.find(line, "@")
 value1 = string.sub(line, 1, dmt1 - 2)
 value2 = string.sub(line, dmt1 + 2, #line)
 table.insert(ptable,{value1, value2})
 end
f:close()
if len == 0 then return nil end
return ptable
end

local function convLang(ptable,value)
local cLang = 2
local newTable = {}
if value == "russian" then cLang = 1 end
 for f = 1, #ptable do
 newTable[ptable[f][1]] = ptable[f][cLang]
 end
return newTable
end
local nlang = {}
if LANGUAGE ~= "russian" then
 local rawlang = loadLanguage(dir.."translate.lang")
 nlang = convLang(rawlang, LANGUAGE) 
end
local function lang(strin)
 if strin and type(nlang[string.gsub(strin, "♦", "")]) == "string" then return nlang[string.gsub(strin, "♦", "")] end
 return strin
 end
 
local aItemIconsSpr
aItemIconsSpr = readFromFile(dir.."itempic.data")

local vAttackDistance

local t_loot = {
["0"]={},
["SIL1_4"] = {
{9,9.33},{10,9.33},{18,4.2},{19,3.2},{20,3},
{3,1},{4,1},{5,1},{6,1},{28,0.5},{29,0.5},{30,0.5},{8,0.6},{62,0.5},{63,0.5}, -- о.д.
},
["SIL5_9"] = {
{11,9.33},{12,9.33},{18,5.4},{19,4.25},{20,4.75},{37,0.4},
{38,0.4},{39,0.4},{40,0.4},{41,0.4},{45,4.5},{49,0.2},{50,0.5},{51,0.2},{52,1.25},
{53,0.1},{54,1.2},{55,0.01},{56,0.1},{57,0.1},{62,0.4},{63,0.4},{75,0.4},
{64,0.4},{31,0.75},{32,0.75},{33,0.75},{34,0.75},{35,0.75},{42,0.3},{43,0.3},{44,0.3},{65,0.4}, -- о.д.
},
["SIL10_14"] = {
{13,9.33},{14,9.33},{18,6.5},{19,4.8},{20,5.5},{64,0.2},{57,0.75},{55,0.01},
{65,0.25},{49,0.2},{50,3},{51,0.72},{52,2},{53,0.25},{54,1.6},{56,0.75},
{75,0.3},{76,0.2},{45,4.8},
{37,0.3},{38,0.3},{39,0.3},{40,0.3},{41,0.3},{59,0.1},{60,0.1},{61,0.1},{70,0.6},{71,0.6},{72,0.6},{73,0.6},{74,0.35},{123,0.35} -- о.д.
},
["SIL15_19"] = {
{15,9.5},{16,9.5},{18,7.2},{19,5.3},{20,6.2},{59,0.125},{60,0.125},{61,0.125},{90,0.05},{45,5.2},
{75,0.2},{49,0.15},{50,6},{51,2.22},{52,4.68},{53,0.3},{54,1.8},{56,0.5},{57,0.5},{55,0.01},
{77,0.2},{78,0.2},{79,0.2},{99,0.375},{100,0.375},{101,0.375},{102,0.375},{103,0.4},{70,0.15},{71,0.15},{72,0.15},{73,0.15},{74,0.2},{76,0.3},{123,0.4} -- о.д.
},
["SIL20_24"] = {
{113,9.2},{114,9.2},{75,0.15},{54,2},{56,0.35},{57,0.35},{55,0.01},{90,0.1},{117,6.63},{118,5.5},{122,5.2},{50,3},{51,1},{52,1.5},
{99,0.2},{100,0.2},{101,0.2},{102,0.2},{103,0.15},{98,0.4}, -- о.д.
},
["phantom"] = {{54,2},{56,1},{57,1},{36,10.3},{64,0.9},{65,0.6},{49,5}},
["flamefiend"] = {{49,5},{51,5},{52,5},{36,5},{45,3}},
["d7miniboss"] = {{13,1.2},{14,1.2},{37,0.2},{38,0.2},{39,0.2},{40,0.2},{41,0.2},{45,1},{36,0.5},{49,0.1},
{50,0.3},{51,0.1},{52,0.1},{55,0.06},{56,0.06},{57,0.06},{64,0.1},{65,0.1},{59,0.08},{60,0.08},{61,0.08}
},
["d7boss"] = {{49,0.1},{50,0.3},{51,0.1},{52,0.1},{67,1},{69,0.05},{59,0.1},{60,0.1},{61,0.1},{46,0.04}},
["d10boss"] = {{49,0.1},{50,1.5},{51,0.1},{52,0.1},{53,0.05},{54,0.1},{56,0.05},{57,0.05},{70,0.03},{71,0.03},
{72,0.03},{73,0.03},{74,0.03},{75,0.05},{76,0.03},{77,0.02},{78,0.02},{79,0.02}},
["d12boss1"] = {{49,0.1},{50,1.5},{51,0.1},{75,0.01},{90,0.05}}
}

local baseWtype = {
"Ходячие трупы","Призраки","Слизни","Дерево","Черепахи","Скелеты", -- 1-6
"Големы","Слабые демоны","Монстр долины 1116","Босс долины 1116","Прочие персонажи","Монстр подземелья 0317", -- 7-12
"Босс подземелья 0317",
}

local gud = {
	{["id"] = 1, ["name"] = "Игрок", ["wtype"] = "Управляемый персонаж", ["lvl"] = 1, ["atds"] = 10, ["criticalhc"] = 1,
	["loot"] = {["exp"] = 0, ["coins"] = 0, ["items"] = "0"}, ["vresp"] = 0, ["rtype"] = "p", ["image"] = "player"},
	{["id"] = 2, ["name"] = "Зомби", ["wtype"] = 1,["lvl"] = 1, ["atds"] = 10,
	["loot"] = {["coins"] = 3, ["items"] = "SIL1_4"},
	["vresp"] = 45, ["rtype"] = "e", ["image"] = "zombie1"},
	{["id"] = 3, ["name"] = "Привидение", ["wtype"] = 2,["lvl"] = 2, ["atds"] = 10,
	["loot"] = {["coins"] = 5, ["items"] = "SIL1_4"},
	["skill"] = {{3,1,10},{2,1,100}}, ["vresp"] = 45, ["rtype"] = "e", ["image"] = "ghost"},
	{["id"] = 4, ["name"] = "Зеленый слизень", ["wtype"] = 3, ["lvl"] = 2, ["atds"] = 10,
	["loot"] = {["coins"] = 4, ["items"] = "SIL1_4"}, 
	["vresp"] = 45, ["rtype"] = "e", ["image"] = "greenslug"},
	{["id"] = 5, ["name"] = "Василий", ["wtype"] = "", ["lvl"] = 0, ["quests"] = {1,2,3,9,10,19,29},
	["vresp"] = 0, ["image"] = "vil1", ["rtype"] = "f",["dialog"] = 1},
	{["id"] = 6, ["name"] = "Зеленый куст", ["wtype"] = 4, ["lvl"] = 3, ["atds"] = 10,
	["loot"] = {["coins"] = 6, ["items"] = "SIL1_4"}, 
	["vresp"] = 45, ["rtype"] = "e", ["image"] = "bush"},
	{["id"] = 7, ["name"] = "Дух места", ["wtype"] = 2, ["lvl"] = 3, ["atds"] = 10,
	["loot"] = {["coins"] = 6, ["items"] = "SIL1_4"},
	["skill"] = {{3,1,10},{2,1,100}}, ["vresp"] = 45, ["rtype"] = "e", ["image"] = "spiritofplace"},
	{["id"] = 8, ["name"] = "Каменная черепаха", ["wtype"] = 5, ["lvl"] = 4, ["atds"] = 9,
	["loot"] = {["coins"] = 7, ["items"] = "SIL1_4"}, 
	["skill"] = {{5,1,1},{1,1,100}}, ["vresp"] = 45, ["rtype"] = "e", ["image"] = "stoneturtle"},
	{["id"] = 9, ["name"] = "Гниющее дерево", ["wtype"] = 4, ["lvl"] = 4, ["atds"] = 10,
	["loot"] = {["coins"] = 7, ["items"] = "SIL1_4"}, 
	["skill"] = {{5,1,1},{1,1,100}},["vresp"] = 45, ["rtype"] = "e", ["image"] = "swamptree"},
	{["id"] = 10, ["name"] = "Тохен Снардил", ["wtype"] = "Аптекарь", ["lvl"] = 0, ["quests"] = {4},
	["vresp"] = 0, ["image"] = "vil2", ["rtype"] = "f",["dialog"] = 2},
	{["id"] = 11, ["name"] = "Лонант Никвал", ["wtype"] = "Кузнец", ["lvl"] = 0, ["quests"] = {16,41},
	["vresp"] = 0, ["image"] = "vil3", ["rtype"] = "f",["dialog"] = 3},
	{["id"] = 12, ["name"] = "Вал Паген", ["wtype"] = "Стражник", ["lvl"] = 0, ["quests"] = nil,
	["vresp"] = 0, ["image"] = "guardian1", ["rtype"] = "f",["dialog"] = 4},
	{["id"] = 13, ["name"] = "Хом Бодинал", ["wtype"] = "Стражник", ["lvl"] = 0, ["quests"] = nil,
	["vresp"] = 0, ["image"] = "guardian1", ["rtype"] = "f",["dialog"] = 5},
	{["id"] = 14, ["name"] = "Болотный вурдалак", ["wtype"] = 1, ["lvl"] = 5, ["atds"] = 10, ["agr"] = true,
	["loot"] = {["exp"] = 15, ["coins"] = 9, ["items"] = "SIL5_9"}, 
	["skill"] = {{5,1,1},{1,1,100}},["vresp"] = 55, ["rtype"] = "e", ["image"] = "venomous_ghoul"},
	{["id"] = 15, ["name"] = "Скелет", ["wtype"] = 6, ["lvl"] = 5, ["atds"] = 10, ["agr"] = true,
	["loot"] = {["coins"] = 9, ["items"] = "SIL5_9"}, 
	["skill"] = {{5,1,1},{1,1,100}},["vresp"] = 55, ["rtype"] = "e", ["image"] = "skelet1"},
	{["id"] = 16, ["name"] = "Подземный вурдалак", ["wtype"] = 1, ["lvl"] = 5, ["atds"] = 10, ["agr"] = true,
	["loot"] = {["coins"] = 8, ["items"] = "SIL5_9"}, 
	["skill"] = {{5,1,1},{1,1,100}},["vresp"] = 85, ["rtype"] = "e", ["image"] = "venomous_ghoul"},
	{["id"] = 17, ["name"] = "Привидение", ["wtype"] = 2, ["lvl"] = 6, ["atds"] = 10, ["agr"] = true,
	["loot"] = {["coins"] = 11, ["items"] = "SIL5_9"}, 
	["skill"] = {{5,1,1},{1,1,100}},["vresp"] = 55, ["rtype"] = "e", ["image"] = "nv_ghost"},
	{["id"] = 18, ["name"] = "Выход", ["wtype"] = "", ["lvl"] = 0, ["quests"] = nil,
	["vresp"] = 0, ["image"] = "tlp1", ["rtype"] = "f",["dialog"] = 6},
	{["id"] = 19, ["name"] = "Каменная стена", ["wtype"] = "", ["lvl"] = 0, ["quests"] = nil,
	["vresp"] = 0, ["image"] = "stne_wall", ["rtype"] = "f",["dialog"] = 7},
	{["id"] = 20, ["name"] = "Учёный из Лусофаема", ["wtype"] = "", ["lvl"] = 0, ["quests"] = {5,15,17},
	["vresp"] = 0, ["image"] = "vil4", ["rtype"] = "f",["dialog"] = 8},
	{["id"] = 21, ["name"] = "Гравий", ["lvl"] = 0, ["reqlvl"] = 1, ["rtype"] = "r", ["image"] = "gravel", ["mnprs"] = 8, ["mxprs"] = 15, ["vresp"] = 750,
	["items"] = {{27,100},{27,1}}, ["coins"] = 0, ["exp"] = 2},
	{["id"] = 22, ["name"] = "Залежи железа", ["lvl"] = 0, ["reqlvl"] = 1, ["rtype"] = "r", ["image"] = "iron_ore", ["mnprs"] = 8, ["mxprs"] = 15, ["vresp"] = 750,
	["items"] = {{2,100},{2,1}}, ["coins"] = 0, ["exp"] = 2},
	{["id"] = 23, ["name"] = "Залежи меди", ["lvl"] = 0, ["reqlvl"] = 1, ["rtype"] = "r", ["image"] = "copper_ore", ["mnprs"] = 8, ["mxprs"] = 15, ["vresp"] = 750,
	["items"] = {{24,100},{24,1}}, ["coins"] = 0, ["exp"] = 2},
	{["id"] = 24, ["name"] = "Старый пень", ["lvl"] = 0, ["reqlvl"] = 1, ["rtype"] = "r", ["image"] = "wooden", ["mnprs"] = 8, ["mxprs"] = 15, ["vresp"] = 750,
	["items"] = {{21,100},{21,1}}, ["coins"] = 0, ["exp"] = 2},
	{["id"] = 25, ["name"] = "Залежи древесного угля", ["lvl"] = 0, ["reqlvl"] = 1, ["rtype"] = "r", ["image"] = "wcoal", ["mnprs"] = 8, ["mxprs"] = 15, ["vresp"] = 750,
	["items"] = {{26,100},{26,1}}, ["coins"] = 0, ["exp"] = 2},
	{["id"] = 26, ["name"] = "Син Толан", ["wtype"] = "Портной", ["lvl"] = 0, ["quests"] = nil,
	["vresp"] = 0, ["image"] = "vil5", ["rtype"] = "f",["dialog"] = 9},
	{["id"] = 27, ["name"] = "Телепорт в восточное поселение", ["wtype"] = "", ["lvl"] = 0, ["quests"] = nil,
	["vresp"] = 0, ["image"] = "tlp1", ["rtype"] = "f",["dialog"] = 10},
	{["id"] = 28, ["name"] = "Телепорт в деревню Зеленый камень", ["wtype"] = "", ["lvl"] = 0, ["quests"] = nil,
	["vresp"] = 0, ["image"] = "tlp1", ["rtype"] = "f",["dialog"] = 11},
	{["id"] = 29, ["name"] = "Разлагающийся ходячий труп", ["wtype"] = 1, ["lvl"] = 5, ["atds"] = 10, ["agr"] = true,
	["loot"] = {["coins"] = 8, ["items"] = "SIL5_9"}, ["vresp"] = 85, ["rtype"] = "e", ["image"] = "dec_ghoul"},
	{["id"] = 30, ["name"] = "Проводник", ["wtype"] = "", ["lvl"] = 0, ["quests"] = {},
	["vresp"] = 0, ["image"] = "vil6", ["rtype"] = "f",["dialog"] = 12},
	{["id"] = 31, ["name"] = "Проход в пещере", ["wtype"] = "", ["lvl"] = 0, ["quests"] = nil,
	["vresp"] = 0, ["image"] = "dungeonexit1", ["rtype"] = "f",["dialog"] = 13},
	{["id"] = 32, ["name"] = "Голем-скалодробитель", ["wtype"] = 7, ["lvl"] = 5, ["atds"] = 10,
	["loot"] = {["coins"] = 0, ["items"] = "SIL5_9"}, 
	["vresp"] = 85, ["rtype"] = "e", ["image"] = "sgolem"},
	{["id"] = 33, ["name"] = "Зачарованный скелет", ["wtype"] = 6, ["lvl"] = 5, ["atds"] = 10, ["agr"] = true,
	["loot"] = {["coins"] = 11, ["items"] = "SIL5_9"}, 
	["skill"] = {{5,1,1},{1,1,100}},["vresp"] = 85, ["rtype"] = "e", ["image"] = "skelet2"},
	{["id"] = 34, ["name"] = "Оживший мертвец", ["wtype"] = 1, ["lvl"] = 6, ["atds"] = 10, ["agr"] = true,
	["loot"] = {["coins"] = 13, ["items"] = "SIL5_9"}, 
	["skill"] = {{5,1,1},{1,1,100}},["vresp"] = 105, ["rtype"] = "e", ["image"] = "zombie2"},
	{["id"] = 35, ["nres"]=true, ["name"] = "Генерал Бездрут", ["wtype"] = 1, ["lvl"] = 5, ["atds"] = 10, ["mhp"] = 914,["agr"] = true,
	["loot"] = {["coins"] = 20, ["items"] = "SIL5_9"}, 
	["skill"] = {{5,1,1},{1,1,100}},["vresp"] = 1536, ["rtype"] = "e", ["image"] = "vangen1"},
	{["id"] = 36, ["name"] = "Расхититель могил", ["wtype"] = 1, ["lvl"] = 6, ["atds"] = 10, ["agr"] = true,
	["loot"] = {["coins"] = 13, ["items"] = "SIL5_9"}, 
	["skill"] = {{5,1,1},{1,1,100}},["vresp"] = 105, ["rtype"] = "e", ["image"] = "graver"},
	{["id"] = 37, ["name"] = "Останки героя", ["wtype"] = 1, ["lvl"] = 6, ["atds"] = 10, ["agr"] = true,
	["loot"] = {["coins"] = 13, ["items"] = "SIL5_9"}, 
	["skill"] = {{5,1,1},{1,1,100}},["vresp"] = 105, ["rtype"] = "e", ["image"] = "skelet3"},
	{["id"] = 38, ["nres"]=true, ["name"] = "Генерал Сутт'ешдпад", ["wtype"] = 1, ["lvl"] = 6, ["atds"] = 10, ["mhp"] = 986,["agr"] = true,
	["loot"] = {["coins"] = 30, ["items"] = "SIL5_9"}, 
	["vresp"] = 1536, ["rtype"] = "e", ["image"] = "vangen2"},
	{["id"] = 39, ["name"] = "Старейшина", ["wtype"] = "", ["lvl"] = 0, ["quests"] = {6,8,18,20},
	["vresp"] = 0, ["image"] = "vil7", ["rtype"] = "f",["dialog"] = 14},
	{["id"] = 40, ["name"] = "Воин из могилы", ["wtype"] = 1, ["lvl"] = 6, ["atds"] = 10, ["agr"] = true,
	["loot"] = {["coins"] = 15, ["items"] = "SIL5_9"}, 
	["skill"] = {{5,1,1},{1,1,100}},["vresp"] = 120, ["rtype"] = "e", ["image"] = "zombie3"},
	{["id"] = 41, ["name"] = "Ревенант", ["wtype"] = 1, ["lvl"] = 6, ["atds"] = 10, ["agr"] = true,
	["loot"] = {["coins"] = 15, ["items"] = "SIL5_9"}, 
	["skill"] = {{5,1,1},{1,1,100}},["vresp"] = 120, ["rtype"] = "e", ["image"] = "zombie4"},
	{["id"] = 42, ["nres"]=true, ["name"] = "Фантом", ["wtype"] = 2, ["lvl"] = 7, ["atds"] = 10, ["mhp"] = 2842,["agr"] = true, 
	["skill"] = {{3,1,10},{2,1,100}}, ["daft_klz"] = {"np"}, ["tcdrop"] = 2, ["loot"] = {["exp"] = 30, ["coins"] = 0, ["items"] = "phantom"}, 
	["vresp"] = 1536, ["rtype"] = "e", ["image"] = "phantom"},
	{["id"] = 43, ["name"] = "Портал", ["wtype"] = "", ["lvl"] = 0, ["tlp"] = "r",
	["image"] = "tportal_1", ["rtype"] = "c"},
	{["id"] = 44, ["name"] = "Суром Канхил", ["wtype"] = "Стражник", ["lvl"] = 0, ["quests"] = nil,
	["vresp"] = 0, ["image"] = "guardian1", ["rtype"] = "f",["dialog"] = 16},
	{["id"] = 45, ["name"] = "Лонант Зерцал", ["wtype"] = "Стражник", ["lvl"] = 0, ["quests"] = {11,12,13,14},
	["vresp"] = 0, ["image"] = "guardian1", ["rtype"] = "f",["dialog"] = 17},
	{["id"] = 46, ["name"] = "Камень телепорта", ["wtype"] = "", ["lvl"] = 0, ["quests"] = nil,
	["vresp"] = 0, ["image"] = "tlpstone", ["rtype"] = "f",["dialog"] = 15},
	{["id"] = 47, ["name"] = "Скелет охотника", ["wtype"] = 6, ["lvl"] = 6, ["atds"] = 10, ["agr"] = true,
	["loot"] = {["coins"] = 12, ["items"] = "SIL5_9"}, ["vresp"] = 55, ["rtype"] = "e", ["image"] = "skelet4"},
	{["id"] = 48, ["name"] = "Цветущее дерево", ["wtype"] = 4, ["lvl"] = 7, ["atds"] = 10, ["skill"] = {{2,1,50},{1,1,100}},
	["loot"] = {["coins"] = 14, ["items"] = "SIL5_9"}, ["vresp"] = 55, ["rtype"] = "e", ["image"] = "flowering_tree"},
	{["id"] = 49, ["name"] = "Красный слизень", ["wtype"] = 3, ["lvl"] = 7, ["atds"] = 10, ["agr"] = true,
	["loot"] = {["coins"] = 14, ["items"] = "SIL5_9"}, ["vresp"] = 55, ["rtype"] = "e", ["image"] = "redslug"},
	{["id"] = 50, ["name"] = "Болотный бес", ["wtype"] = 8, ["lvl"] = 8, ["atds"] = 10, ["agr"] = true, ["skill"] = {{4,1,10},{2,1,50},{1,1,100}},
	["loot"] = {["coins"] = 17, ["items"] = "SIL5_9"}, ["vresp"] = 60, ["rtype"] = "e", ["image"] = "dirty_blobdemon"},
	{["id"] = 51, ["name"] = "Личинка", ["wtype"] = 8, ["lvl"] = 8, ["atds"] = 10, ["agr"] = true, ["skill"] = {{4,1,10},{2,1,50},{1,1,100}},
	["loot"] = {["coins"] = 17, ["items"] = "SIL5_9"}, ["vresp"] = 60, ["rtype"] = "e", ["image"] = "d_maggot"},
	{["id"] = 52, ["name"] = "Железная черепаха", ["wtype"] = 5, ["lvl"] = 9, ["atds"] = 9,
	["loot"] = {["coins"] = 12, ["items"] = "SIL5_9"},
	["vresp"] = 60, ["rtype"] = "e", ["image"] = "ironturtle"},
	{["id"] = 53, ["nres"]=true, ["name"] = "Тлеющий дух", ["wtype"] = 2, ["lvl"] = 10, ["atds"] = 12, ["mhp"] = 1363,["agr"] = true, ["skill"] = {{3,1,5},{2,1,100}},
	["daft_klz"] = {{"sp",54}}, ["tcdrop"] = 5, ["loot"] = {["exp"] = 55, ["coins"] = 0, ["items"] = "flamefiend"}, ["vresp"] = 1636, ["rtype"] = "e", ["image"] = "flamefiend"},
	{["id"] = 54, ["nres"]=true, ["name"] = "Запертый дух", ["wtype"] = 2, ["lvl"] = 10, ["atds"] = 10, ["mhp"] = 1336,["agr"] = true, ["skill"] = {{3,1,5},{2,1,100}},
	["daft_klz"] = {"np"}, ["tcdrop"] = 2, ["loot"] = {["exp"] = 55, ["coins"] = 0, ["items"] = "flamefiend"}, ["vresp"] = 1536, ["rtype"] = "e", ["image"] = "phantom"},
	{["id"] = 55, ["name"] = "Отан Нихцил", ["wtype"] = "Алхимик", ["lvl"] = 0, ["quests"] = {},
	["vresp"] = 0, ["image"] = "vil8", ["rtype"] = "f",["dialog"] = 18},
	{["id"] = 56, ["name"] = "Оживший труп каторжника", ["wtype"] = 1, ["lvl"] = 8, ["atds"] = 10, ["agr"] = true,
	["loot"] = {["coins"] = 6, ["items"] = "SIL5_9"}, ["vresp"] = 620, ["rtype"] = "e", ["image"] = "zombie5"},
	{["id"] = 57, ["name"] = "Кровавый вурдалак", ["wtype"] = 1, ["lvl"] = 9, ["atds"] = 10, ["agr"] = true,
	["loot"] = {["coins"] = 10, ["items"] = "SIL5_9"}, ["vresp"] = 620, ["rtype"] = "e", ["image"] = "deadghoul"},
	{["id"] = 58, ["nres"]=true, ["name"] = "Демон-душеед", ["wtype"] = 8, ["lvl"] = 11, ["atds"] = 10, ["mhp"] = 2837, ["agr"] = true, ["skill"] = {{2,1,50},{1,1,100}},
	["tcdrop"] = 5,["loot"] = {["exp"] = 66, ["coins"] = 0, ["items"] = "d7miniboss"}, ["vresp"] = 99999, ["rtype"] = "e", ["image"] = "odecfaddi"},
	{["id"] = 59, ["nres"]=true, ["name"] = "Нодум Цинтал", ["wtype"] = 1, ["lvl"] = 11, ["atds"] = 10, ["mhp"] = 2463, ["agr"] = true, ["skill"] = {{2,1,50},{1,1,100}},
	["tcdrop"] = 5,["loot"] = {["exp"] = 66, ["coins"] = 25, ["items"] = "d7miniboss"}, ["vresp"] = 99999, ["rtype"] = "e", ["image"] = "vanlt1"},
	{["id"] = 60, ["name"] = "Беспокойный дух", ["wtype"] = 2, ["lvl"] = 9, ["atds"] = 10, ["agr"] = true, ["skill"] = {{3,1,5},{2,1,100}},
	["loot"] = {["coins"] = 10, ["items"] = "SIL5_9"}, ["vresp"] = 620, ["rtype"] = "e", ["image"] = "d_ghost"},
	{["id"] = 61, ["name"] = "Рассыпающийся скелет", ["wtype"] = 6, ["lvl"] = 10, ["atds"] = 10, ["agr"] = true,
	["loot"] = {["coins"] = 15, ["items"] = "SIL10_14"}, ["vresp"] = 620, ["rtype"] = "e", ["image"] = "skelet5"},
	{["id"] = 62, ["name"] = "Выход из пещеры", ["wtype"] = "", ["lvl"] = 0, ["quests"] = nil,
	["vresp"] = 0, ["image"] = "dungeonexit1", ["rtype"] = "f",["dialog"] = 19},
	{["id"] = 63, ["nres"]=true, ["name"] = "Башня демона и силы зла", ["wtype"] = 11, ["lvl"] = 1, ["atds"] = 10, ["mhp"] = 5501, ["skill"] = {{2,1,50},{1,1,100}},
	["cmve"] = true,["loot"] = {["exp"] = 0, ["coins"] = 0, ["items"] = "0"}, ["vresp"] = 8^10, ["rtype"] = "e", ["image"] = "evfotr"},
	{["id"] = 64, ["name"] = "Сумеречный охотник", ["wtype"] = 8, ["lvl"] = 10, ["atds"] = 10, ["agr"] = true,
	["loot"] = {["coins"] = 15, ["items"] = "SIL10_14"}, ["vresp"] = 620, ["rtype"] = "e", ["image"] = "twihnt"},
	{["id"] = 65, ["nres"]=true, ["name"] = "Вердант Канхог'ешсед", ["wtype"] = 1, ["lvl"] = 12, ["atds"] = 10, ["mhp"] = 3156, ["agr"] = true, ["skill"] = {{2,1,50},{1,1,100}},
	["tcdrop"] = 5,["loot"] = {["exp"] = 78, ["coins"] = 25, ["items"] = "d7miniboss"}, ["vresp"] = 99999, ["rtype"] = "e", ["image"] = "vundf"},
	{["id"] = 66, ["nres"]=true, ["name"] = "Боевые доспехи Шана Тессана", ["wtype"] = 2, ["lvl"] = 14, ["atds"] = 10, ["mhp"] = 4673, ["agr"] = true, ["skill"] = {{2,1,50},{1,1,100}},
	["daft_klz"] = {"np"},["tcdrop"] = 10,["loot"] = {["exp"] = 105, ["coins"] = 0, ["items"] = "d7boss"}, ["vresp"] = 99999, ["rtype"] = "e", ["image"] = "wraith_gudini"},
	{["id"] = 67, ["name"] = "Нортум Вадренсал", ["wtype"] = "", ["lvl"] = 0, ["quests"] = {37,38,39},
	["vresp"] = 0, ["image"] = "vil9", ["rtype"] = "f",["dialog"] = 20},
	{["id"] = 68, ["name"] = "Старейшина крепости", ["wtype"] = "", ["lvl"] = 0, ["quests"] = {25,26,27,28,36},
	["vresp"] = 0, ["image"] = "vil7", ["rtype"] = "f",["dialog"] = 21},
	{["id"] = 69, ["name"] = "Тезар Оскенал", ["wtype"] = "Стражник", ["lvl"] = 0, ["quests"] = nil,
	["vresp"] = 0, ["image"] = "guardian1", ["rtype"] = "f",["dialog"] = 22},
	{["id"] = 70, ["name"] = "Джун Каторан", ["wtype"] = "Стражник", ["lvl"] = 0, ["quests"] = {},
	["vresp"] = 0, ["image"] = "guardian1", ["rtype"] = "f",["dialog"] = 23},
	{["id"] = 71, ["name"] = "Ядовитый слизень", ["wtype"] = 3, ["lvl"] = 9, ["atds"] = 10, ["agr"] = true,
	["loot"] = {["coins"] = 12, ["items"] = "SIL5_9"}, ["vresp"] = 55, ["rtype"] = "e", ["image"] = "yellowslug"},
	{["id"] = 72, ["name"] = "Гранитный голем", ["wtype"] = 7, ["lvl"] = 10, ["atds"] = 10, ["agr"] = true,
	["loot"] = {["coins"] = 15, ["items"] = "SIL10_14"}, ["vresp"] = 55, ["rtype"] = "e", ["image"] = "m_golem"},
	{["id"] = 73, ["name"] = "Текамбха-доспех", ["wtype"] = 2, ["lvl"] = 11, ["atds"] = 11, ["agr"] = true, ["skill"] = {{2,1,50},{1,1,100}},
	["loot"] = {["coins"] = 19, ["items"] = "SIL10_14"}, ["vresp"] = 55, ["rtype"] = "e", ["image"] = "bnkt"},
	{["id"] = 74, ["name"] = "Кан Вушен", ["wtype"] = "Комендант", ["lvl"] = 0, ["quests"] = {35,21,22,23,24,42},
	["vresp"] = 0, ["image"] = "csl1", ["rtype"] = "f",["dialog"] = 24},
	{["id"] = 75, ["name"] = "Проклинающий бес", ["wtype"] = 8, ["lvl"] = 12, ["atds"] = 10, ["agr"] = true,
	["loot"] = {["coins"] = 24, ["items"] = "SIL10_14"},
	["skill"] = {{5,1,5},{4,1,10},{6,1,20},{2,1,50},{1,1,100}},["vresp"] = 55, ["rtype"] = "e", ["image"] = "mogeghoul"},
	{["id"] = 76, ["nres"]=true, ["name"] = "Дух равнины", ["wtype"] = 2, ["lvl"] = 15, ["atds"] = 10, ["mhp"] = 5000, ["agr"] = true,
	["loot"] = {["exp"] = 35, ["coins"] = 27, ["items"] = "0"},
	["skill"] = {{5,1,15},{4,1,10},{2,1,100}},["vresp"] = 8^5, ["rtype"] = "e", ["image"] = "kt_ghost"},
	{["id"] = 77, ["name"] = "Скелет разбойника", ["wtype"] = 6, ["lvl"] = 12, ["atds"] = 10, ["agr"] = true,
	["loot"] = {["coins"] = 24, ["items"] = "SIL10_14"}, ["vresp"] = 55, ["rtype"] = "e", ["image"] = "skelet6"},
	{["id"] = 78, ["name"] = "Дух раскопанной могилы", ["wtype"] = 7, ["lvl"] = 13, ["atds"] = 10, ["agr"] = true,
	["loot"] = {["coins"] = 28, ["items"] = "SIL10_14"}, ["vresp"] = 55, ["rtype"] = "e", ["image"] = "deihghoul"},
	{["id"] = 79, ["name"] = "Выход", ["wtype"] = "", ["lvl"] = 0, ["quests"] = nil,
	["vresp"] = 0, ["image"] = "tlp1", ["rtype"] = "f",["dialog"] = 25},
	{["id"] = 80, ["name"] = "Блуждающий темный дух", ["wtype"] = 9, ["lvl"] = 12, ["atds"] = 10, ["mhp"] = 1040, ["agr"] = true,
	["loot"] = {["coins"] = 9, ["items"] = "SIL15_19"},
	["skill"] = {{3,1,5},{2,1,100}}, ["vresp"] = 900, ["rtype"] = "e", ["image"] = "c_ghost"},
	{["id"] = 81, ["name"] = "Монстр в железной маске", ["wtype"] = 9, ["lvl"] = 12, ["atds"] = 10, ["mhp"] = 1085, ["agr"] = true,
	["loot"] = {["coins"] = 9, ["items"] = "SIL15_19"},
	["vresp"] = 900, ["rtype"] = "e", ["image"] = "rdwarrior"},
	{["id"] = 82, ["name"] = "Страж горной долины", ["wtype"] = 9, ["lvl"] = 13, ["atds"] = 10, ["mhp"] = 1300, ["agr"] = true,
	["loot"] = {["coins"] = 10, ["items"] = "SIL15_19"},
	["vresp"] = 900, ["rtype"] = "e", ["image"] = "mvalgr"},
	{["id"] = 83, ["name"] = "Заклинатель духов земли", ["wtype"] = 9, ["lvl"] = 13, ["atds"] = 10, ["mhp"] = 1250, ["agr"] = true,
	["loot"] = {["coins"] = 10, ["items"] = "SIL15_19"},
	["skill"] = {{7,1,12},{2,1,70},{1,1,100}}, ["vresp"] = 900, ["rtype"] = "e", ["image"] = "mvaltghoul"},
	{["id"] = 84, ["name"] = "Поврежденный дух доспеха", ["wtype"] = 9, ["lvl"] = 14, ["atds"] = 10, ["mhp"] = 1510, ["agr"] = true,
	["loot"] = {["coins"] = 11, ["items"] = "SIL15_19"},
	["vresp"] = 900, ["rtype"] = "e", ["image"] = "mvalwr"},
	{["id"] = 85, ["nres"]=true, ["name"] = "Башня темной земли", ["wtype"] = 11, ["lvl"] = 1, ["atds"] = 10, ["mhp"] = 12001, ["agr"] = true, ["skill"] = {{2,1,100}},
	["cmve"] = true,["loot"] = {["exp"] = 0, ["coins"] = 0, ["items"] = "0"}, ["vresp"] = 8^10, ["rtype"] = "e", ["image"] = "evfmv"},
	{["id"] = 86, ["name"] = "Блуждающий зомби", ["wtype"] = 9, ["lvl"] = 15, ["atds"] = 10, ["mhp"] = 1480, ["agr"] = true,
	["loot"] = {["coins"] = 12, ["items"] = "SIL15_19"},
	["vresp"] = 900, ["rtype"] = "e", ["image"] = "zombie6"},
	{["id"] = 87, ["name"] = "Оживший труп", ["wtype"] = 9, ["lvl"] = 15, ["atds"] = 10, ["mhp"] = 1760, ["agr"] = true,
	["loot"] = {["coins"] = 12, ["items"] = "SIL15_19"},
	["skill"] = {{7,1,5},{1,1,100}}, ["vresp"] = 900, ["rtype"] = "e", ["image"] = "zombie7"},
	{["id"] = 88, ["name"] = "Колдун из мира теней", ["wtype"] = 10, ["lvl"] = 20, ["atds"] = 12, ["mhp"] = 18620, ["agr"] = true,
	["tcdrop"] = 10, ["loot"] = {["exp"] = 60, ["coins"] = 42, ["items"] = "d10boss",["drop"]={{80,18.3}}},
	["skill"] = {{7,1,1},{6,1,1},{7,1,1},{2,1,60},{1,1,100}}, ["vresp"] = 8^5, ["rtype"] = "e", ["image"] = "mvalnecwraith"},
	{["id"] = 89, ["name"] = "Сундук", ["lvl"] = 0, ["reqlvl"] = 1, ["rtype"] = "r", ["image"] = "chest1", ["mnprs"] = 5, ["mxprs"] = 20, ["vresp"] = 8^5,
	["items"] = {{55,5},{56,5},{57,5},{75,2},{49,5},{50,8},{51,5},{52,5},{67,3}}, ["coins"] = 0, ["exp"] = 0},
	{["id"] = 90, ["name"] = "Узник горной долины", ["wtype"] = 9, ["lvl"] = 16, ["atds"] = 10, ["mhp"] = 1770, ["agr"] = true,
	["loot"] = {["coins"] = 12, ["items"] = "SIL15_19"},
	["skill"] = {{7,1,10},{1,1,100}}, ["vresp"] = 900, ["rtype"] = "e", ["image"] = "dohbenages"},
	{["id"] = 91, ["name"] = "Блуждающий труп воина", ["wtype"] = 9, ["lvl"] = 16, ["atds"] = 10, ["mhp"] = 1770, ["agr"] = true,
	["loot"] = {["coins"] = 12, ["items"] = "SIL15_19"},
	["vresp"] = 900, ["rtype"] = "e", ["image"] = "bkmanwr"},
	{["id"] = 92, ["name"] = "Древний заколдованный доспех", ["wtype"] = 10, ["lvl"] = 20, ["atds"] = 12, ["mhp"] = 18620, ["agr"] = true,
	["tcdrop"] = 10, ["loot"] = {["exp"] = 60, ["coins"] = 50, ["items"] = "d10boss",["drop"]={{81,18.3}}},
	["skill"] = {{7,1,1},{6,1,1},{7,1,1},{2,1,60},{1,1,100}}, ["vresp"] = 8^5, ["rtype"] = "e", ["image"] = "slrenow"},
	{["id"] = 93, ["name"] = "Прислужник горной долины", ["wtype"] = 9, ["lvl"] = 16, ["atds"] = 10, ["mhp"] = 1900, ["agr"] = true,
	["loot"] = {["coins"] = 12, ["items"] = "SIL15_19"}, ["vresp"] = 900, ["rtype"] = "e", ["image"] = "udegefn"},
	{["id"] = 94, ["name"] = "Таинственный жрец", ["wtype"] = 10, ["lvl"] = 20, ["atds"] = 12, ["mhp"] = 18620, ["agr"] = true,
	["tcdrop"] = 10, ["loot"] = {["exp"] = 60, ["coins"] = 51, ["items"] = "d10boss",["drop"]={{82,18.3}}},
	["skill"] = {{7,1,1},{6,1,1},{7,1,1},{2,1,60},{1,1,100}}, ["vresp"] = 8^5, ["rtype"] = "e", ["image"] = "mvalfwarrior"},
	{["id"] = 95, ["name"] = "Искатель кристаллов", ["wtype"] = 9, ["lvl"] = 17, ["atds"] = 10, ["mhp"] = 1890, ["agr"] = true,
	["loot"] = {["coins"] = 16, ["items"] = "SIL15_19"},
	["skill"] = {{6,1,20},{2,1,100}}, ["vresp"] = 900, ["rtype"] = "e", ["image"] = "mfghost"},
	{["id"] = 96, ["name"] = "Древнее божество горной долины", ["wtype"] = 10, ["lvl"] = 25, ["atds"] = 12, ["mhp"] = 24560, ["agr"] = true,
	["daft_klz"] = {{"sp",100}}, ["tcdrop"] = 5, ["loot"] = {["exp"] = 99, ["coins"] = 60, ["items"] = "d10boss",["drop"]={{83,25}}},
	["skill"] = {{7,1,1},{6,1,1},{7,1,1},{2,1,100}}, ["vresp"] = 8^5, ["rtype"] = "e", ["image"] = "mvalwoodenspirit"},
	{["id"] = 97, ["name"] = "Портал", ["wtype"] = "", ["lvl"] = 0, ["tlp"] = {11,1},
	["image"] = "tportal_1", ["rtype"] = "c"},
	{["id"] = 98, ["name"] = "Портал", ["wtype"] = "", ["lvl"] = 0, ["tlp"] = {10,1},
	["image"] = "tportal_1", ["rtype"] = "c"},
	{["id"] = 99, ["name"] = "Превосходный кузнец", ["wtype"] = "", ["lvl"] = 0, ["quests"] = {},
	["vresp"] = 0, ["image"] = "vil10", ["rtype"] = "f",["dialog"] = 26},
	{["id"] = 100, ["nres"]=true, ["name"] = "", ["wtype"] = 9, ["lvl"] = 25, ["atds"] = 12, ["mhp"] = 4999, ["agr"] = true,
	["tcdrop"] = 1, ["loot"] = {["exp"] = 50, ["coins"] = 0, ["items"] = "0",["drop"]={{83,5},{87,5}}},
	["skill"] = {{2,1,100}}, ["vresp"] = 8^5, ["rtype"] = "e", ["image"] = "mvalfsphere"},
	{["id"] = 101, ["name"] = "Древний бес", ["wtype"] = 12, ["lvl"] = 14, ["atds"] = 10, ["hpmul"] = 2.5, ["agr"] = true,
	["loot"] = {["coins"] = 9, ["items"] = "SIL10_14"},
	["skill"] = {{7,1,20},{2,1,100}}, ["vresp"] = 900, ["rtype"] = "e", ["image"] = "nwdeu"},
	{["id"] = 102, ["name"] = "Призрачный страж храма", ["wtype"] = 12, ["lvl"] = 14, ["atds"] = 10, ["hpmul"] = 2.6, ["agr"] = true,
	["loot"] = {["coins"] = 11, ["items"] = "SIL10_14"},
	["skill"] = {{2,1,100}}, ["vresp"] = 900, ["rtype"] = "e", ["image"] = "nwdugt"},
	{["id"] = 103, ["name"] = "Синт Штемлур", ["wtype"] = 13, ["lvl"] = 20, ["atds"] = 10, ["mhp"] = 12560, ["agr"] = true,
	["tcdrop"] = 5, ["loot"] = {["exp"] = 35, ["coins"] = 5, ["items"] = "d12boss1",["drop"]={{80,18.3}}},
	["skill"] = {{2,1,100}}, ["vresp"] = 8^5, ["rtype"] = "e", ["image"] = "acasmwraith"},
	{["id"] = 104, ["nres"]=true, ["name"] = "Башня песка", ["wtype"] = 11, ["lvl"] = 1, ["atds"] = 10, ["mhp"] = 11998, ["skill"] = {{2,1,100}},
	["cmve"] = true,["loot"] = {["exp"] = 0, ["coins"] = 0, ["items"] = "0"}, ["vresp"] = 8^10, ["rtype"] = "e", ["image"] = "evfmv"},
	{["id"] = 105, ["name"] = "Повелитель бронзовых статуй", ["wtype"] = 13, ["lvl"] = 20, ["atds"] = 10, ["mhp"] = 20371, ["agr"] = true,
	["tcdrop"] = 10, ["loot"] = {["exp"] = 70, ["coins"] = 14, ["items"] = "d12boss1",["drop"]={{81,18.3},{83,1}}},
	["skill"] = {{2,1,100}}, ["vresp"] = 8^5, ["rtype"] = "e", ["image"] = "dvabwthlit"},
	{["id"] = 106, ["name"] = "Глиняный дух", ["wtype"] = 12, ["lvl"] = 15, ["atds"] = 10, ["hpmul"] = 2.6, ["agr"] = true,
	["loot"] = {["coins"] = 12, ["items"] = "SIL15_19"},
	["vresp"] = 900, ["rtype"] = "e", ["image"] = "ducstoneemb"},
	{["id"] = 107, ["name"] = "Волшебный бронзовый страж", ["wtype"] = 12, ["lvl"] = 16, ["atds"] = 10, ["hpmul"] = 2.7, ["agr"] = true,
	["loot"] = {["coins"] = 12, ["items"] = "SIL15_19"},
	["vresp"] = 900, ["rtype"] = "e", ["image"] = "tlform"},
	{["id"] = 108, ["name"] = "Волшебный щит", ["wtype"] = 12, ["lvl"] = 18, ["atds"] = 10, ["hpmul"] = 6.4, ["agr"] = true,
	["loot"] = {["coins"] = 14, ["items"] = "SIL15_19"},
	["vresp"] = 900, ["rtype"] = "e", ["image"] = "tlwrarikle"},
	{["id"] = 109, ["name"] = "Чернокнижник", ["wtype"] = 12, ["lvl"] = 19, ["atds"] = 10, ["hpmul"] = 8.7, ["agr"] = true,
	["loot"] = {["coins"] = 14, ["items"] = "SIL15_19"},
	["skill"] = {{8,1,10},{10,1,10},{2,1,100}},["vresp"] = 900, ["rtype"] = "e", ["image"] = "tlwhwrihgan"},
	{["id"] = 110, ["name"] = "Вход", ["wtype"] = "", ["lvl"] = 0, ["tlp"] = {13,1},
	["image"] = "hallway_gate", ["rtype"] = "c"},
	{["id"] = 111, ["name"] = "Выход", ["wtype"] = "", ["lvl"] = 0, ["tlp"] = {12,2060},
	["image"] = "hallway_gate", ["rtype"] = "c"},
	{["id"] = 112, ["name"] = "Нечеловеческий", ["wtype"] = 13, ["lvl"] = 22, ["atds"] = 10, ["mhp"] = 15869, ["agr"] = true,
	["tcdrop"] = 15, ["loot"] = {["exp"] = 90, ["coins"] = 25, ["items"] = "d12boss1",["drop"]={{94,23.8},{82,18.3},{83,0.92},{83,1}}},
	["skill"] = {{8,1,25},{9,1,25},{2,1,75},{1,1,100}}, ["vresp"] = 8^5, ["rtype"] = "e", ["image"] = "tmlwemoduncelg"},
	{["id"] = 113, ["name"] = "Гнилой дух", ["wtype"] = 12, ["lvl"] = 19, ["atds"] = 10, ["hpmul"] = 3.8, ["agr"] = true,
	["loot"] = {["coins"] = 12, ["items"] = "SIL20_24",["drop"]={{50,8.15},{51,4.43},{52,8.15}}},
	["vresp"] = 900, ["rtype"] = "e", ["image"] = "darkenemsoul"},
	{["id"] = 114, ["name"] = "Магический воин", ["wtype"] = 12, ["lvl"] = 20, ["atds"] = 10, ["hpmul"] = 3.4, ["agr"] = true,
	["loot"] = {["coins"] = 15, ["items"] = "SIL20_24",["drop"]={{50,8.22},{51,4.56},{52,8.22}}},
	["vresp"] = 900, ["rtype"] = "e", ["image"] = "utwancientinwat"},
	{["id"] = 115, ["name"] = "Сипри Соруим", ["wtype"] = 13, ["lvl"] = 30, ["atds"] = 10, ["mhp"] = 15105, ["ptk"] = {4,14}, ["mtk"] = {16,28}, ["agr"] = true,
	["daft_klz"] = {{"sp",118}}, ["tcdrop"] = 12, ["loot"] = {["exp"] = 80, ["coins"] = 50, ["items"] = "d12boss1",["drop"]={{94,15.75},{95,7.5},{80,4.2},{83,2.38}}},
	["skill"] = {{2,1,50},{1,1,100}}, ["vresp"] = 8^5, ["rtype"] = "e", ["image"] = "sudishesitrim"},
	{["id"] = 116, ["name"] = "Сипри Соруим", ["wtype"] = 13, ["lvl"] = 30, ["atds"] = 10, ["mhp"] = 22624, ["ptk"] = {7,20}, ["mtk"] = {21,34}, ["agr"] = true,
	["daft_klz"] = {{"sp",119}}, ["tcdrop"] = 12, ["loot"] = {["exp"] = 130, ["coins"] = 60, ["items"] = "d12boss1",["drop"]={{94,20},{95,15.25},{80,5.6},{83,3.12}}},
	["skill"] = {{2,1,50},{1,1,100}}, ["vresp"] = 8^5, ["rtype"] = "e", ["image"] = "sudishesitrim"},
	{["id"] = 117, ["name"] = "Сипри Соруим", ["wtype"] = 13, ["lvl"] = 30, ["atds"] = 10, ["mhp"] = 31070, ["ptk"] = {11,28}, ["mtk"] = {25,45}, ["agr"] = true,
	["tcdrop"] = 12, ["loot"] = {["exp"] = 200, ["coins"] = 80, ["items"] = "d12boss1",["drop"]={{94,28.33},{95,18.31},{80,5.5},{83,3.48}}},
	["skill"] = {{2,1,50},{1,1,100}}, ["vresp"] = 8^5, ["rtype"] = "e", ["image"] = "sudishesitrim"},
	{["id"] = 118, ["name"] = "Призыв босса - Лорд Сипри", ["wtype"] = 11, ["lvl"] = 1, ["atds"] = 10, ["mhp"] = 2599,
	["daft_klz"] = {{"sp",116}}, ["cmve"] = true, ["loot"] = {["exp"] = 1, ["coins"] = 1, ["items"] = "0"},
	["skill"] = {{2,1,100}}, ["vresp"] = 8^5, ["rtype"] = "e", ["image"] = "c_ghost"},
	{["id"] = 119, ["name"] = "Призыв босса - Лорд Сипри", ["wtype"] = 11, ["lvl"] = 1, ["atds"] = 10, ["mhp"] = 3499,
	["daft_klz"] = {{"sp",117}}, ["cmve"] = true, ["loot"] = {["exp"] = 1, ["coins"] = 1, ["items"] = "0"},
	["skill"] = {{2,1,100}}, ["vresp"] = 8^5, ["rtype"] = "e", ["image"] = "c_ghost"},
	{["id"] = 120, ["name"] = "Соттах-Еснад", ["wtype"] = 13, ["lvl"] = 32, ["atds"] = 10, ["mhp"] = 18781, ["ptk"] = {6,18}, ["mtk"] = {18,30}, ["agr"] = true,
	["tcdrop"] = 12, ["loot"] = {["exp"] = 100, ["coins"] = 75, ["items"] = "d12boss1",["drop"]={{94,12.5},{96,1.6},{81,0.75},{83,1.99}}},
	["skill"] = {{2,1,65},{1,1,100}}, ["vresp"] = 8^5, ["rtype"] = "e", ["image"] = "tlwmu"},
	{["id"] = 121, ["name"] = "Могущественный • Эмиссар Соттах-Еснад", ["wtype"] = 13, ["lvl"] = 32, ["atds"] = 14, ["mhp"] = 23500, ["ptk"] = {10,25}, ["mtk"] = {23,41}, ["agr"] = true,
	["tcdrop"] = 12, ["loot"] = {["exp"] = 200, ["coins"] = 93, ["items"] = "d12boss1",["drop"]={{94,10.5},{97,2.36},{96,3.55},{81,1.2},{83,2.33}}},
	["skill"] = {{2,1,65},{1,1,100}}, ["vresp"] = 8^5, ["rtype"] = "e", ["image"] = "tlwmu"},
	{["id"] = 122, ["name"] = "Призыв босса - Соттах-Еснад", ["wtype"] = 11, ["lvl"] = 1, ["atds"] = 14, ["mhp"] = 3800,
	["daft_klz"] = {{"sp",121}}, ["cmve"] = true, ["loot"] = {["exp"] = 1, ["coins"] = 1, ["items"] = "0"},
	["skill"] = {{2,1,100}}, ["vresp"] = 8^5, ["rtype"] = "e", ["image"] = "tlform"},
	{["id"] = 123, ["name"] = "Пехотинец", ["wtype"] = 12, ["lvl"] = 18, ["atds"] = 10, ["agr"] = true,
	["loot"] = {["coins"] = 12, ["items"] = "SIL15_19"},["vresp"] = 900, ["rtype"] = "e", ["image"] = "infantryman"},
	{["id"] = 124, ["name"] = "Забытая шкатулка", ["lvl"] = 0, ["reqlvl"] = 15, ["rtype"] = "r", ["image"] = "chest1", ["mnprs"] = 5, ["mxprs"] = 20, ["vresp"] = 8^5,
	["items"] = {{90,35},{94,20},{87,5.75}}, ["coins"] = 0, ["exp"] = 25},
	{["id"] = 125, ["name"] = "Камень перемещения", ["wtype"] = "", ["lvl"] = 0, ["tlp"] = {8,1},
	["image"] = "tlpstone", ["rtype"] = "c"},
	{["id"] = 126, ["name"] = "Превосходный портной", ["wtype"] = "", ["lvl"] = 0, ["quests"] = {40},
	["vresp"] = 0, ["image"] = "vil11", ["rtype"] = "f",["dialog"] = 27},
	{["id"] = 127, ["name"] = "Портал", ["wtype"] = "", ["lvl"] = 0, ["tlp"] = {14,1},
	["image"] = "tportal_1", ["rtype"] = "c"},
	{["id"] = 128, ["name"] = "Портал", ["wtype"] = "", ["lvl"] = 0, ["tlp"] = {13,3024},
	["image"] = "tportal_1", ["rtype"] = "c"},
	{["id"] =129, ["name"] = "Шлифовальный камень", ["lvl"] = 0, ["reqlvl"] = 15, ["rtype"] = "r", ["image"] = "gravel", ["mnprs"] = 8, ["mxprs"] = 15, ["vresp"] = 750,
	["items"] = {{121,100},{121,1}}, ["coins"] = 0, ["exp"] = 10},
	{["id"] =130, ["name"] = "Залежи чёрного железа", ["lvl"] = 0, ["reqlvl"] = 15, ["rtype"] = "r", ["image"] = "iron_ore", ["mnprs"] = 8, ["mxprs"] = 15, ["vresp"] = 750,
	["items"] = {{46,100},{46,1}}, ["coins"] = 0, ["exp"] = 10},
	{["id"] =131, ["name"] = "Древесный ствол", ["lvl"] = 0, ["reqlvl"] = 15, ["rtype"] = "r", ["image"] = "wooden", ["mnprs"] = 8, ["mxprs"] = 15, ["vresp"] = 750,
	["items"] = {{119,100},{119,1}}, ["coins"] = 0, ["exp"] = 10},
	{["id"] =132, ["name"] = "Залежи каменного угля", ["lvl"] = 0, ["reqlvl"] = 15, ["rtype"] = "r", ["image"] = "wcoal", ["mnprs"] = 8, ["mxprs"] = 15, ["vresp"] = 750,
	["items"] = {{120,100},{120,1}}, ["coins"] = 0, ["exp"] = 10},
	{["id"] = 133, ["name"] = "Одвук Кинин", ["wtype"] = "Аптекарь", ["lvl"] = 0, ["quests"] = {},
	["vresp"] = 0, ["image"] = "vil2", ["rtype"] = "f",["dialog"] = 28},
	{["id"] = 134, ["name"] = "Прун Тогенак", ["wtype"] = "Кузнец", ["lvl"] = 0, ["quests"] = {},
	["vresp"] = 0, ["image"] = "vil3", ["rtype"] = "f",["dialog"] = 29},
	{["id"] = 135, ["name"] = "Тинон Хокил", ["wtype"] = "Стражник", ["lvl"] = 0, ["quests"] = nil,
	["vresp"] = 0, ["image"] = "guardian1", ["rtype"] = "f",["dialog"] = 30},
	{["id"] = 136, ["name"] = "Махтий Зомерал", ["wtype"] = "Аптекарь", ["lvl"] = 0, ["quests"] = {},
	["vresp"] = 0, ["image"] = "vil2", ["rtype"] = "f",["dialog"] = 28},
	{["id"] = 137, ["name"] = "Шим Тарнодан", ["wtype"] = "Кузнец", ["lvl"] = 0, ["quests"] = {},
	["vresp"] = 0, ["image"] = "vil3", ["rtype"] = "f",["dialog"] = 29},
	{["id"] = 138, ["name"] = "Панорат Кхинкан", ["wtype"] = "Портной", ["lvl"] = 0, ["quests"] = nil,
	["vresp"] = 0, ["image"] = "vil5", ["rtype"] = "f",["dialog"] = 9},
	{["id"] = 139, ["name"] = "Кан Воко", ["wtype"] = "Стражник", ["lvl"] = 0, ["quests"] = nil,
	["vresp"] = 0, ["image"] = "guardian1", ["rtype"] = "f",["dialog"] = 31},
	{["id"] = 140, ["name"] = "Одвук Цертан", ["wtype"] = "Стражник", ["lvl"] = 0, ["quests"] = nil,
	["vresp"] = 0, ["image"] = "guardian1", ["rtype"] = "f",["dialog"] = 32},
}

for f = 1, #gud do
gud[f]["name"] = lang(gud[f]["name"])
if gud[f]["name"] == "" then gud[f]["name"] = "Без названия" end
 if gud[f]["loot"] and not gud[f]["loot"]["exp"] then
 gud[f]["loot"]["exp"] = gud[f]["lvl"] * 5
 end
if gud[f]["rtype"] == "e" and not gud[f]["skill"] then gud[f]["skill"] = {{1,1,100}} end
os.sleep()
end

local gid = {
	{["name"] = "Медь", ["type"] = "item", ["subtype"] = "res", ["description"] = "Металл начального уровня",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 7, ["icon"] = 1, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Железо", ["type"] = "item", ["subtype"] = "res", ["description"] = "Металл начального уровня",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 7, ["icon"] = 2, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Шлем новобранца", ["lvl"] = 1, ["type"] = "armor", ["subtype"] = "helmet", ["reqlvl"] = 1, ["description"] = "",
	["props"] = {}, ["cost"] = 5, ["icon"] = 5, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Доспех новобранца", ["lvl"] = 1, ["type"] = "armor", ["subtype"] = "bodywear", ["reqlvl"] = 1, ["description"] = "",
	["props"] = {}, ["cost"] = 5, ["icon"] = 3, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Брюки новобранца", ["lvl"] = 1, ["type"] = "armor", ["subtype"] = "pants", ["reqlvl"] = 1, ["description"] = "",
	["props"] = {}, ["cost"] = 5, ["icon"] = 4, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Сапоги новобранца", ["lvl"] = 1, ["type"] = "armor", ["subtype"] = "footwear", ["reqlvl"] = 1, ["description"] = "",
	["props"] = {}, ["cost"] = 5, ["icon"] = 6, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Деревянный меч", ["lvl"] = 1, ["type"] = "weapon", ["subtype"] = "sword", ["reqlvl"] = 1, ["description"] = "",
	["props"] = {["atds"] = 10, ["phisat"] = {5,9}}, ["cost"] = 1, ["icon"] = 7, ["ncolor"] = 0xFFFF00},
	{["name"] = "Ожерелье из волчьей кости", ["lvl"] = 1, ["type"] = "armor", ["subtype"] = "pendant", ["reqlvl"] = 1, ["description"] = "",
	["props"] = {}, ["stackable"] = false, ["cost"] = 6, ["icon"] = 8, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Малое исцеляющее зелье", ["type"] = "potion", ["subtype"] = "health", ["reqlvl"] = 1, ["description"] = "",
	["props"] = 1, ["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 1, ["icon"] = 9, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Малое бодрящее зелье", ["type"] = "potion", ["subtype"] = "mana", ["reqlvl"] = 1, ["description"] = "",
	["props"] = 1, ["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 1, ["icon"] = 10, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Среднее исцеляющее зелье", ["type"] = "potion", ["subtype"] = "health", ["reqlvl"] = 5, ["description"] = "",
	["props"] = 1, ["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 2, ["cost"] = 2, ["icon"] = 11, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Среднее бодрящее зелье", ["type"] = "potion", ["subtype"] = "mana", ["reqlvl"] = 5, ["description"] = "",
	["props"] = 1, ["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 2, ["cost"] = 2, ["icon"] = 12, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Большое исцеляющее зелье", ["type"] = "potion", ["subtype"] = "health", ["reqlvl"] = 10, ["description"] = "",
	["props"] = 1, ["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 3, ["cost"] = 3, ["icon"] = 13, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Большое бодрящее зелье", ["type"] = "potion", ["subtype"] = "mana", ["reqlvl"] = 10, ["description"] = "",
	["props"] = 1, ["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 3, ["cost"] = 3, ["icon"] = 14, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Концентрированное исцеляющее зелье", ["type"] = "potion", ["subtype"] = "health", ["reqlvl"] = 15, ["description"] = "",
	["props"] = 1, ["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 4, ["cost"] = 4, ["icon"] = 15, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Концентрированное бодрящее зелье", ["type"] = "potion", ["subtype"] = "mana", ["reqlvl"] = 15, ["description"] = "",
	["props"] = 1, ["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 4, ["cost"] = 4, ["icon"] = 16, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Грубая шкура животного", ["type"] = "item", ["subtype"] = "res", ["description"] = "Может быть использован для крафта",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 3, ["icon"] = 17, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Мягкий мех", ["type"] = "item", ["subtype"] = "res", ["description"] = "Может быть использован для крафта",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 5, ["icon"] = 18, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Грубая нить", ["type"] = "item", ["subtype"] = "res", ["description"] = "Нить начального уровня",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 5, ["icon"] = 19, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Необработанная кожа", ["type"] = "item", ["subtype"] = "res", ["description"] = "Кожа начального уровня",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 6, ["icon"] = 20, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Необработанная древесина", ["type"] = "item", ["subtype"] = "res", ["description"] = "Древесина начального уровня",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 4, ["icon"] = 21, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Коробка", ["type"] = "chest", ["subtype"] = "none", ["cost"] = 1, ["description"] = "Нажмите ПКМ чтобы открыть",
	["props"] = {{9,5,14.2},{10,5,14.2},{3,1,14.2},{4,1,14.2},{5,1,14.2},{6,1,14.2},{8,1,14.2},{9,1,100}}, 
	["stackable"] = false, ["icon"] = 22, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Телепортирующая частица", ["type"] = "tlp", ["subtype"] = "none", ["description"] = "Телепортирует к началу",
	["stackable"] = true, ["maxstack"] = 99, ["cost"] = 1, ["icon"] = 23, ["ncolor"] = 0x00C232},
	{["name"] = "Медная руда", ["type"] = "item", ["subtype"] = "res", ["description"] = "Перерабатываемое сырьё",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 2, ["icon"] = 24, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Железная руда", ["type"] = "item", ["subtype"] = "res", ["description"] = "Перерабатываемое сырьё",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 2, ["icon"] = 25, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Древесный уголь", ["type"] = "item", ["subtype"] = "res", ["description"] = "Топливо начального уровня",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 5, ["icon"] = 26, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Гравий", ["type"] = "item", ["subtype"] = "res", ["description"] = "Камень начального уровня",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 3, ["icon"] = 27, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Длинный меч", ["lvl"] = 1, ["type"] = "weapon", ["subtype"] = "sword", ["reqlvl"] = 2, ["description"] = "",
	["props"] = {["atds"] = 10, ["phisat"] = {25,34}}, ["cost"] = 14, ["icon"] = 29, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Легкое копье", ["lvl"] = 1, ["type"] = "weapon", ["subtype"] = "spear", ["reqlvl"] = 2, ["description"] = "",
	["props"] = {["atds"] = 14, ["phisat"] = {22,30}}, ["cost"] = 14, ["icon"] = 28, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Короткий каменный топор", ["lvl"] = 1, ["type"] = "weapon", ["subtype"] = "axe", ["reqlvl"] = 2, ["description"] = "",
	["props"] = {["atds"] = 9, ["phisat"] = {28,41}}, ["cost"] = 14, ["icon"] = 30, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Легкий боевой шлем", ["lvl"] = 2, ["type"] = "armor", ["subtype"] = "helmet", ["reqlvl"] = 5, ["description"] = "",
	["props"] = {}, ["cost"] = 23, ["icon"] = 31, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Доспех из кожи", ["lvl"] = 2, ["type"] = "armor", ["subtype"] = "bodywear", ["reqlvl"] = 5, ["description"] = "",
	["props"] = {}, ["cost"] = 27, ["icon"] = 32, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Брюки из кожи", ["lvl"] = 2, ["type"] = "armor", ["subtype"] = "pants", ["reqlvl"] = 5, ["description"] = "",
	["props"] = {}, ["cost"] = 25, ["icon"] = 33, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Кожаные сапоги", ["lvl"] = 2, ["type"] = "armor", ["subtype"] = "footwear", ["reqlvl"] = 5, ["description"] = "",
	["props"] = {}, ["cost"] = 25, ["icon"] = 34, ["ncolor"] = 0xFFFFFF},	
	{["name"] = "Волшебный кулон", ["lvl"] = 2, ["type"] = "armor", ["subtype"] = "pendant", ["reqlvl"] = 6, ["description"] = "",
	["props"] = {}, ["cost"] = 36, ["icon"] = 35, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Коробка", ["type"] = "chest", ["subtype"] = "none", ["cost"] = 1, ["description"] = "Нажмите ПКМ чтобы открыть",
	["props"] = {{11,5,14.2},{12,5,14.2},{31,1,14.2},{32,1,14.2},{34,1,14.2},{35,1,14.2},{42,1,6.3},{43,1,6.3},{44,1,6.3},{11,1,100}},
	["stackable"] = false, ["icon"] = 36, ["ncolor"] = 0x3245EA},
	{["name"] = "Стальной шлем", ["lvl"] = 3, ["type"] = "armor", ["subtype"] = "helmet", ["reqlvl"] = 9, ["description"] = "",
	["props"] = {}, ["cost"] = 38, ["icon"] = 37, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Кольчуга воина", ["lvl"] = 3, ["type"] = "armor", ["subtype"] = "bodywear", ["reqlvl"] = 9, ["description"] = "",
	["props"] = {}, ["cost"] = 43, ["icon"] = 38, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Поножи воина", ["lvl"] = 3, ["type"] = "armor", ["subtype"] = "pants", ["reqlvl"] = 9, ["description"] = "",
	["props"] = {}, ["cost"] = 38, ["icon"] = 39, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Сапоги воина", ["lvl"] = 3, ["type"] = "armor", ["subtype"] = "footwear", ["reqlvl"] = 9, ["description"] = "",
	["props"] = {}, ["cost"] = 37, ["icon"] = 40, ["ncolor"] = 0xFFFFFF},	
	{["name"] = "Сверкающее ожерелье", ["lvl"] = 3, ["type"] = "armor", ["subtype"] = "pendant", ["reqlvl"] = 10, ["description"] = "",
	["props"] = {}, ["cost"] = 42, ["icon"] = 41, ["ncolor"] = 0xFFFFFF},	
	{["name"] = "Закаленный меч", ["lvl"] = 2, ["type"] = "weapon", ["subtype"] = "sword", ["reqlvl"] = 6, ["description"] = "",
	["props"] = {["atds"] = 10, ["phisat"] = {43,61}}, ["cost"] = 53, ["icon"] = 42, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Железное копье", ["lvl"] = 2, ["type"] = "weapon", ["subtype"] = "spear", ["reqlvl"] = 6, ["description"] = "",
	["props"] = {["atds"] = 14, ["phisat"] = {39,56}}, ["cost"] = 48, ["icon"] = 43, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Бронзовая короткая секира", ["lvl"] = 2, ["type"] = "weapon", ["subtype"] = "axe", ["reqlvl"] = 6, ["description"] = "",
	["props"] = {["atds"] = 9, ["phisat"] = {48,72}}, ["cost"] = 58, ["icon"] = 44, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Жидкое масло", ["type"] = "item", ["subtype"] = "res", ["description"] = "Масло начального уровня",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 7, ["icon"] = 45, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Высокоуглеродистая сталь", ["type"] = "item", ["subtype"] = "res", ["description"] = "Может быть использован для крафта",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 2, ["cost"] = 12, ["icon"] = 46, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Лазурный меч", ["cchg"] = "cf", ["lvl"] = 2, ["type"] = "weapon", ["subtype"] = "sword", ["reqlvl"] = 5, ["description"] = "Награда за задание",
	["props"] = {["atds"] = 10, ["phisat"] = {52,68}, ["dds"] = {{"str+",2},{"pdm+",7}}}, ["cost"] = 1, ["icon"] = 42, ["ncolor"] = 0x0044EE},
	{["name"] = "Шлем гвардейца", ["cchg"] = "cf", ["lvl"] = 2, ["type"] = "armor", ["subtype"] = "helmet", ["reqlvl"] = 5, ["description"] = "Награда за задание",
	["props"] = {["dds"] = {{"str+",1},{"hp+",20}}}, ["cost"] = 5, ["icon"] = 31, ["ncolor"] = 0x0044EE},
	{["name"] = "Маска призрака", ["type"] = "item", ["subtype"] = "none", ["description"] = "",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 25, ["icon"] = 47, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Кость", ["type"] = "item", ["subtype"] = "none", ["description"] = "",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 2, ["icon"] = 48, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Бронзовый амулет", ["type"] = "item", ["subtype"] = "none", ["description"] = "",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 15, ["icon"] = 49, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Сломанное оружие", ["type"] = "item", ["subtype"] = "none", ["description"] = "",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 5, ["icon"] = 50, ["ncolor"] = 0xFFFFFF}, -- 52
	{["name"] = "Пыль магического камня", ["type"] = "item", ["subtype"] = "none", ["description"] = "Пыль",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 18, ["icon"] = 51, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Осколок магического камня", ["type"] = "item", ["subtype"] = "none", ["description"] = "Осколок",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 9, ["icon"] = 52, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Изумрудный магический кристалл", ["type"] = "item", ["subtype"] = "none", ["description"] = "Кристалл",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 46, ["icon"] = 53, ["ncolor"] = 0xFFFFFF}, -- 55
	{["name"] = "Осколок светлого камня", ["type"] = "item", ["subtype"] = "none", ["description"] = "Осколок",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 5, ["icon"] = 54, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Осколок камня печали", ["type"] = "item", ["subtype"] = "none", ["description"] = "Осколок",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 5, ["icon"] = 55, ["ncolor"] = 0xFFFFFF}, -- 57
	{["name"] = "Серебрянный кулон", ["cchg"] = "cf", ["lvl"] = 3, ["type"] = "armor", ["subtype"] = "pendant", ["reqlvl"] = 7, ["description"] = "Награда за задание",
	["props"] = {["dds"] = {{"mdf+",15},{"pdm+",1}}}, ["cost"] = 35, ["icon"] = 56, ["ncolor"] = 0x0044EE},
	{["name"] = "Меч из вороненой стали", ["lvl"] = 3, ["type"] = "weapon", ["subtype"] = "sword", ["reqlvl"] = 11, ["description"] = "",
	["props"] = {["atds"] = 10, ["phisat"] = {83,105}}, ["cost"] = 77, ["icon"] = 57, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Копье падшего воина", ["lvl"] = 3, ["type"] = "weapon", ["subtype"] = "spear", ["reqlvl"] = 11, ["description"] = "",
	["props"] = {["atds"] = 14, ["phisat"] = {77,95}}, ["cost"] = 70, ["icon"] = 58, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Топор с широким лезвием", ["lvl"] = 3, ["type"] = "weapon", ["subtype"] = "axe", ["reqlvl"] = 11, ["description"] = "",
	["props"] = {["atds"] = 9, ["phisat"] = {84,123}}, ["cost"] = 82, ["icon"] = 59, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Легкая накидка", ["lvl"] = 1, ["type"] = "armor", ["subtype"] = "robe", ["reqlvl"] = 2, ["description"] = "",
	["props"] = {}, ["cost"] = 8, ["icon"] = 60, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Металлическое кольцо", ["lvl"] = 1, ["type"] = "armor", ["subtype"] = "ring", ["reqlvl"] = 3, ["description"] = "",
	["props"] = {}, ["cost"] = 7, ["icon"] = 61, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Рыцарский плащ", ["lvl"] = 2, ["type"] = "armor", ["subtype"] = "robe", ["reqlvl"] = 7, ["description"] = "",
	["props"] = {}, ["cost"] = 27, ["icon"] = 62, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Кольцо чистоты", ["lvl"] = 2, ["type"] = "armor", ["subtype"] = "ring", ["reqlvl"] = 9, ["description"] = "",
	["props"] = {}, ["cost"] = 34, ["icon"] = 63, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Отличный меч героя", ["cchg"] = "cf", ["lvl"] = 3, ["type"] = "weapon", ["subtype"] = "sword", ["reqlvl"] = 7, ["description"] = "Награда за задание",
	["props"] = {["atds"] = 10, ["phisat"] = {90,114},["dds"] = {{"sur+",1},{"str+",2},{"pdm+",10}}}, ["cost"] = 1, ["icon"] = 64, ["ncolor"] = 0xAB00D3},
	{["name"] = "Позолоченная шкатулка", ["type"] = "chest", ["subtype"] = "none", ["cost"] = 1, ["description"] = "Нажмите ПКМ чтобы открыть",
	["props"] = {{13,5,14.2},{14,5,14.2},{65,1,8.6},{64,1,9},{59,1,6.3},{60,1,6.3},{61,1,6.3},{55,1,1.5},{56,1,2.3},{57,1,2.3}},
	["stackable"] = false, ["icon"] = 65, ["ncolor"] = 0x3245EA},
	{["name"] = "Зачарованный доспех", ["cchg"] = "cf", ["lvl"] = 4, ["type"] = "armor", ["subtype"] = "bodywear", ["reqlvl"] = 8, ["description"] = "Награда за задание",
	["props"] = {["dds"] = {{"sur+",1},{"mdf+",12}}}, ["cost"] = 1, ["icon"] = 66, ["ncolor"] = 0x0044EE},
	{["name"] = "Амулет удачи", ["type"] = "elementmul", ["subtype"] = "hp", ["description"] = "Восстанавливает 40% здоровья, если оно ниже 10%",
	["props"] = {["r"]=10,["ics"]=40}, ["stackable"] = true, ["maxstack"] = 10, ["lvl"] = 1, ["cost"] = 5, ["icon"] = 67, ["ncolor"] = 0xB49730},
	{["name"] = "Шлем кавалериста", ["lvl"] = 4, ["type"] = "armor", ["subtype"] = "helmet", ["reqlvl"] = 14, ["description"] = "",
	["props"] = {}, ["cost"] = 49, ["icon"] = 68, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Пластинчатая кираса", ["lvl"] = 4, ["type"] = "armor", ["subtype"] = "bodywear", ["reqlvl"] = 14, ["description"] = "",
	["props"] = {}, ["cost"] = 55, ["icon"] = 69, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Тяжелые поножи", ["lvl"] = 4, ["type"] = "armor", ["subtype"] = "pants", ["reqlvl"] = 14, ["description"] = "",
	["props"] = {}, ["cost"] = 52, ["icon"] = 70, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Тяжелые сапоги", ["lvl"] = 4, ["type"] = "armor", ["subtype"] = "footwear", ["reqlvl"] = 14, ["description"] = "",
	["props"] = {}, ["cost"] = 50, ["icon"] = 71, ["ncolor"] = 0xFFFFFF},	
	{["name"] = "Драгоценное ожерелье", ["lvl"] = 4, ["type"] = "armor", ["subtype"] = "pendant", ["reqlvl"] = 15, ["description"] = "",
	["props"] = {}, ["cost"] = 42, ["icon"] = 72, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Часть книги умений", ["type"] = "item", ["subtype"] = "none", ["description"] = "Используется для изучения умений",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 5, ["icon"] = 73, ["ncolor"] = 0xFFFFFF}, --75
	{["name"] = "Накидка мага", ["lvl"] = 3, ["type"] = "armor", ["subtype"] = "robe", ["reqlvl"] = 15, ["description"] = "",
	["props"] = {}, ["cost"] = 42, ["icon"] = 74, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Меч полководца", ["lvl"] = 4, ["type"] = "weapon", ["subtype"] = "sword", ["reqlvl"] = 16, ["description"] = "",
	["props"] = {["atds"] = 10, ["phisat"] = {123,158}}, ["cost"] = 93, ["icon"] = 75, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Копье холодной реки", ["lvl"] = 4, ["type"] = "weapon", ["subtype"] = "spear", ["reqlvl"] = 16, ["description"] = "",
	["props"] = {["atds"] = 14, ["phisat"] = {114,147}}, ["cost"] = 84, ["icon"] = 76, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Короткая секира железных скал", ["lvl"] = 4, ["type"] = "weapon", ["subtype"] = "axe", ["reqlvl"] = 16, ["description"] = "",
	["props"] = {["atds"] = 9, ["phisat"] = {132,175}}, ["cost"] = 94, ["icon"] = 77, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Сломанный щит", ["type"] = "item", ["subtype"] = "res", ["description"] = "Осколок старого щита. Добывается в опасных подземельях.",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 10, ["icon"] = 78, ["ncolor"] = 0x0044EE}, -- 80
	{["name"] = "Часть древней брони", ["type"] = "item", ["subtype"] = "res", ["description"] = "Кусок прочного доспеха. Добывается в опасных подземельях.",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 10, ["icon"] = 79, ["ncolor"] = 0x0044EE},
	{["name"] = "Часть нержавеющего меча", ["type"] = "item", ["subtype"] = "res", ["description"] = "Осколок старого меча. Добывается в опасных подземельях.",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 10, ["icon"] = 80, ["ncolor"] = 0x0044EE},
	{["name"] = "Чистый камень", ["type"] = "item", ["subtype"] = "none", ["description"] = "Сияющий кристалл отгояет тьму.",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 25, ["icon"] = 81, ["ncolor"] = 0x0044EE},
	{["name"] = "Меч воина", ["lvl"] = 4, ["type"] = "weapon", ["subtype"] = "sword", ["reqlvl"] = 14, ["description"] = "",
	["props"] = {["atds"] = 10, ["phisat"] = {152,197}}, ["cost"] = 110, ["icon"] = 82, ["ncolor"] = 0x66FF80},
	{["name"] = "Острое темное копье", ["lvl"] = 4, ["type"] = "weapon", ["subtype"] = "spear", ["reqlvl"] = 14, ["description"] = "",
	["props"] = {["atds"] = 14, ["phisat"] = {139,185}}, ["cost"] = 110, ["icon"] = 83, ["ncolor"] = 0x66FF80},
	{["name"] = "Яркий топор", ["lvl"] = 4, ["type"] = "weapon", ["subtype"] = "axe", ["reqlvl"] = 14, ["description"] = "",
	["props"] = {["atds"] = 9, ["phisat"] = {164,212}}, ["cost"] = 110, ["icon"] = 84, ["ncolor"] = 0x66FF80},
	{["name"] = "Материал для создания", ["type"] = "item", ["subtype"] = "res", ["description"] = "Новый материал, чтобы создать снаряжение для 14+ ур.",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 22, ["icon"] = 85, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Кольцо Штемлура", ["lvl"] = 4, ["type"] = "armor", ["subtype"] = "ring", ["reqlvl"] = 14, ["description"] = "",
	["props"] = {}, ["cost"] = 80, ["icon"] = 86, ["ncolor"] = 0x66FF80},
	{["name"] = "Аметистовый кулон", ["lvl"] = 4, ["type"] = "armor", ["subtype"] = "pendant", ["reqlvl"] = 14, ["description"] = "",
	["props"] = {}, ["cost"] = 80, ["icon"] = 87, ["ncolor"] = 0x66FF80},
	{["name"] = "Потемневший значок", ["type"] = "item", ["subtype"] = "none", ["description"] = "Отдайте коменданту чтобы получить 1000 ед. опыта",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 1, ["cost"] = 25, ["icon"] = 88, ["ncolor"] = 0x66FF80},
	{["name"] = "Меч Волны", ["lvl"] = 5, ["type"] = "weapon", ["subtype"] = "sword", ["reqlvl"] = 19, ["description"] = "",
	["props"] = {["atds"] = 10, ["phisat"] = {191,254}}, ["cost"] = 175, ["icon"] = 89, ["ncolor"] = 0x66FF80},
	{["name"] = "Пика Штемлура", ["lvl"] = 5, ["type"] = "weapon", ["subtype"] = "spear", ["reqlvl"] = 19, ["description"] = "",
	["props"] = {["atds"] = 14, ["phisat"] = {181,240}}, ["cost"] = 175, ["icon"] = 90, ["ncolor"] = 0x66FF80},
	{["name"] = "Секира мертвеца", ["lvl"] = 5, ["type"] = "weapon", ["subtype"] = "axe", ["reqlvl"] = 19, ["description"] = "",
	["props"] = {["atds"] = 9, ["phisat"] = {206,273}}, ["cost"] = 175, ["icon"] = 91, ["ncolor"] = 0x66FF80},
	{["name"] = "Сердце фантома", ["type"] = "res", ["subtype"] = "none", ["description"] = "Редкий минерал, используемый для порабощения духов.",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 2, ["cost"] = 32, ["icon"] = 92, ["ncolor"] = 0x0044EE},
	{["name"] = "Наручи Лорда Сипри", ["type"] = "item", ["subtype"] = "res", ["description"] = "Артефакт, наполненный особой силой.",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 3, ["cost"] = 50, ["icon"] = 93, ["ncolor"] = 0xAB00D3},
	{["name"] = "Артефакт Увеула", ["type"] = "item", ["subtype"] = "res", ["description"] = "Артефакт, наполненный особой силой.",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 3, ["cost"] = 50, ["icon"] = 94, ["ncolor"] = 0x66FF80},
	{["name"] = "Лезвие волшебного клинка", ["type"] = "item", ["subtype"] = "res", ["description"] = "Артефакт, наполненный особой силой.",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 3, ["cost"] = 50, ["icon"] = 95, ["ncolor"] = 0x66FF80},
	{["name"] = "Плащ благословения", ["lvl"] = 4, ["type"] = "armor", ["subtype"] = "robe", ["reqlvl"] = 21, ["description"] = "",
	["props"] = {}, ["cost"] = 85, ["icon"] = 96, ["ncolor"] = 0xFFFFFF},	
	{["name"] = "Шлем холодной реки", ["lvl"] = 5, ["type"] = "armor", ["subtype"] = "helmet", ["reqlvl"] = 19, ["description"] = "",
	["props"] = {}, ["cost"] = 69, ["icon"] = 97, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Броня водопада", ["lvl"] = 5, ["type"] = "armor", ["subtype"] = "bodywear", ["reqlvl"] = 19, ["description"] = "",
	["props"] = {}, ["cost"] = 73, ["icon"] = 98, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Тяжелые поножи водопада", ["lvl"] = 5, ["type"] = "armor", ["subtype"] = "pants", ["reqlvl"] = 19, ["description"] = "",
	["props"] = {}, ["cost"] = 71, ["icon"] = 99, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Тяжелые сапоги водопада", ["lvl"] = 5, ["type"] = "armor", ["subtype"] = "footwear", ["reqlvl"] = 19, ["description"] = "",
	["props"] = {}, ["cost"] = 69, ["icon"] = 100, ["ncolor"] = 0xFFFFFF},	
	{["name"] = "Сияющее ожерелье", ["lvl"] = 5, ["type"] = "armor", ["subtype"] = "pendant", ["reqlvl"] = 20, ["description"] = "",
	["props"] = {}, ["cost"] = 70, ["icon"] = 101, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Тяжелый шлем рыцаря", ["lvl"] = 5, ["type"] = "armor", ["subtype"] = "helmet", ["reqlvl"] = 15, ["description"] = "",
	["props"] = {}, ["nmlt"] = 1.8, ["cost"] = 75, ["icon"] = 102, ["ncolor"] = 0x66FF80},
	{["name"] = "Тяжелый шлем рыцаря", ["cchg"] = "cf", ["lvl"] = 5, ["type"] = "armor", ["subtype"] = "helmet", ["reqlvl"] = 15, ["description"] = "",
	["props"] = {["dds"] = {{"sur+",5},{"mdf+",82},{"hp+",50}}}, ["nmlt"] = 2.6, ["cost"] = 90, ["icon"] = 102, ["ncolor"] = 0xFFFF00},
	{["name"] = "Кираса рыцаря", ["lvl"] = 5, ["type"] = "armor", ["subtype"] = "bodywear", ["reqlvl"] = 15, ["description"] = "",
	["props"] = {}, ["nmlt"] = 1.8, ["cost"] = 90, ["icon"] = 103, ["ncolor"] = 0x66FF80},
	{["name"] = "Кираса сановника", ["cchg"] = "cf", ["lvl"] = 5, ["type"] = "armor", ["subtype"] = "bodywear", ["reqlvl"] = 15, ["description"] = "",
	["props"] = {["dds"] = {{"hp+",65},{"pdf+",94},{"str+",5}}}, ["nmlt"] = 2.6, ["cost"] = 105, ["icon"] = 103, ["ncolor"] = 0xFFFF00},
	{["name"] = "Поножи рыцаря", ["lvl"] = 5, ["type"] = "armor", ["subtype"] = "pants", ["reqlvl"] = 15, ["description"] = "",
	["props"] = {}, ["nmlt"] = 1.8, ["cost"] = 85, ["icon"] = 104, ["ncolor"] = 0x66FF80},
	{["name"] = "Ножные латы сановника", ["cchg"] = "cf", ["lvl"] = 5, ["type"] = "armor", ["subtype"] = "pants", ["reqlvl"] = 15, ["description"] = "",
	["props"] = {["dds"] = {{"sur+",3},{"mp+",50},{"str+",3}}}, ["nmlt"] = 2.6, ["cost"] = 100, ["icon"] = 104, ["ncolor"] = 0xFFFF00},
	{["name"] = "Сапоги рыцаря", ["lvl"] = 5, ["type"] = "armor", ["subtype"] = "footwear", ["reqlvl"] = 15, ["description"] = "",
	["props"] = {}, ["nmlt"] = 1.8, ["cost"] = 75, ["icon"] = 105, ["ncolor"] = 0x66FF80},
	{["name"] = "Сапоги сановника", ["cchg"] = "cf", ["lvl"] = 5, ["type"] = "armor", ["subtype"] = "footwear", ["reqlvl"] = 15, ["description"] = "",
	["props"] = {["dds"] = {{"pdm+",15},{"hp+",40},{"chc+",1}}}, ["nmlt"] = 2.6, ["cost"] = 90, ["icon"] = 105, ["ncolor"] = 0xFFFF00},
	{["name"] = "Золотой меч", ["cchg"] = "cf", ["lvl"] = 5, ["type"] = "weapon", ["subtype"] = "sword", ["reqlvl"] = 12, ["description"] = "Награда за задание",
	["props"] = {["atds"] = 10, ["phisat"] = {188,246}, ["dds"] = {{"chc+",2},{"pdm+",55},{"hp+",80}}}, ["cost"] = 1, ["icon"] = 110, ["ncolor"] = 0xAB00D3},
	{["name"] = "Малое восстанавливающее зелье", ["type"] = "potion", ["subtype"] = "health", ["reqlvl"] = 20, ["description"] = "",
	["props"] = 1, ["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 5, ["cost"] = 7, ["icon"] = 106, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Малое духовное зелье", ["type"] = "potion", ["subtype"] = "mana", ["reqlvl"] = 20, ["description"] = "",
	["props"] = 1, ["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 5, ["cost"] = 7, ["icon"] = 107, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Среднее восстанавливающее зелье", ["type"] = "potion", ["subtype"] = "health", ["reqlvl"] = 30, ["description"] = "",
	["props"] = 1, ["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 6, ["cost"] = 7, ["icon"] = 108, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Среднее духовное зелье", ["type"] = "potion", ["subtype"] = "mana", ["reqlvl"] = 30, ["description"] = "",
	["props"] = 1, ["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 6, ["cost"] = 7, ["icon"] = 109, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Дублёная кожа", ["type"] = "item", ["subtype"] = "res", ["description"] = "Кожа низкого уровня",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 2, ["cost"] = 12, ["icon"] = 111, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Шерстяные нитки", ["type"] = "item", ["subtype"] = "res", ["description"] = "Нить низкого уровня",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 2, ["cost"] = 9, ["icon"] = 112, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Пиломатериалы", ["type"] = "item", ["subtype"] = "res", ["description"] = "Древесина низкого уровня",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 2, ["cost"] = 10, ["icon"] = 113, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Каменный уголь", ["type"] = "item", ["subtype"] = "res", ["description"] = "Топливо низкого уровня",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 2, ["cost"] = 12, ["icon"] = 114, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Шлифовальный камень", ["type"] = "item", ["subtype"] = "res", ["description"] = "Камень низкого уровня",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 2, ["cost"] = 12, ["icon"] = 115, ["ncolor"] = 0xFFFFFF},
	{["name"] = "Очищенное масло", ["type"] = "item", ["subtype"] = "res", ["description"] = "Масло низкого уровня",
	["stackable"] = true, ["maxstack"] = 99, ["lvl"] = 2, ["cost"] = 12, ["icon"] = 116, ["ncolor"] = 0xFFFFFF}, --▖▗▘▝
	{["name"] = "Кольцо звездопада", ["lvl"] = 3, ["type"] = "armor", ["subtype"] = "ring", ["reqlvl"] = 17, ["description"] = "",
	["props"] = {}, ["cost"] = 72, ["icon"] = 117, ["ncolor"] = 0xFFFFFF},
}

gfunc.watds = {["sword"]=10,["spear"]=12,["axe"]=10}
local weaponHitRate = {["sword"]=0.9,["spear"]=1,["axe"]=1.2}
local armorPhysicalDefenceMultiple = {["helmet"]=38.2,["bodywear"]=40.4,["pants"]=38.7,["footwear"]=37.3,["pendant"]=19.5,["robe"]=30.6,["ring"]=21.3}
local armorMagicalDefenceMultiple = {["helmet"]=15.4,["bodywear"]=26.3,["pants"]=23.8,["footwear"]=11.5,["pendant"]=27.5,["robe"]=32.8,["ring"]=24.7}
local nmlt = 1

for f = 1, #gid do
gid[f]["name"] = lang(string.gsub(gid[f]["name"], "♦", ""))
if gid[f]["props"] and type(gid[f]["props"]) == "table" and gid[f]["props"]["dds"] then for o = 1, #gid[f]["props"]["dds"] do gid[f]["name"] = "♦"..gid[f]["name"] end end
 if gid[f]["name"] == "" then gid[f]["name"] = "Без названия" end
gid[f]["description"] = lang(gid[f]["description"])
 if gid[f]["type"] == "armor" then
  gid[f]["stackable"] = false
  if gid[f]["nmlt"] then nmlt = tonumber(gid[f]["nmlt"]) end
  if gid[f]["props"]["pdef"] == nil then
  gid[f]["props"]["pdef"] = math.ceil(9+gid[f]["lvl"]*armorPhysicalDefenceMultiple[gid[f]["subtype"]]*nmlt*math.max((gid[f]["lvl"]^1.2/4),1))
  end
  if gid[f]["props"]["mdef"] == nil then
  gid[f]["props"]["mdef"] = math.ceil(9+gid[f]["lvl"]*armorMagicalDefenceMultiple[gid[f]["subtype"]]*nmlt*math.max((gid[f]["lvl"]^1.2/4),1))
  end
 end
 if gid[f]["type"] == "weapon" then
 gid[f]["stackable"] = false
 end
nmlt = 1
end

nmlt = nil

local gidemDataNum, mItemDataNum = #gid, #gid

local gqd = {
	{["name"] = "Зомби", ["type"] = "k", ["qr"] = 5, ["targ"] = 2, ["num"] = 5, ["minlvl"] = 1,
	["descr"] = "Василий просит вас прогнать всех зомби, блуждающих рядом с деревней.",
	["gtext"] = "Зомби слабые и медлительные, но их стало слишком много!",
	["qreward"] = {["coins"] = 10, ["xp"] = 65, ["item"] = {{9,5},{23,5}}}},
	{["name"] = "Призраки", ["type"] = "k", ["qr"] = 5, ["targ"] = 3, ["num"] = 3, ["minlvl"] = 1,
	["descr"] = "Развейте несколько призраков, чтобы ослабить негативный фон.",
	["gtext"]="Множество духов пребывало в спящем состоянии, пока не случилось великое бедствие.",
	["qreward"] = {["coins"] = 12, ["xp"] = 75, ["item"] = {{10,5},{29,1}}}},
	{["name"] = "Луговые слизни", ["type"] = "k", ["qr"] = 5, ["targ"] = 4, ["num"] = 7, ["minlvl"] = 2,
	["descr"] = "Уничтожьте несколько слизней в зелёных лугах.",
	["gtext"]="Никогда не было так много слизней в наших лугах! Зелёные луговые слизни очень быстро уничтожают любые растения и могут добраться до наших запасов.",
	["qreward"] = {["coins"] = 20, ["xp"] = 130, ["item"] = {{22,1}}}}, -- 3
	{["name"] = "Панцирь черепахи", ["type"] = "k", ["qr"] = 10, ["targ"] = 8, ["num"] = 3, ["minlvl"] = 3,
	["descr"] = " Анатолия очень заинтересовали каменные черепахи. Принесите ему 3 панциря каменных черепах, он будет благодарен.",
	["gtext"]="Очищенный панцирь каменной черепахи можно использовать в приготовлении некоторых лекарств. Я думаю, их можно найти на востоке от деревни.",
	["qreward"] = {["coins"] = 18, ["xp"] = 200, ["item"] = nil}},
	{["name"] = "Ночные жители", ["type"] = "k", ["qr"] = 20, ["targ"] = {16,29}, ["num"] = {3,3}, ["minlvl"] = 5,  
	["descr"] = "Отправляйтесь к могильникам и прогоните пещерных вурдалаков из окрестностей.",
	["gtext"]="Существа, теперь населяющие некоторые пещеры, не переносят солнечного света, поэтому выходят из пещер только в ночное время суток. Теперь они все ближе и ближе подбираются к поселению в попытках найти еду.",
	["qreward"] = {["coins"] = 59, ["xp"] = 400, ["item"] = {{36,1}}}}, -- 5
	{["name"] = "Хаос в подземелье", ["type"] = "k", ["qr"] = 39, ["targ"] = {35,38}, ["num"] = {1,1}, ["minlvl"] = 5,
	["descr"] = "Генерал Бездрут и Генерал Сутт'ешдпад восстали из мертвых!  Старейшина посёлка у холма просит вас помочь уничтожить их как можно скорее.",
	["gtext"]="Загадочным образом могильник наполнился ожившими трупами, и это как-то связано со всем происходящим вокруг!",
	["qreward"] = {["coins"] = 75, ["xp"] = 635, ["item"] = {{36,1},{36,1},{69,1}}}},
	{["name"] = "", ["type"] = "k", ["qr"] = 39, ["targ"] = 38, ["num"] = 1, ["minlvl"] = 5,
	["descr"] = "",
	["qreward"] = {["coins"] = 75, ["xp"] = 0, ["item"] = {{36,1},{36,1}}}}, -- 7
	{["name"] = "Причина хаоса в подземелье", ["type"] = "k", ["qr"] = 39, ["targ"] = 42, ["num"] = 1, ["minlvl"] = 5,
	["descr"] = "Найдите призрака внутри древнего могильника и обезвредьте его.",
	["gtext"]="В могильник проник некий негативный фантом, способный поднимать мертвецов. Пока он находится там, мы не сможем изменить ситуацию в лучшую сторону.",
	["qreward"] = {["coins"] = 100, ["xp"] = 800, ["item"] = {{47,1}}}},
	{["name"] = "Дух места", ["type"] = "k", ["qr"] = 5, ["targ"] = 7, ["num"] = 5, ["minlvl"] = 3,
	["descr"] = "Василий просит вас изгнать духов места из окрестностей деревни.",
	["gtext"]="Эти привидения прежде не давали о себе знать и жили в земле и старых деревьях.",
	["qreward"] = {["coins"] = 25, ["xp"] = 150, ["item"] = nil}}, -- 9
	{["name"] = "Ожившие деревья", ["type"] = "k", ["qr"] = 5, ["targ"] = 9, ["num"] = 5, ["minlvl"] = 4,
	["descr"] = "Сожгите гнилые ивовые деревья, чтобы они не накапливали тьму.",
	["gtext"]="Деревья давно погибли, но призраки, живущие в них, могут ими управлять.",
	["qreward"] = {["coins"] = 40, ["xp"] = 370, ["item"] = nil}},
	{["name"] = "Болотный вурдалак [ур. 5+]", ["type"] = "k", ["qr"] = 45, ["targ"] = 14, ["num"] = 3, ["minlvl"] = 5,
	["descr"] = "Помогите страже уничтожить монстров: Болотный вурдалак.",
	["gtext"]="Мы прилагаем все усилия, чтобы прогнать чудовищ из наших земель.",
	["qreward"] = {["coins"] = 25, ["xp"] = 400, ["item"] = nil}}, -- 11	
	{["name"] = "Скелет охотника [ур. 5+]", ["type"] = "k", ["qr"] = 45, ["targ"] = 47, ["num"] = 3, ["minlvl"] = 5,
	["descr"] = "Помогите страже уничтожить монстров: Скелет охотника.",
	["gtext"]="Мы прилагаем все усилия, чтобы прогнать чудовищ из наших земель.",
	["qreward"] = {["coins"] = 29, ["xp"] = 400, ["item"] = nil}}, -- 12
	{["name"] = "Цветущее дерево [ур. 6+]", ["type"] = "k", ["qr"] = 45, ["targ"] = 48, ["num"] = 2, ["minlvl"] = 6,
	["descr"] = "Помогите страже уничтожить монстров: Цветущее дерево.",
	["gtext"]="Мы прилагаем все усилия, чтобы прогнать чудовищ из наших земель.",
	["qreward"] = {["coins"] = 32, ["xp"] = 520, ["item"] = nil}}, -- 13
	{["name"] = "Красный слизень [ур. 6+]", ["type"] = "k", ["qr"] = 45, ["targ"] = 49, ["num"] = 3, ["minlvl"] = 6,
	["descr"] = "Помогите страже уничтожить монстров: Красный слизень.",
	["gtext"]="Мы прилагаем все усилия, чтобы прогнать чудовищ из наших земель.",
	["qreward"] = {["coins"] = 32, ["xp"] = 520, ["item"] = nil}}, -- 14
	{["name"] = "Слабые демоны", ["type"] = "k", ["qr"] = 20, ["targ"] = {50,51}, ["num"] = {3,3}, ["minlvl"] = 7,
	["descr"] = "Разыщите и уничтожьте мелких демонов.",
	["gtext"]="Появление нечистой силы на юго-востоке говорит о серьезности атаки, а не о резком увеличении активности духов и нежити. Мы все волнуемся о частых набегах монстров.",
	["qreward"] = {["coins"] = 77, ["xp"] = 680, ["item"] = {{48,1}}}}, -- 15
	{["name"] = "Предметы", ["type"] = "f", ["qr"] = 11, ["targ"] = {{49,1},{51,1},{52,1}}, ["minlvl"] = 5,
	["descr"] = "Найдите утерянные предметы воинов и странников.",
	["gtext"]="Много вещей было украдено, и я хочу пеплавить и перековать их во что-нибудь полезное.",
	["qreward"] = {["coins"] = 40, ["xp"] = 1322, ["item"] = nil}},
	{["name"] = "Горящий призрак", ["type"] = "k", ["qr"] = 20, ["targ"] = 53, ["num"] = 1, ["minlvl"] = 7,
	["descr"] = "Найдите огненного призрака на юго-востоке и уничтожьте.",
	["gtext"]="Этот призрак объявился на юго-востоке не случайно… Кажется, что он вообще ничего не делает, но тем не менее есть необычная астральная активность.",
	["qreward"] = {["coins"] = 74, ["xp"] = 1442, ["item"] = {{58,1},{36,1},{69,1}}}}, -- 17
	{["name"] = "Новые кошмары", ["type"] = "k", ["qr"] = 39, ["targ"] = {58,59,63,65,66}, ["num"] = {1,1,1,1,1}, ["minlvl"] = 7,
	["descr"] = "Уничтожьте силы демонов в тайном подземелье.",
	["gtext"]="Появление демонов в катакомбах грозит уничтожением поселка из под земли, а также это даст им огромное преимущество в данной ситуации. У нас недостаточно сил, чтобы бороться с ними, мы расчитываем на вашу помощь.",
	["qreward"] = {["coins"] = 305, ["xp"] = 2100, ["item"] = {{66,1},{67,1},{69,3},{75,1}}}},
	{["name"] = "Ходячие скелеты", ["type"] = "k", ["qr"] = 5, ["targ"] = 15, ["num"] = 5, ["minlvl"] = 5,
	["descr"] = "Обезвредьте несколько скелетов, чтобы узнать об их происхождении.",
	["gtext"]="Неизвестно, каким образом скелеты появились в зеленых лугах, но это явное проявление некромантии; надеюсь нам удастся узнать, кто за этим стоит.",
	["qreward"] = {["coins"] = 28, ["xp"] = 355, ["item"] = {{22,1}}}},
	{["name"] = "Зачистка подземелья [ур. 7+]", ["type"] = "k", ["qr"] = 39, ["targ"] = {56,57,60,61,64}, ["num"] = {3,3,5,8,3}, ["minlvl"] = 7,
	["descr"] = "Катакомбы заполонили чудовища, с ними вы можнете справиться без особого труда.",
	["gtext"]="До недавнего времени катакомбы были пустыми, но постепенно их заселили чуовища и демоны.",
	["qreward"] = {["coins"] = 162, ["xp"] = 1850, ["item"] = {{68,1},{67,1},{75,1}}}}, -- 20
	{["name"] = "Ядовитый слизень [ур. 8+]", ["type"] = "k", ["qr"] = 74, ["targ"] = 71, ["num"] = 5, ["minlvl"] = 8,
	["descr"] = "Помогите страже уничтожить монстров: Ядовитый слизень.",
	["gtext"]="Мы прилагаем все усилия, чтобы прогнать чудовищ из наших земель.",
	["qreward"] = {["coins"] = 44, ["xp"] = 870, ["item"] = nil}},
	{["name"] = "Гранитный голем [ур. 9+]", ["type"] = "k", ["qr"] = 74, ["targ"] = 72, ["num"] = 5, ["minlvl"] = 9,
	["descr"] = "Помогите страже уничтожить монстров: Гранитный голем.",
	["qreward"] = {["coins"] = 50, ["xp"] = 1050, ["item"] = nil}},
	["gtext"]="Мы прилагаем все усилия, чтобы прогнать чудовищ из наших земель.",
	{["name"] = "Текамбха-доспех [ур. 10+]", ["type"] = "k", ["qr"] = 74, ["targ"] = 73, ["num"] = 5, ["minlvl"] = 10,
	["descr"] = "Помогите страже уничтожить монстров: Текамбха-доспех.",
	["qreward"] = {["coins"] = 63, ["xp"] = 1300, ["item"] = nil}},
	["gtext"]="Мы прилагаем все усилия, чтобы прогнать чудовищ из наших земель.",
	{["name"] = "Проклинающий бес [ур. 11+]", ["type"] = "k", ["qr"] = 74, ["targ"] = 75, ["num"] = 5, ["minlvl"] = 11,
	["descr"] = "Помогите страже уничтожить монстров: Проклинающий бес.",
	["gtext"]="Мы прилагаем все усилия, чтобы прогнать чудовищ из наших земель.",
	["qreward"] = {["coins"] = 63, ["xp"] = 1650, ["item"] = nil}},
	{["name"] = "Призрак весны", ["type"] = "k", ["qr"] = 68, ["targ"] = 76, ["num"] = 1, ["minlvl"] = 10,
	["descr"] = "Развейте фантома, притворяющегося духом равнины.",
	["gtext"]="Что же стало с духом равнины? Скорее всего силы тьмы его не просто поработили, а изменили составляющую духа. К сожалению, его нужно уничтожить, чтобы он никому не причинил вреда.",
	["qreward"] = {["coins"] = 75, ["xp"] = 2550, ["item"] = {{75,1}}}}, -- 25
	{["name"] = "Разведка в долине", ["type"] = "k", ["qr"] = 68, ["targ"] = {80,81,82,83,84,86,87,90,91,93}, ["num"] = {5,3,4,4,5,5,5,5,5,5}, ["minlvl"] = 11,
	["descr"] = "Долина переполнена чудовищами и демонами. Они помешают добраться до артефакта, не дающего Призраку покинуть долину.",
	["gtext"]="Нужно изгнать всю нечисть из долины мрачных миражей! Артефакт точно где-то там, но бесчисленные толпы монстров попросту не дадут даже заглянуть туда.",
	["qreward"] = {["coins"] = 285, ["xp"] = 4125, ["item"] = {{67,1},{75,1}}}},
	{["name"] = "Тьма опустилась на долину мра", ["type"] = "k", ["qr"] = 68, ["targ"] = {85,88,92,94}, ["num"] = {1,1,1,1}, ["minlvl"] = 11,
	["descr"] = "Уничтожьте предводителей сил зла в долине мрачных миражей: Колдуна из мира теней, Древний заколдованный доспех и Таинственного жреца.",
	["gtext"]="Даже до нашествия сил демонов в долине присутствовали ожившие мертвецы и природная нечисть, но теперь все монстры стали агрессивнее, а их количество увеличилось в разы. Уничтожьте предводителей сил зла в долине.",
	["qreward"] = {["coins"] = 355, ["xp"] = 5750, ["item"] = {{83,1},{75,1}}}},
	{["name"] = "Цель: Древнее божество горной", ["type"] = "k", ["qr"] = 68, ["targ"] = 96, ["num"] = 1, ["minlvl"] = 11,
	["descr"] = "",
	["gtext"]="",
	["repeat"] = true, ["qreward"] = {["coins"] = 100, ["xp"] = 2500, ["item"] = {{94,2}}}}, -- 28
	{["name"] = "Путеводитель (1)", ["type"] = "k", ["qr"] = 39, ["targ"] = 42, ["num"] = 1, ["minlvl"] = 5,
	["descr"] = "Вы можете найти Фантом в Могильнике.", ["qreward"] = {["coins"] = 0, ["xp"] = 500, ["item"] = nil}, ["fct"] = "setquest", ["value"] = 30},
	{["name"] = "Путеводитель (2)", ["type"] = "k", ["qr"] = 39, ["targ"] = 54, ["num"] = 1, ["minlvl"] = 1,
	["descr"] = "Вы можете найти Запертого Духа на Равнине.", ["qreward"] = {["coins"] = 0, ["xp"] = 750, ["item"] = nil}, ["fct"] = "setquest", ["value"] = 31},
	{["name"] = "Путеводитель (3)", ["type"] = "k", ["qr"] = 39, ["targ"] = 66, ["num"] = 1, ["minlvl"] = 1,
	["descr"] = "Вы можете найти Доспех Шана Тессана в Тайном подземелье.", ["qreward"] = {["coins"] = 0, ["xp"] = 1500, ["item"] = nil}, ["fct"] = "setquest", ["value"] = 32},
	{["name"] = "Путеводитель (4)", ["type"] = "k", ["qr"] = 68, ["targ"] = 76, ["num"] = 1, ["minlvl"] = 1,
	["descr"] = "Вы можете найти Духа равнины восточнее Крепости малой реки.", ["qreward"] = {["coins"] = 0, ["xp"] = 2250, ["item"] = nil}, ["fct"] = "setquest", ["value"] = 33},
	{["name"] = "Путеводитель (5)", ["type"] = "k", ["qr"] = 68, ["targ"] = 85, ["num"] = 1, ["minlvl"] = 1,
	["descr"] = "Вы можете найти Башню тёмной земли в долине мрачных миражей.", ["qreward"] = {["coins"] = 0, ["xp"] = 4500, ["item"] = nil}, ["fct"] = "setquest", ["value"] = 34}, 
	{["name"] = "Путеводитель (6)", ["type"] = "k", ["qr"] = 68, ["targ"] = 104, ["num"] = 1, ["minlvl"] = 1,
	["descr"] = "Вы можете найти Башню песка недалеко от Монастыря Увеула.", ["qreward"] = {["coins"] = 0, ["xp"] = 7500, ["item"] = nil}}, -- 34
	{["name"] = "Обмен медальона", ["type"] = "f", ["qr"] = 74, ["targ"] = {{90,1}}, ["minlvl"] = 5,
	["descr"] = "Найдите потерянный потемневший значок и отдайте коменданту Кану Вушену.", ["gtext"] = "Если где-нибудь увидите такой значок, то принесите его мне.", ["repeat"] = true, ["qreward"] = {["coins"] = 0, ["xp"] = 1000, ["item"] = nil}}, -- 35
	{["name"] = "Цель: Соттах-Еснад", ["type"] = "k", ["qr"] = 68, ["targ"] = 120, ["num"] = 1, ["minlvl"] = 14,
	["descr"] = "",
	["repeat"] = true, ["qreward"] = {["coins"] = 200, ["xp"] = 4000, ["item"] = {{94,5}}}},
	{["name"] = "Духовная пыль", ["type"] = "k", ["qr"] = 67, ["targ"] = 113, ["num"] = 8, ["minlvl"] = 13,
	["descr"] = "Никогда не найти чёрным душам выход из волшебной ловушки, но Вы можете продать 8 штук.",
	["qreward"] = {["coins"] = 154, ["xp"] = 3500, ["item"] = {{94,1}}}},
	{["name"] = "Уничтожение сердца", ["type"] = "k", ["qr"] = 67, ["targ"] = 112, ["num"] = 1, ["minlvl"] = 14,
	["descr"] = "Хотелось бы получше узнать историю храма Увеула, чтобы узнать: кто же там был так неаккуратно разбужен?",
	["qreward"] = {["coins"] = 186, ["xp"] = 4500, ["item"] = {{94,1},{75,1}}}},
	{["name"] = "Способ ограничения духа", ["type"] = "k", ["qr"] = 67, ["targ"] = 120, ["num"] = 1, ["minlvl"] = 15,
	["descr"] = "Церковь Увеула, желая покорить потусторонний мир, призвала четвёрку сильных магов пространства, чтобы открыть Большой портал и провести через него солдат и служителей, но вскоре они пожалели об этом. Сейчас портал разрушен, и Соттах-Еснад попытается его восстановить.",
	["qreward"] = {["coins"] = 248, ["xp"] = 6000, ["item"] = {{112,1},{75,1}}}},
	{["name"] = "Волшебный зелёный минерал", ["type"] = "f", ["qr"] = 126, ["targ"] = {{55,1}}, ["minlvl"] = 10,
	["descr"] = "Зелёный изумрудный кристалл - важный компонент в создании зачарованных вещей. Защитники крепости будут благодарны за новое снаряжение.",
	["qreward"] = {["coins"] = 86, ["xp"] = 2270, ["item"] = {{75,1}}}}, --40
	{["name"] = "Нехватка древесины", ["type"] = "f", ["qr"] = 11, ["targ"] = {{21,3}}, ["minlvl"] = 3,
	["descr"] = "По просьбе кузнеца найдите в зелёных лугах древесные пни и соберите немного древесины.",
	["qreward"] = {["coins"] = 35, ["xp"] = 120, ["item"] = nil}},
	{["name"] = "Скелеты разбойников", ["type"] = "k", ["qr"] = 74, ["targ"] = 77, ["num"] = 4, ["minlvl"] = 11,
	["descr"] = "Недалеко от крепости вы можете найти заколдованных скелетов. Нужно выяснить, мог ли ими кто-либо управлять.",
	["gtext"]="",
	["qreward"] = {["coins"] = 100, ["xp"] = 500, ["item"] = nil},["fct"] = "setquest", ["value"] = 43}, --42
	{["name"] = "Странный предмет", ["type"] = "t", ["qr"] = 55, ["targ"] = nil, ["minlvl"] = 1,
	["descr"] = "Нужно найти алхимика, возможно он что-то знает об этом камне.",
	["qreward"] = {["coins"] = 0, ["xp"] = 1000, ["item"] = nil},["fct"] = "setquest", ["value"] = 44},
	{["name"] = "Механизм оживления", ["type"] = "k", ["qr"] = 74, ["targ"] = 78, ["num"] = 4, ["minlvl"] = 1,
	["descr"] = "Разведчики заметили, как один из големов раскапывает землю и оживляет мертвых при помощи неизвестного чёрного камня. Выясните, так ли это на самом деле и доложите коменданту Кану Вушену.",
	["qreward"] = {["coins"] = 50, ["xp"] = 750, ["item"] = nil},["fct"] = "setquest", ["value"] = 45},
	{["name"] = "Данные разведки", ["type"] = "t", ["qr"] = 55, ["targ"] = nil, ["minlvl"] = 1,
	["descr"] = "Расскажите алхимику о случившемся.",
	["qreward"] = {["coins"] = 200, ["xp"] = 1500, ["item"] = {{75,1}}}}, --45
	
}

for f = 1, #gqd do
gqd[f]["qstgve"] = nil
gqd[f]["name"] = lang(gqd[f]["name"])
gqd[f]["comp"] = 0
end

local gsd = {
	{["name"] = "Физическая атака", ["distance"] = 0, ["type"] = "attack", ["typedm"] = "p", ["lvl"] = 1, ["reloading"] = 1,
	["basedmgmlt"] = 100,
	["reqlvl"] = {1,5,10,15,20,25,30}, ["reqcn"] = {0,0,0,0,0,0,0}, ["reqitem"] = nil, 
	["manacost"] = {0,0,0,0,0,0,0}, ["eff"] = nil,["descr"] = {"Обычная атака."}},
	{["name"] = "Глубокий порез", ["distance"] = 0, ["type"] = "attack", ["typedm"] = "p", ["lvl"] = 1, ["reloading"] = 3,
	["value"] = {12,21,34,51,72,104,149}, ["basedmgmlt"] = 100,
	["reqlvl"] = {1,3,5,7,10,15,20}, ["reqcn"] = {0,32,65,84,125,178,252}, ["reqitem"] = {{75,1},{75,1},{75,1},{75,1},{75,1},{75,1},{75,1}},
	["manacost"] = {5,6,7,9,11,13,15}, ["eff"] = nil,["descr"] = {"Наносит базовый физический урон плюс $b ед.","$a урона."}},
	{["name"] = "Кровопускание", ["distance"] = 0, ["type"] = "attack", ["typedm"] = "p", ["lvl"] = 1, ["reloading"] = 8,
	["basedmgmlt"] = 100,["reqlvl"] = {1,3,8,12,17,24,33}, ["reqcn"] = {0,45,82,110,146,203,295}, ["reqitem"] = {{75,1},{75,1},{75,1},{75,1},{75,1},{75,1},{75,1}},
	["manacost"] = {6,11,16,23,33,46,64}, ["eff"] = 3,["descr"] = {"Наносит базовый физический урон, плюс $v ед.","урона за $d сек."}},
	{["name"] = "Яростный удар", ["distance"] = 1, ["type"] = "attack", ["typedm"] = "p", ["lvl"] = 1, ["reloading"] = 4, 
	["reqlvl"] = {3,7,12,17,22,31,41}, ["reqcn"] = {50,89,156,285,447,744,1178}, ["reqitem"] = {{75,1},{75,1},{75,1},{75,1},{75,1},{75,1},{75,1}},
	["value"] = {25,43,66,91,139,194,286}, ["basedmgmlt"] = 100,
	["manacost"] = {7,10,13,18,24,32,42}, ["eff"] = nil,["descr"] = {"Наносит базовый физический урон, плюс $b ед.","$a урона."}},
	{["name"] = "Удар шторма", ["distance"] = 0, ["type"] = "attack", ["typedm"] = "p", ["lvl"] = 1, ["reloading"] = 8,
	["value"] = {16,34,52,88,131,186,254}, ["basedmgmlt"] = 100, ["weapondmgmlt"] = {25,30,35,40,45,50,60},
	["reqlvl"] = {5,10,15,22,30,39,50}, ["reqcn"] = {84,134,189,364,527,819,1434}, ["reqitem"] = {{75,1},{75,1},{75,1},{75,1},{75,1},{75,1},{75,1}},
	["manacost"] = {11,19,28,39,54,72,94}, ["eff"] = 5,["descr"] = {"Мощная атака, наносящая базовый физический","урон, плюс $e% урона оружия, плюс"," $b ед. $a урона. Оглушает","противника на $d сек."}},	
	{["name"] = "Железный плащ", ["type"] = "buff", ["lvl"] = 1, ["reloading"] = 25,
	["reqlvl"] = {5,9,14,19,24,29,35}, ["reqcn"] = {20,47,86,118,152,211,324}, ["reqitem"] = {{75,1},{75,1},{75,1},{75,1},{75,1},{75,1},{75,1}},
	["manacost"] = {18,30,48,72,102,140,185}, ["eff"] = 4,["descr"] = {"Вы получаете дополнительные $v% физической","защиты на $d сек."}}, 
	{["name"] = "Стремительный удар", ["distance"] = 0, ["type"] = "attack", ["typedm"] = "p", ["lvl"] = 1, ["reloading"] = 15,
	["value"] = {22,39,65,98,152,207,292}, ["basedmgmlt"] = 100, ["weapondmgmlt"] = {35,40,45,50,55,60,65},
	["reqlvl"] = {14,19,24,30,36,42,49}, ["reqcn"] = {84,134,189,264,327,419,534}, ["reqitem"] = {{75,1},{75,1},{75,1},{75,1},{75,1},{75,1},{75,1}},
	["manacost"] = {15,25,36,47,59,71,84}, ["eff"] = 12,["descr"] = {"Сокрушительный удар наносит базовый физический","урон, плюс $e ед. урона оружия, плюс"," $b ед. $a урона. Снижает","физическую защиту противника на $v%","на $d сек."}},
	{["name"] = "Воодушевление", ["type"] = "buff", ["lvl"] = 1, ["reloading"] = 30, 
	["reqlvl"] = {9,19,25,29,35,39,45}, ["reqcn"] = {138,252,371,524,850,1300,1915}, ["reqitem"] = {{75,1},{75,1},{75,1},{75,1},{75,1},{75,1},{75,1}},
	["manacost"] = {40,60,85,115,155,200,240}, ["eff"] = 13,["descr"] = {"Мгновенное восстановление $v% здоровья."}},
	{["name"] = "Удар пустоты", ["distance"] = 0, ["type"] = "attack", ["typedm"] = "p", ["lvl"] = 1, ["reloading"] = 20,
	["value"] = {102,155,217,291,377,470,573}, ["basedmgmlt"] = 100, ["weapondmgmlt"] = {50,55,60,65,70,75,80},
	["reqlvl"] = {15,20,25,30,35,40,45}, ["reqcn"] = {154,227,315,432,555,864,1320}, ["reqitem"] = {{75,1},{75,1},{75,1},{75,1},{75,1},{75,1},{75,1}},
	["manacost"] = {44,67,95,131,182,239,306}, ["eff"] = 14,["descr"] = {"Точный удар наносит базовый физический","урон, плюс $e ед. урона оружия, плюс"," $b ед. $a урона. Оглушает","противника на $d сек."}},
	
	
}

local eusd = {
	[1]={["distance"]=0,["type"]="attack",["mindamage"] = {0}, ["maxdamage"] = {0},["typedm"] = "p",["eff"]=nil},
	[2]={["distance"]=0,["type"]="attack",["mindamage"] = {0}, ["maxdamage"] = {0},["typedm"] = "m",["eff"]=nil},
	[3]={["distance"]=0,["type"]="attack",["mindamage"] = {-2}, ["maxdamage"] = {-1},["typedm"] = "m",["eff"]={7,1}},
	[4]={["distance"]=0,["type"]="attack",["mindamage"] = {-1}, ["maxdamage"] = {0},["typedm"] = "m",["eff"]={6,1}},
	[5]={["distance"]=0,["type"]="attack",["mindamage"] = {0}, ["maxdamage"] = {1},["typedm"] = "m",["eff"]={8,1}},
	[6]={["distance"]=0,["type"]="attack",["mindamage"] = {0}, ["maxdamage"] = {1},["typedm"] = "m",["eff"]={7,2}},
	[7]={["distance"]=1,["type"]="attack",["mindamage"] = {0}, ["maxdamage"] = {1},["typedm"] = "m",["eff"]={9,1}},
	[8]={["distance"]=3,["type"]="attack",["mindamage"] = {2}, ["maxdamage"] = {5},["typedm"] = "p",["eff"]={10,1}},
	[9]={["distance"]=5,["type"]="attack",["mindamage"] = {3}, ["maxdamage"] = {12},["typedm"] = "m",["eff"]={11,1}},
	[10]={["distance"]=0,["type"]="attack",["mindamage"] = {0}, ["maxdamage"] = {0},["typedm"] = "m",["eff"]={7,3}},
}

local ged = {
	[1]={["name"]="Исцеляющее зелье",["type"]="hpi", ["descr"]="Восстановление здоровья",
	["dur"]={10,10,10,10,10,10},["val"]={35,60,125,210,320,620},["i"]={0xff4940,"H",0xff9200,"▲",0xff4940," ",0xff4940,"P",0xff9200,"▼",0xff4940," "}},
	[2]={["name"]="Бодрящее зелье",["type"]="mpi", ["descr"]="Восстановление маны",
	["dur"]={10,10,10,10,10,10},["val"]={30,50,110,190,285,540},["i"]={0x3349ff,"M",0x336dff,"▲",0x3349ff," ",0x3349ff,"P",0x336dff,"▼",0x3349ff," "}},
	[3]={["name"]="Кровоточащая рана",["type"]="hpd", ["descr"]="Наносит урон",
	["dur"]={12,12,12,12,12,12},["val"]={15,38,69,90,137,192},["i"]={0x662400," ",0x787878," ",0x662400," ",0x787878," ",0x662400," ",0x787878," "}},
	[4]={["name"]="Железный плащ",["type"]="pdfi%", ["descr"]="Увеличивает защиту",
	["dur"]={60,90,120,180,260,340},["val"]={15,20,25,30,35,40,45},["i"]={0xffdb80," ",0xffdb80,"Θ",0xffdb80," ",0xa4a4a4," ",0xffdb80," ",0xa4a4a4," "}},
	[5]={["name"]="Оглушение",["type"]="stn", ["descr"]="Не может двигаться и атаковать",
	["dur"]={3,3,3,3,3,3},["i"]={0x662480," ",0xcc9240," ",0x662480," ",0x994940," ",0x662480," ",0x994940," "}},
	[6]={["name"]="Обездвиживание",["type"]="ste", ["descr"]="Не может двигаться",
	["dur"]={3},["i"]={0xccb680," ",0xccb680," ",0xccb680," ",0xccb680,"*",0xccb680," ",0xccb680," "}},
	[7]={["name"]="Слабость духа",["type"]="mpi", ["descr"]="Уменьшение маны",
	["dur"]={5,5,10},["val"]={-5,-10,-45},["i"]={0x66dbff," ",0x99dbff," ",0x66dbff," ",0x66dbff," ",0x99dbff," ",0x66dbff," "}},
	[8]={["name"]="Ранение",["type"]="hpd", ["descr"]="Уменьшение здоровья",
	["dur"]={5},["val"]={10},["i"]={0xcc6d40," ",0xff9240," ",0xcc6d40," ",0xcc6d40," ",0xff9240," ",0xcc6d40," "}},
	[9]={["name"]="Отравление",["type"]="hpd", ["descr"]="Наносит урон",
	["dur"]={10},["val"]={15},["i"]={0x99dbbf," ",0x339280," ",0x99dbbf," ",0x339280," ",0x339280," ",0x339280," "}},
	[10]={["name"]="Оглушение",["type"]="stn", ["descr"]="Не может двигаться и атаковать",
	["dur"]={1},["i"]={0x662480," ",0xcc9240," ",0x662480," ",0x994940," ",0x662480," ",0x994940," "}},
	[11]={["name"]="Сильный яд",["type"]="hpd", ["descr"]="Наносит урон",
	["dur"]={10},["val"]={25},["i"]={0x99dbbf," ",0x336d40," ",0x99dbbf," ",0x336d40," ",0x99dbbf," ",0x336d40," "}},
	[12]={["name"]="Неловкость",["type"]="pdfi%", ["descr"]="Снижает защиту",
	["dur"]={10,10,10,10,10,10},["val"]={-8,-10,-12,-14,-16,-18,-20},["i"]={0x994940," ",0x996dbf," ",0x994940," ",0x996dbf," ",0x994940," ",0x996dbf," "}},
	[13]={["name"]="Воодушевление",["type"]="hpi%", ["descr"]="",
	["dur"]={1,1,1,1,1,1},["val"]={70,75,80,85,90,95},["i"]={0xff0040,"*",0xff9200,"*",0xff0040,"*",0xff0040,"*",0xff9200,"*",0xff0040,"*"}},
	[14]={["name"]="Оглушение",["type"]="stn", ["descr"]="Не может двигаться и атаковать",
	["dur"]={3,4,5,6,7,8},["i"]={0x662480," ",0xcc9240," ",0x662480," ",0x994940," ",0x662480," ",0x994940," "}},
}

local cPlayerSkills = {{1,0,1},{2,0,1},{3,0,1},{4,0,1},{5,0,0},{6,0,1},{7,0,0},{8,0,0},{9,0,0}}
local cUskills = {1,2,3,4,5,7}

local imageBuffer = {} -- буффер для картинок, чтобы не грузить процессор и диск | версия 1.2 17

local iconImageBuffer = {} -- буффер для иконок предметов | версия 1.2 17

local CGD = {} -- массив со всеми персонажами

local cUquests = {} -- структура -- [1] (и т.д.) = {1(id),0(прогресс),false(не выполнено/выполнено)} 

local inventory = {
["weared"] = {
["helmet"] = 0,
["pendant"] = 0,
["bodywear"] = 0,
["robe"] = 0,
["pants"] = 0,
["weapon"] = 7,
["footwear"] = 0,
["ring"] = 0},
["bag"] = {}
}
for f = 1, 20 do
inventory["bag"][f] = {}
inventory["bag"][f][1] = 0
inventory["bag"][f][2] = 0
end

local cGlobalx, cBackgroundPos = 1, 1
local pSprPicPos = 75
local cTarget = 0
local paused = false
local cWindowTrd = nil
local showTargetInfo = false
local pckTarget = 0
local pickingUp = false
local maxPckTime = 0
local pckTime = 0
local pmov = 0
gfunc.usepmx = false

local stopDrawing = false
local ingame = true
local playerCanMove = true
local cmp, mmp, cxp, mxp, cCoins = 0, 0, 0, 0, 0
local cDialog

local charPoints = gud[1]["lvl"]-1
local survivability = 1
local strength = 1
local intelligence = 1

local world = {
current = 1,
[1]={
	name = "Деревня Зеленый Камень",
	limitL = -160,
	limitR = 105,
	drespawn = 1,
	drx = 1,
	spawnList = {
		{27,-107,1},
		{26,-80,1},
		{11,-68,1},
		{10,-47,1},
		{5,-25,1},
		{12,45,1}
		},
	draw = function()
	buffer.square(1, 1, 160, 47, 0x00AAFF)
	buffer.square(1, 48, 160, 1, 0x755340)
	buffer.square(1, 49, 160, 2, 0x339240)
	end,
	},
[2]={
	name = "Зеленые луга",
	limitL = -60,
	limitR = 1700,
	drespawn = 1,
	drx = 1,
	spawnList = {
		{13,-27,1},
		{2,95,1,5,42},
		{3,305,2,5,45},
		{4,530,1,7,24},
		{6,710,1,3,45},
		{7,845,1,3,45},
		{8,980,1,3,45},
		{9,1115,1,3,45},
		{14,1250,1,3,45},
		{15,1385,1,6,45},
		{19,1692,-2},
		{21,283,1},
		{21,920,1},
		{21,1178,1},
		{22,542,1},
		{22,737,1},
		{22,1321,1},
		{22,994,1},
		{24,475,1},
		{24,841,1},
		{25,377,1},
		{25,1034,1},
		},
	draw = function()
	buffer.square(1, 1, 160, 47, 0x00AAFF)
	buffer.square(1, 48, 160, 1, 0x755340)
	buffer.square(1, 49, 160, 2, 0x339240)
	end,
	},
[3]={
	name = "Пещера",
	limitL = -60,
	limitR = 500,
	drespawn = 4,
	drx = 1,
	spawnList = {
		{18,-25,1},
		{16,68,1,3,45},
		{29,216,1,3,45},
		{31,361,1},
		},
	draw = function()
	buffer.square(1, 1, 160, 47, 0x656565, 0xFFFFFF, " ")
	buffer.square(1, 1, 160, 3, 0x616161, 0xFFFFFF, " ")
	buffer.square(1, 48, 160, 1, 0x585858, 0xFFFFFF, " ")
	buffer.square(1, 49, 160, 2, 0x434343, 0xFFFFFF, " ")
	end,
	},
[4]={
	name = "Посёлок у холма",
	limitL = -130,
	limitR = 105,
	drespawn = 4,
	drx = 1,
	spawnList = {
		{135,-120,1},
		{28,-102,1},
		{133,-78,1},
		{134,-57,1},
		{20,-20,1},
		{30,23,1},
		{39,8,1},
		{44,38,1}
		},
	draw = function()
	buffer.square(1, 1, 160, 47, 0x00AAFF)
	buffer.square(1, 48, 160, 1, 0x755340)
	buffer.square(1, 49, 160, 2, 0x339240)
	end,
	},
[5]={
	name = "Могильник",
	limitL = -60,
	limitR = 1550,
	drespawn = 4,
	drx = 1,
	spawnList = {
		{32,75,1,3,45},
		{33,210,1,4,105},
		{34,248,1,4,105},
		{35,773,1},
		{36,801,1,2,65},
		{37,927,1,3,55},
		{38,1096,1},
		{40,1148,1,5,45},
		{41,1375,1,2,45},
		{42,1464,1},
		},
	draw = function()
	buffer.square(1, 1, 160, 47, 0x757575)
	buffer.square(1, 1, 160, 3, 0x717171)
	buffer.square(1, 48, 160, 1, 0x686868)
	buffer.square(1, 49, 160, 2, 0x535353)
	end,
	},
[6]={
	name = "Равнина",
	limitL = -60,
	limitR = 1190,
	drespawn = 4,
	drx = 1,
	spawnList = {
		{45,-27,1},
		{14,105,1,3,45},
		{47,245,1,3,45},
		{48,380,1,2,45},
		{49,480,1,3,45},
		{50,610,1,3,45},
		{51,740,1,3,45},
		{52,870,1,3,45},
		{53,1000,1},
		{21,143,1},
		{21,563,1},
		{21,878,1},
		{22,604,1},
		{22,921,1},
		{24,320,1},
		{24,783,1},
		{25,377,1},
		{25,811,1},
		{140,1200,1},
		},
	draw = function()
	buffer.square(1, 1, 160, 47, 0x00AAFF)
	buffer.square(1, 48, 160, 1, 0x755340)
	buffer.square(1, 49, 160, 2, 0x339240)
	end,
	},
[7]={
	name = "Тайное подземелье",
	limitL = -60,
	limitR = 1650,
	drespawn = 4,
	drx = 1,
	spawnList = {
		{62,-50,1},
		{56,75,1,3,65},
		{57,270,1,3,65},
		{58,485,1},
		{60,360,1,5,55},
		{59,790,1},
		{61,820,1,4,55},
		{63,1065,1},
		{61,1090,1,4,45},
		{64,1270,1,3,55},
		{65,1450,1},
		{66,1550,1},
		},
	draw = function()
	buffer.square(1, 1, 160, 47, 0x757575)
	buffer.square(1, 1, 160, 3, 0x717171)
	buffer.square(1, 48, 160, 1, 0x686868)
	buffer.square(1, 49, 160, 2, 0x535353)
	end,
	},
[8]={
	name = "Крепость малой реки",
	limitL = -100,
	limitR = 115,
	drespawn = 4,
	drx = 1,
	spawnList = {
		{139,-102,1},
		{55,-78,1},
		{136,-57,1},
		{67,-35,1},
		{68,-20,1},
		{137,25,1},
		{138,42,1},
		{99,57,1},
		{74,98,1},
		{69,120,1},
		{126,75,1},
		},
	draw = function()
	buffer.square(1, 1, 160, 47, 0x00AAFF)
	buffer.square(1, 48, 160, 1, 0x755340)
	buffer.square(1, 49, 160, 2, 0x339240)
	end,
	},
[9]={
	name = "Равнина",
	limitL = -60,
	limitR = 2000,
	drespawn = 4,
	drx = 1,
	spawnList = {
		{70,-27,1},
		{71,135,1,5,55},
		{72,410,1,4,55},
		{73,640,1,4,65},
		{75,900,1,4,65},
		{77,1180,1,4,65},
		{78,1440,1,4,65},
		{76,1750,1},
		{21,413,1},
		{21,759,1},
		{21,1723,1},
		{22,328,1},
		{22,895,1},
		{22,1572,1},
		{22,673,1},
		{24,475,1},
		{24,841,1},
		{25,612,1},
		{25,856,1},
		{25,1356,1},
		},
	draw = function()
	buffer.square(1, 1, 160, 47, 0x00AAFF)
	buffer.square(1, 48, 160, 1, 0x755340)
	buffer.square(1, 49, 160, 2, 0x339240)
	end,
	},
[10]={
	name = "Долина мрачных миражей",
	limitL = -40,
	limitR = 4550,
	drespawn = 8,
	drx = 1,
	spawnList = {
		{79,-25,1},
		{80,135,1,5,75},
		{81,510,1,3,75},
		{82,735,3,4,75},
		{83,1035,1,4,75},
		{84,1335,1,5,75},
		{85,1750,1},
		{86,1850,1,5,75},
		{87,2225,1,5,75},
		{88,2650,3},
		{89,1010,1},
		{90,2750,1,5,75},
		{91,3125,1,5,75},
		{92,3530,1},
		{93,3630,1,5,75},
		{94,4040,1},
		{95,4150,1,5,75},
		{97,4550,3},
		},
	draw = function()
	buffer.square(1, 1, 160, 18, 0x00AAFF)
	buffer.square(1, 19, 160, 29, 0x898989)
	buffer.square(1, 19, 160, 1, 0xA7A7A7)
	buffer.square(1, 20, 160, 1, 0x999999)
	buffer.square(1, 48, 160, 1, 0x755340)
	buffer.square(1, 49, 160, 2, 0x339240)
	end,
	},
[11]={
	name = "Долина мрачных миражей",
	limitL = -40,
	limitR = 200,
	drespawn = 8,
	drx = 1,
	spawnList = {
		{98,-25,3},
		{96,160,1}
		},
	draw = function()
	buffer.square(1, 1, 160, 18, 0x00AAFF)
	buffer.square(1, 19, 160, 29, 0x898989)
	buffer.square(1, 19, 160, 1, 0xA7A7A7)
	buffer.square(1, 20, 160, 1, 0x999999)
	buffer.square(1, 48, 160, 1, 0x755340)
	buffer.square(1, 49, 160, 2, 0x339240)
	end,
	},
[12]={
	name = "Подземный ход",
	limitL = -60,
	limitR = 3190,
	drespawn = 8,
	drx = 1,
	spawnList = {
		{79,-25,1},
		{101,135,1,5,75},
		{102,510,1,5,70},
		{103,880,3},
		{104,970,1},
		{106,1070,1,5,65},
		{105,1400,2},
		{107,1480,1,4,65},
		{108,1760,1,2,120},
		{109,1805,1,2,120},
		{110,2050,1},
		{113,2130,1,9,50},
		{114,2500,1,6,45},
		{115,2825,1},
		{114,2920,1,4,45},
		{127,3140,2},
		},
	draw = function()
	buffer.square(1, 1, 160, 3, 0x151515)
	buffer.square(1, 1, 160, 20, 0x999280)
	buffer.square(1, 21, 160, 27, 0x757575)
	buffer.square(1, 1, 160, 3, 0x717171)
	buffer.square(1, 48, 160, 1, 0x686868)
	buffer.square(1, 49, 160, 2, 0x535353)
	end,
	},
[13]={
	name = "Зелёный коридор",
	limitL = -60,
	limitR = 405,
	drespawn = 8,
	drx = 1,
	spawnList = {
		{111,-25,1},
		{108,80,1},
		{112,120,1},
		{113,190,1,12,35},
		},
	draw = function()
	buffer.square(1, 1, 160, 3, 0x151515)
	buffer.square(1, 1, 160, 20, 0x999280)
	buffer.square(1, 21, 160, 27, 0x757575)
	buffer.square(1, 1, 160, 3, 0x717171)
	buffer.square(1, 48, 160, 1, 0x686868)
	buffer.square(1, 49, 160, 2, 0x535353)
	end,
	},
[14]={
	name = "Вход в монастырь Увеула",
	limitL = -60,
	limitR = 700,
	drespawn = 8,
	drx = 1,
	spawnList = {
		{128,-25,2},
		{123,130,1,8,32},
		{120,490,1},
		{124,590,1},
		{125,650,1},
		},
	draw = function()
	buffer.square(1, 1, 160, 3, 0x151515)
	buffer.square(1, 1, 160, 20, 0x999280)
	buffer.square(1, 21, 160, 27, 0x757575)
	buffer.square(1, 1, 160, 3, 0x717171)
	buffer.square(1, 48, 160, 1, 0x686868)
	buffer.square(1, 49, 160, 2, 0x535353)
	end,
	},
}

local function clicked(x,y,x1,y1,x2,y2)
 if x >= x1 and x <= x2 and y >= y1 and y <= y2 then 
 return true 
 end   
 return false
end

local function toboolean(v)
 if v == "true" then return true
 end
return false
end

function gfunc.random(n1,n2,accuracy)
return math.random(n1*(accuracy or 1),n2*(accuracy or 1))/(accuracy or 1)
end

function gfunc.scolorText(x,y,col,str)
local dsymb = "^"
local pcl, cs, f, s = col, nil, 1, 1
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

local function getDistance(from,x)
local dist = 0
local x1, x2 = CGD[from]["x"], x
if x1 < x2 then dist = x2-x1
elseif x1 > x2 then dist = x1-x2
end
return dist
end

local function getDistanceToId(from,to)
local dist = 0
local x1, x2 = CGD[from]["x"], CGD[to]["x"]
if x1 < x2 then dist = x2-x1-CGD[from]["width"]
elseif x1 > x2+CGD[to]["width"] then dist = x1-x2-CGD[to]["width"]
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
pSprPicPos = 75-getDistance(1,x)
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
 if getDistance(id,x) < distanceLimit and x < CGD[id]["x"] then
 CGD[id]["x"] = CGD[id]["x"] - step
 CGD[id]["spos"] = "l"
 elseif getDistance(id,x) < distanceLimit and x > CGD[id]["x"] then
 CGD[id]["x"] = CGD[id]["x"] + step
 CGD[id]["spos"] = "r"
 end
end

function gfunc.playerAutoMove(x, distanceLimit, step)
 if getDistance(1,x) >= step and getDistance(1,x) < distanceLimit and x < CGD[1]["x"] then
 CGD[1]["spos"] = "l" 
 pmov = -step
 elseif getDistance(1,x) >= step and getDistance(1,x) < distanceLimit and x > CGD[1]["x"] then
 CGD[1]["spos"] = "r"
 pmov = step
 else
 CGD[1]["mx"] = CGD[1]["x"]
 CGD[1]["image"] = 0
 pmov = 0
 gfunc.usepmx = false
 end
end

function gfunc.roundupnum(num)
local res
 if num - math.floor(num) < 0.5 then 
 res = math.floor(num)
 else
 res = math.ceil(num)
 end
return res
end

local function insertQuests(id,dialog)
local var, povar
local newDialog = dialog
local cQue = gud[CGD[id]["id"]]["quests"]
local insQuestDialog = true 
 if type(cQue) == "table" and cDialog["im"] ~= nil then
  povar = 1
  table.insert(cQue,0)
  for n = 1, #dialog do
   if dialog[n]["action"] == "dialog" then
   insQuestDialog = false
   break
   end
  end
  if insQuestDialog then
  table.insert(newDialog,1,{["dq"]=0,["text"]=lang("Задания"),["action"]="dialog",["do"] ={["text"]="Выберите любые доступные задания"}})
  end
  for f = 1, #cQue do
  var = true
   for q = 1, #cUquests do
    if cUquests[q][1] == cQue[f] and cUquests[q][3] then
     if CGD[1]["lvl"] < gqd[cQue[f]]["minlvl"] or gqd[cQue[f]]["comp"] or not gqd[cQue[f]]["comp"] then
	 var = false
     break
	 end
    end
   end
   if var and cQue[f] > 0 and cQue[f] <= #gqd and newDialog[1]["dq"]~=nil then
   newDialog[1]["do"][povar] = {["q"]=cQue[f],["text"]=gqd[cQue[f]]["name"],["action"]="qdialog",
    ["do"] = {
		["text"]=gqd[cQue[f]]["gtext"] or "Новое задание",
		{["text"]="Я готов выполнить задание",["action"]="getquest",["do"]=cQue[f]},
		{["text"]="Не сейчас",["action"]="close",["do"]=nil}
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
  newDialog[1]["do"][#newDialog[1]["do"]+1] = {["text"]=lang("До встречи"),["action"]="close",["do"]=nil}
  end
 end
return newDialog
end

local sMSG1, smsg1time = {"",""}, 0

local function addsmsg1(msg)
table.insert(sMSG1,msg)
smsg1time = 8
end

local sMSG2, smsg2time = {""}, 0

local function addsmsg2(msg)
table.insert(sMSG2,msg)
smsg2time = 5
end

sMSG3 = ""

local function addsmsg3(msg)
sMSG3 = msg
end

local sMSG4, smsg4time = {"","",""}, 0

local function addsmsg4(msg)
table.insert(sMSG4,msg)
smsg4time = 5
end

local consDataR = {}

local function booleanToString(b)
 if b then
 return "true"
 end
 return "false"
end

local console={}
function console.debug(...)
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
table.insert(consDataR,msg)
end

function console.wError(e)
if type(e) == "string" then table.insert(consDataR,"!/"..e) end
end

local function addUnit(id,x,y)
local cUSprite
CGD[#CGD+1] = {}
CGD[#CGD]["sx"] = x
CGD[#CGD]["mx"] = x
CGD[#CGD]["x"] = x
CGD[#CGD]["y"] = y
CGD[#CGD]["id"] = gud[id]["id"]
CGD[#CGD]["lvl"] = gud[id]["lvl"]
CGD[#CGD]["spos"] = "r"
CGD[#CGD]["image"] = 0
 if CGD[#CGD]["image"] ~= nil then
 cUSprite = image.load(dir.."sprpic/"..gud[id]["image"]..".pic")
 CGD[#CGD]["width"] = cUSprite.width
 CGD[#CGD]["height"] = cUSprite.height
 end
 cUSprite = nil
 if gud[id]["mhp"] == nil then
 CGD[#CGD]["mhp"] = math.ceil(36+(gud[id]["lvl"]-1)*36.3+((gud[id]["lvl"]-1)^2-1)/2)
 else
 CGD[#CGD]["mhp"] = gud[id]["mhp"]
 end
 if gud[id]["hpmul"] then
 CGD[#CGD]["mhp"] = math.ceil(CGD[#CGD]["mhp"] * gud[id]["hpmul"])
 end
CGD[#CGD]["chp"] = CGD[#CGD]["mhp"]
if not gud[id]["ptk"] then CGD[#CGD]["ptk"] = {
math.ceil(CGD[#CGD]["lvl"]*1.25+CGD[#CGD]["lvl"]^0.2),
math.ceil(CGD[#CGD]["lvl"]*1.42+CGD[#CGD]["lvl"]^0.6)
}
else CGD[#CGD]["ptk"] = gud[id]["ptk"] end
if not gud[id]["mtk"] then CGD[#CGD]["mtk"] = {
math.ceil(CGD[#CGD]["lvl"]*1.38+CGD[#CGD]["lvl"]^0.2),
math.ceil(CGD[#CGD]["lvl"]*1.52+CGD[#CGD]["lvl"]^0.6)
} 
else CGD[#CGD]["mtk"] = gud[id]["mtk"] end
CGD[#CGD]["pdef"] = 0
CGD[#CGD]["mdef"] = 0
CGD[#CGD]["resptime"] = 0
CGD[#CGD]["living"] = true
CGD[#CGD]["cmove"] = true
CGD[#CGD]["ctck"] = true
CGD[#CGD]["rtype"] = gud[id]["rtype"]
CGD[#CGD]["attPlayer"] = false
CGD[#CGD]["tlinfo"] = {}
 if gud[id]["rtype"] == "f" then 
 CGD[#CGD]["dialog"] = gud[id]["dialog"]
 end
CGD[#CGD]["effects"] = {}
console.debug("Добавление","id:"..tostring(gud[id]["id"]),"имя:"..gud[id]["name"],"x:"..tostring(x),"y:"..tostring(y),"Gid:"..#CGD)
end

console.wError(preduprejdenie)

console.debug("Загрузка ("..unicode.sub(os.date(), 1, -4)..")")

function gfunc.checkInventoryisFull()
local full = true
 for f = 1, #inventory["bag"] do
 if inventory["bag"][f][2] == 0 then full = false end
 end
return full
end

function gfunc.checkInventorySpace()
local space = 0
 for f = 1, #inventory["bag"] do
 if inventory["bag"][f][1] == 0 then space = space + 1 end
 end
return space
end

local lostItem

local function addItem(itemid,num)
local vparInvEx = 0
local r = 0
 for f = 1, #inventory["bag"] do
  if inventory["bag"][f][2] == 0 then
  inventory["bag"][f][1] = 0
  if inventory["bag"][f][1] >= 200 then gid[inventory["bag"][f][1]] = nil end
  iconImageBuffer[f] = nil
  end
 end
 if not gid[itemid] or not gid[itemid]["stackable"] then
  for f = 1, #inventory["bag"] do
   if inventory["bag"][f][1] == 0 then 
   vparInvEx = 1
   inventory["bag"][f][1] = itemid
   inventory["bag"][f][2] = num
    if cWindowTrd == "inventory" then
	iconImageBuffer[f] = image.load(dir.."itempic/"..aItemIconsSpr[gid[inventory["bag"][f][1]]["icon"]]..".pic")
    end
   r = f
   break 
   end
  end
 end
 if gid[itemid] and gid[itemid]["stackable"] and vparInvEx == 0 then
  for i = 1, #inventory["bag"] do
   if inventory["bag"][i][1] == itemid then
   inventory["bag"][i][2] = inventory["bag"][i][2] + num
   vparInvEx = 1
   r = i
   break
   end
  end
  if vparInvEx == 0 then
   for i = 1, #inventory["bag"] do
    if inventory["bag"][i][1] == 0 or inventory["bag"][i][2] == 0 then
	inventory["bag"][i][1] = itemid
	inventory["bag"][i][2] = num
	vparInvEx = 1
    if cWindowTrd == "inventory" then
	iconImageBuffer[i] = image.load(dir.."itempic/"..aItemIconsSpr[gid[inventory["bag"][i][1]]["icon"]]..".pic")
    end	
	r = i
	break
	end
   end
  end
 end
 if vparInvEx == 0 and gfunc.checkInventoryisFull() then
 lostItem = {itemid,num}
 console.debug("Инвентарь переполнен")
 addsmsg1("Инвентарь переполнен!")
 end
 for f = 1, #inventory["bag"] do
  if inventory["bag"][f][1] ~= 0 and gid[inventory["bag"][f][1]] and not gid[inventory["bag"][f][1]]["stackable"] and inventory["bag"][f][2] > 1 then
  inventory["bag"][f][2] = 1
  end
 end
return r
end

local function getRandSeq(massiv) -- эта функция перемешивает значения массива (костыль)
local new = {}
 for e = 1, #massiv do
 new[e] = "_n"
 end
 for f = 1, #massiv do
 table.insert(new,gfunc.random(1,#massiv),massiv[f])
 end
 for e = 1, #new do if new[#new-e+1] == "_n" then table.remove(new,#new-e+1) end end
return new
end
 
local function createNewItem(itemID) 
local newItemID, hu = -1, 0
 while true do
 if not gid[200+hu] then newItemID = 200+hu break end
 hu = hu + 1
 end
 if gid[itemID]["type"] == "armor" or gid[itemID]["type"] == "weapon" then
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
 for e = 1, # list do
 gid[newItemID][list[e]] = gid[itemID][list[e]]
 end
gid[newItemID]["props"] = {["dds"]={}}
 for k, v in pairs(gid[itemID]["props"]) do
 gid[newItemID]["props"][k] = gid[itemID]["props"][k]
 end
 local props = {
	[1]={"hp+",
		["min"] = 4+(gid[itemID]["lvl"])^2,
		["max"] = 5+(gid[itemID]["lvl"])^2*3,
		["weapon"] = 10 + gid[itemID]["lvl"]*2, -- %
		["armor"] = 80 + gid[itemID]["lvl"]*2 -- %
		},
	[2]={"sur+",
		["min"] = math.ceil(gid[itemID]["lvl"]/2),
		["max"] = gid[itemID]["lvl"],
		["weapon"] = 40 + gid[itemID]["lvl"]*2,
		["armor"] = 50 + gid[itemID]["lvl"]*2
		},
	[3]={"str+",
		["min"] = math.ceil(gid[itemID]["lvl"]/2),
		["max"] = gid[itemID]["lvl"],
		["weapon"] = 40 + gid[itemID]["lvl"]*2,
		["armor"] = 50 + gid[itemID]["lvl"]*2
		},
	[4]={"int+",
		["min"] = math.ceil(gid[itemID]["lvl"]/2),
		["max"] = gid[itemID]["lvl"],
		["weapon"] = 40  + gid[itemID]["lvl"]*2,
		["armor"] = 50 + gid[itemID]["lvl"]*2
		},
	[5]={"pdm+",
		["min"] = (gid[itemID]["lvl"]-1)*3,
		["max"] = (gid[itemID]["lvl"]-1)*12,
		["weapon"] = 60 + gid[itemID]["lvl"]*2,
		["armor"] = 0,
		["sub"] = {"spear","axe","sword"}
		},
	[6]={"mdm+",
		["min"] = (gid[itemID]["lvl"]-1)*3,
		["max"] = (gid[itemID]["lvl"]-1)*6,
		["weapon"] = 55 + gid[itemID]["lvl"]*2,
		["armor"] = 0,
		["sub"] = {"magical"}
		},
	[7]={"pdm+",
		["min"] = gid[itemID]["lvl"]^2/2,
		["max"] = gid[itemID]["lvl"]^2/1.3,
		["weapon"] = 0,
		["armor"] = 15 + gid[itemID]["lvl"]*2
		},
	[8]={"mdm+",
		["min"] = gid[itemID]["lvl"]^2/2,
		["max"] = gid[itemID]["lvl"]^2/1.3,
		["weapon"] = 0,
		["armor"] = 15 + gid[itemID]["lvl"]*2
		},
	[9]={"pdf+",
		["min"] = 5+(gid[itemID]["lvl"]-1)^2*3,
		["max"] = 5+(gid[itemID]["lvl"]-1)^2*5,
		["weapon"] = 0,
		["armor"] = 30 + gid[itemID]["lvl"]*2
		},
	[10]={"mdf+",
		["min"] = 5+(gid[itemID]["lvl"]-1)^2*3,
		["max"] = 5+(gid[itemID]["lvl"]-1)^2*5,
		["weapon"] = 0,
		["armor"] = 30 + gid[itemID]["lvl"]*2
		},
	[11]={"mp+",
		["min"] = 4+(gid[itemID]["lvl"])^2,
		["max"] = 5+(gid[itemID]["lvl"])^2*2,
		["weapon"] = 2 + gid[itemID]["lvl"]*2, -- %
		["armor"] = 20 + gid[itemID]["lvl"]*2 -- %
		},
	[12]={"chc+",
		["min"] = 1,
		["max"] = 2,
		["weapon"] = 10,
		["armor"] = 5
		},
	[13]={"hp%",
		["min"] = math.max(math.min(gid[itemID]["lvl"]-2,0),1),
		["max"] = math.max(math.min(gid[itemID]["lvl"]-1,0),5),
		["weapon"] = 0, -- %
		["armor"] = gid[itemID]["lvl"] -- %
		},
	[14]={"mp%",
		["min"] = math.max(math.min(gid[itemID]["lvl"]-2,0),1),
		["max"] = math.max(math.min(gid[itemID]["lvl"]-1,0),5),
		["weapon"] = 0, -- %
		["armor"] = gid[itemID]["lvl"] -- %
		},
	}
 local cccc
 local ddch = {100,45,5,0.5,0.05}
 local adnum = 1
 for f = 1, 5 do
  if gfunc.random(1,10^4)/100 <= ddch[6-f] then
  adnum = 6-f
  break
  end
 end
 local newDds = {}
 local dt, value
  while #newDds < math.min(adnum,gid[itemID]["lvl"]) do
  cccc = false
   dt = gfunc.random(1,#props)
   if gfunc.random(1,10^5) <= props[dt][gid[itemID]["type"]]*10^3 then
   value = math.floor(gfunc.random(props[dt]["min"]*10,props[dt]["max"]*10)/10)
	if props[dt]["sub"] then
	 for j = 1, #props[dt]["sub"] do
	  if gid[itemID]["subtype"] == props[dt]["sub"][j] then
	  cccc = true
	  end
	 end
	elseif value >= 1 then
	cccc = true
	end
   if cccc then table.insert(newDds,{props[dt][1],math.floor(value)}) end
   end
  end
  
 
  for r = 1, #newDds-1 do
   if gid[newItemID]["type"] == "weapon" and not gid[newItemID]["cchg"] then 
    if gid[newItemID]["props"]["phisat"] then 
	gid[newItemID]["props"]["phisat"][1] = math.floor(gid[newItemID]["props"]["phisat"][1]*1.05) 
	gid[newItemID]["props"]["phisat"][2] = math.floor(gid[newItemID]["props"]["phisat"][2]*1.05) 
	end
    if gid[newItemID]["props"]["magat"] then 
	gid[newItemID]["props"]["magat"][1] = math.floor(gid[newItemID]["props"]["magat"][1]*1.1) 
	gid[newItemID]["props"]["magat"][2] = math.floor(gid[newItemID]["props"]["magat"][2]*1.1)
	end
   elseif gid[newItemID]["type"] == "armor" and not gid[newItemID]["cchg"] then
    if gid[newItemID]["props"]["pdef"] then gid[newItemID]["props"]["pdef"] = math.floor(gid[newItemID]["props"]["pdef"]*1.05) end
	if gid[newItemID]["props"]["mdef"] then gid[newItemID]["props"]["mdef"] = math.floor(gid[newItemID]["props"]["mdef"]*1.05) end
   end
  end
  if gid[itemID]["ncolor"] == 0xFFFFFF then
   if #newDds > 0 and #newDds < 3 then gid[newItemID]["ncolor"] = 0x0044FF
   elseif #newDds == 3 then gid[newItemID]["ncolor"] = 0xAB00D3
   elseif #newDds == 4 then gid[newItemID]["ncolor"] = 0xFFB420
   elseif #newDds >= 5 then gid[newItemID]["ncolor"] = 0x35E215
   end
  end
 gid[newItemID]["props"]["dds"] = newDds
 gid[newItemID]["name"] = string.rep("♦",math.min(#newDds,5))..gid[newItemID]["name"]
 gid[newItemID]["cost"] = gid[itemID]["cost"]+math.ceil(gid[itemID]["cost"]/2*math.min(#newDds,5))
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

-- for f = 1, 20 do addItem(createNewItem(gfunc.random(1,116)),gfunc.random(1,10)) end
-- addItem(90,1)
-- addItem(103,1)
-- addItem(105,1)
-- addItem(107,1)
-- addItem(109,1)
-- addItem(111,1)
-- addItem(88,1)
-- addItem(98,1)
-- addItem(112,1)
-- local ym0 = {98}
-- for f = 1, 20 do addItem(createNewItem(ym0[gfunc.random(1,#ym0)]),1) end

local function addPlayerEffect(id,lvl)
local addne = true 
 if type(id) == 'number' and type(lvl) == 'number' and id >= 1 and id <= #ged then
  for eff = 1, #CGD[1]["effects"] do
   if CGD[1]["effects"][eff][1] == id then
   CGD[1]["effects"][eff][2] = ged[id]["dur"][lvl]
   addne = false
   break
   end
  end
 if addne then table.insert(CGD[1]["effects"],{id,ged[id]["dur"][lvl],lvl}) end
 else
 console.wError('addPlayerEffect: неверное значение id или lvl')
 end
end

local function addUnitEffect(uID,eID,lvl)
local addne = true 
 if uID ~= nil and eID ~= nil and lvl ~= nil and eID >= 1 and eID <= #ged then
  buffer.text(50,30,0xffffff,"uID"..uID.."eID"..eID.."lvl"..lvl)
  for eff = 1, #CGD[uID]["effects"] do
   if CGD[uID]["effects"][eff][1] == eID then
   CGD[uID]["effects"][eff][2] = ged[eID]["dur"][lvl]
   addne = false
   break
   end
  end
 if addne then table.insert(CGD[uID]["effects"],{eID,ged[eID]["dur"][lvl],lvl}) end
 else
 console.wError('addUnitEffect: неверное значение uID, eID или lvl')
 end
end

local function inserttunitinfo(u,text)
table.insert(CGD[u]["tlinfo"],text)
end

local function checkItemInBag(itemid)
local d = 0
 for f = 1, #inventory["bag"] do
  if inventory["bag"][f][1] == itemid then 
  d = d + inventory["bag"][f][2]
  end
 end
return d, itemid
end

local vaddsPnts = {vSur=0,vStr=0,vInt=0,vPdm=0,vMdm=0}

function gfunc.playerRefreshVar()
local v = {
["sur+"]=0,["str+"]=0,["int+"]=0,
["hp+"]=0,["mp+"]=0,["vPdm1"]=0,
["pdm+"]=0,["mdm+"]=0,["vMdm1"]=0,
["vPdm2"]=0,["vMdm2"]=0,["pdf+"]=0,
["mdf+"]=0,["chc+"]=0,["hp%"]=0,
["mp%"]=0}
CGD[1]["mhp"], mmp, mxp, CGD[1]["ptk"], CGD[1]["mtk"], CGD[1]["pdef"], CGD[1]["mdef"] = 0, 0, 0, 0, 0, 0, 0
local witypes = {
	"helmet",
	"pendant",
	"bodywear",
	"pants",
	"footwear",
	"robe",
	"ring",
	"weapon"
}
-- 
local CritChan
local buben
 for f = 1, #witypes do
  if inventory["weared"][witypes[f]] ~= 0 and gid[inventory["weared"][witypes[f]]]["props"]["dds"] then
  buben = gid[inventory["weared"][witypes[f]]]["props"]["dds"]
   for e = 1, #buben do
   v[buben[e][1]] = v[buben[e][1]] + buben[e][2]
   end  
  end
  if inventory["weared"][witypes[f]] ~= 0 and gid[inventory["weared"][witypes[f]]]["type"] == "armor" then
  v["pdf+"] = v["pdf+"] + gid[inventory["weared"][witypes[f]]]["props"]["pdef"]
  v["mdf+"] = v["mdf+"] + gid[inventory["weared"][witypes[f]]]["props"]["mdef"] 
  end
 end
 --
 local vAtds = 8 
 CritChan = 1+math.floor((strength+v["str+"])/10)
 CritChan = CritChan+math.floor((intelligence+v["int+"])/10)
 v["vPdm1"], v["vPdm2"], v["vMdm1"], v["vMdm2"] = v["vPdm1"]+v["pdm+"], v["vPdm2"]+v["pdm+"], v["vMdm1"]+v["mdm+"], v["vMdm2"]+v["mdm+"]
 if inventory["weared"]["weapon"] > 0 then
  if gid[inventory["weared"]["weapon"]]["props"]["phisat"] then
  v["vPdm1"] = v["vPdm1"] + gid[inventory["weared"]["weapon"]]["props"]["phisat"][1]
  v["vPdm2"] = v["vPdm2"] + gid[inventory["weared"]["weapon"]]["props"]["phisat"][2]
  end
  if gid[inventory["weared"]["weapon"]]["props"]["magat"] then
  v["vMdm1"] = v["vMdm1"] + gid[inventory["weared"]["weapon"]]["props"]["magat"][1]
  v["vMdm2"] = v["vMdm2"] + gid[inventory["weared"]["weapon"]]["props"]["magat"][2]
 end
 v.vAtds = gfunc.watds[gid[inventory["weared"]["weapon"]]["subtype"]]
 gsd[1]["reloading"] = weaponHitRate[gid[inventory["weared"]["weapon"]]["subtype"]] or 1
 end
vaddsPnts.vSur, vaddsPnts.vStr, vaddsPnts.vInt, vaddsPnts.vPdm1, vaddsPnts.vMdm1, vaddsPnts.vPdm2, vaddsPnts.vMdm2 = v["sur+"], v["str+"], v["int+"], v["vPdm2"], v["vMdm1"], v["vPdm2"], v["vMdm2"]
CGD[1]["mhp"] = math.ceil(((45+(survivability+v["sur+"])*15+(CGD[1]["lvl"]-1)*28+v["hp+"]))*(1+v["hp%"]/100))
mmp = math.ceil(((28+(intelligence+v["int+"])*6+(CGD[1]["lvl"]-1)*7+v["mp+"]))*(1+v["mp%"]/100))
local reqxp = 0
 for e = 1, CGD[1]["lvl"] do
  if e <= 15 then
  reqxp = math.floor(reqxp + reqxp*(2/e) + 50*e^(1/e))
  elseif e > 15 and e < 30 then
  reqxp = math.floor(reqxp + reqxp*(3/e) + 52*e^(1/e))
  elseif e >= 30 then
  reqxp = math.floor(reqxp + reqxp*(4/e) + 54*e^(1/e))
  end
 end
mxp = reqxp
CGD[1]["ptk"] = {
math.floor(1+(1+4*(strength+v["str+"])/100)*(CGD[1]["lvl"]+v["vPdm1"])),
math.ceil(1+(1+4*(strength+v["str+"])/100)*(CGD[1]["lvl"]+v["vPdm2"]))
}
CGD[1]["mtk"] = {
math.floor(1+(1+4*(intelligence+v["int+"])/100)*(CGD[1]["lvl"]+v["vMdm1"])),
math.ceil(1+(1+4*(intelligence+v["int+"])/100)*(CGD[1]["lvl"]+v["vMdm2"]))
}
CGD[1]["pdef"] = math.floor(15+((survivability+v["sur+"])/2+(strength+v["str+"])/4)*(CGD[1]["lvl"]+v["pdf+"]/2))
CGD[1]["armorpdef"] = v["pdf+"]
CGD[1]["mdef"] = math.floor(15+((survivability+v["sur+"])/2+(intelligence+v["int+"])/4)*(CGD[1]["lvl"]+v["mdf+"]/2))
CGD[1]["armormdef"] = v["mdf+"]
CGD[1]["cmove"] = true
CGD[1]["ctck"] = true
CGD[1]["criticalhc"] = v["chc+"] + CritChan
vAttackDistance = v.vAtds
for f = 0, 600 do if gid[200+f] then mItemDataNum = mItemDataNum + 1 end end
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
end

local function addXP(value)
 if mxp-cxp >= value then
 cxp = cxp + value
 else
 value = value - (mxp - cxp)
 charPoints = charPoints + 1
 CGD[1]["lvl"] = CGD[1]["lvl"] + 1
 gfunc.playerRefreshVar()
 cxp = value
 CGD[1]["chp"] = CGD[1]["mhp"]
 cmp = mmp
 end
 if cWindowTrd == nil and value ~= nil and value > 0 then
 addsmsg4(lang("Опыт").."+"..value)
 end
end

local function addCoins(value)
cCoins = cCoins + value
 if cWindowTrd == nil and value ~= nil and value > 0 then
 addsmsg4(lang("Монеты").." "..cCoins.."+"..value)
 end
end

local function getQuest(quest)
table.insert(cUquests,{quest,0,false})
 if type(gqd[quest]["targ"]) == "table" then
 cUquests[#cUquests][2] = {}
  for f = 1, #gqd[quest]["targ"] do
  cUquests[#cUquests][2][f] = 0
  end
 end
end

addUnit(1,1,1)

local function dmLoading()
buffer.square(1,1,160,50,startBckgColour,0x000000," ")
buffer.text(2,2,0xA7A7A7,cScreenStat)
buffer.text(2,4,0xA7A7A7,world[world.current].name)
buffer.text(158-unicode.len(TextVersion),48,0xA1A1A1,TextVersion)
buffer.text(158-unicode.len(pScreenText),49,0xB1B1B1,pScreenText)
 for f = 1, #dopInfo do
 buffer.text(2,48-#dopInfo+f,0xA7A7A7,dopInfo[f])
 end
 if not vseNormalno then
 buffer.text(2,math.floor(mxh/2),0xD80000,"Предупреждение:"..preduprejdenie)
 buffer.text(2,math.floor(mxh/2)+1,0xD80000,"Продолжить загрузку? Y/N")
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

local function loadWorld(id)
stopDrawing = true
paused = true
cWindowTrd = nil
cTarget = 0
cDialog = nil
paused = false
world.current = id
dmLoading()
consDataR = {"Загрузка уровня id:"..id.." "..world[world.current].name.."..."}
local n = CGD[1]
CGD = {}
CGD[1] = n
CGD[1]["x"], CGD[1]["mx"], cGlobalx, cBackgroundPos = 1, 1, 1, 1
CGD[1]["cmove"] = true
CGD[1]["ctck"] = true
imageBuffer = {[-3]=image.load(dir.."sprpic/player_s1.pic"),[-2]=image.load(dir.."sprpic/player_s2.pic"),[-1]=image.load(dir.."sprpic/player_pck.pic"),[0]=image.load(dir.."sprpic/player.pic")}
local cspawnl = world[id].spawnList
local bufferenv = 0
local spx, npx = 0, 0
local function a(f) imageBuffer[f] = image.duplicate(image.load(dir.."sprpic/"..gud[cspawnl[f][1]]["image"]..".pic")) end
gpu.setForeground(0xAAAAAA)
term.setCursor(5,39)
io.write(string.rep("─",150))
term.setCursor(5,41)
io.write(string.rep("─",150))
gpu.setForeground(0xCCCCCC)
 for f = 1, #cspawnl do
  spx = cspawnl[f][2]
  if f > 1 and #cspawnl[f-1] ~= nil and cspawnl[f-1][4] == "p" then
  npx = npx + 45
  spx = npx
  elseif f > 1 and cspawnl[f-1][4] ~= nil and cspawnl[f-1][6] == "p" then
  npx = npx + cspawnl[f-1][4] * cspawnl[f-1][5] - cspawnl[f-1][5]
  spx = npx
  end
  if gud[cspawnl[f][1]]["nres"] ~= false then
   if cspawnl[f][4] == nil then
   addUnit(cspawnl[f][1],spx,cspawnl[f][3])
   a(f)
   CGD[#CGD]["image"] = f
   else
   a(f)
    for i = 1, cspawnl[f][4] do
    addUnit(cspawnl[f][1],spx+i*cspawnl[f][5]-cspawnl[f][5],cspawnl[f][3])
    CGD[#CGD]["image"] = f
    os.sleep()
    end 
   end
  end
 term.setCursor(5,40) 
  for n = 1,math.floor(f*150/#cspawnl) do
  io.write("█")
  end
 end
paused = false
stopDrawing = false
addsmsg2(world[id].name)
end

local function teleport(x,tworld)
 if tworld and tworld ~= world[world.current] then
 loadWorld(tworld)
 end
local x = x or 1
cGlobalx, cBackgroundPos, CGD[1]["x"], CGD[1]["mx"] = x, x, x, x
end

local function saveGame(savePath,filename)
 if not fs.exists(savePath) then
 fs.makeDirectory(savePath)
 end
local gd = {}
 for f = 1, mItemDataNum - 199 or 0 do
 if gid[199+f] then gd[f] = gid[199+f] end
 end
CGD[1]["chp"] = math.floor(CGD[1]["chp"])
local f = io.open(savePath.."/"..filename, "w")
f:write(os.date(),"\n") -- дата изм
f:write(ser.serialize(CGD[1]),"\n") -- игрок
f:write(ser.serialize(inventory),"\n") -- инвентарь
f:write(ser.serialize({world.current, math.floor(cmp), mmp, math.floor(cxp), mxp, cCoins, charPoints, survivability, strength, intelligence}),"\n") -- переменные
f:write(ser.serialize(cPlayerSkills),"\n")
f:write(ser.serialize(cUskills),"\n")
f:write(ser.serialize(gd),"\n") -- предметы из gid
f:write(ser.serialize(cUquests),"\n") -- задания
gd = {}
 for i = 1, #gqd do
  if gqd[i]["comp"] == true then
  table.insert(gd,i)
  end
 end
f:write(ser.serialize(gd),"\n") -- выполненные/заблокированные задания
gd = {}
 for i = 1, #CGD do
 gd[i] = {CGD[i]["living"],CGD[i]["resptime"]} 
 end
f:write(ser.serialize(gd),"\n") -- чек побитых монстров
gd = {}
 for i = 1, #gud do
 if gud[i]["nres"] == false then gd[i] = i end
 end
f:write(ser.serialize(gd)) -- чек нересп. монстров
f:close()
end

local function loadGame(savePath,filename)
 if fs.exists(savePath.."/"..filename) then
 lostItem = nil
 local tkt = 0
 while true do
  if gid[200 + tkt] then gid[200 + tkt] = nil end
  tkt = tkt + 1
  if tkt >= 600 then break end
 end
 paused = true
 stopDrawing = true
 local tbl = readFromFile(savePath.."/"..filename)
 local yv = ser.unserialize(tbl[4])
 world.current = yv[1]
 cmp = yv[2]
 mmp = yv[3]
 cxp = yv[4]
 mxp = yv[5]
 cCoins = yv[6]
 charPoints = yv[7]
 survivability = yv[8]
 strength = yv[9]
 intelligence = yv[10]
 CGD[1] = ser.unserialize(tbl[2])
 CGD[1]["image"] = 0
 local buben = CGD[1]["x"]
 inventory = ser.unserialize(tbl[3])
 cPlayerSkills = ser.unserialize(tbl[5])
 cUskills = ser.unserialize(tbl[6])
 yv = ser.unserialize(tbl[7])
  for f = 1, #yv do
  gid[yv[f]["id"]] = yv[f]
   if gid[#gid]["oid"] then
   gid[#gid]["name"] = lang(gid[gid[#gid]["oid"]]["name"])
   if gid[#gid]["props"] and type(gid[#gid]["props"]) == "table" and gid[#gid]["props"]["dds"] then for o = 1, #gid[#gid]["props"]["dds"] do gid[#gid]["name"] = "♦"..gid[#gid]["name"] end end
   mItemDataNum = math.max(199 + f,200)
   end
  end
 cUquests = ser.unserialize(tbl[8])
  for b = 1, #cUquests do
  gqd[cUquests[b][1]]["comp"] = false
  end
 yv = ser.unserialize(tbl[9])
  for f = 1, #yv do
  gqd[yv[f]]["comp"] = true
  end
 loadWorld(world.current)
 yv = ser.unserialize(tbl[10])
  for f = 1, #yv do
   if CGD[f] then
   CGD[f]["living"], CGD[f]["resptime"] = yv[f][1], yv[f][2]
   if yv[f][3] then gud[CGD[f]["id"]]["nres"] = false end
   end
  end
 yv = ser.unserialize(tbl[11])
  for f = 1, #yv do
  gud[yv[f]]["nres"] = false
  end
 teleport(buben)
 end
tbl = nil
end

local function pbar(x,y,size,percent,color1,color2, text, textcolor)
percent = 100 - percent
local fill = {}
 for f = 1, size do
 table.insert(fill,1)
 end
 for f = 1, size do
  if 100/size*f <= percent then 
  fill[size-f+1] = 0
  end
 end
local color0 = 0x000000
 for f = 1, size do
  if fill[f] == 1 then color0 = color1
  else color0 = color2
  end
 buffer.set(x+f-1,y,color0, 0xFFFFFF, " ") 
 buffer.text(x, y, textcolor, text)
 end
end

function gfunc.check_npc_dq(id)
local sdq = false
 if id > 0 and gud[id]["quests"] then
  for f = 1, #gud[id]["quests"] do
   if gqd[gud[id]["quests"][f]] and gqd[gud[id]["quests"][f]]["comp"] == 0 and CGD[1]["lvl"] >= gqd[gud[id]["quests"][f]]["minlvl"] then
   sdq = true
   break
   end
  end
 end
return sdq
end

function gfunc.check_npc_cq(id)
local scq = false
 if id > 0 then
  for f = 1, #cUquests do
   if gqd[cUquests[f][1]]["qr"] == id and cUquests[f][3] == true then
   scq = true
   break
   end
  end
 end
return scq
end

local function drawCDataUnit()
local ccl, cx, cy
local subtextninfo
 for f = 2, #CGD do
  cx, cy = math.floor(CGD[f]["x"]), math.floor(CGD[f]["y"])
  if CGD[f]["living"] and getDistanceToId(1,f) <= 75 then  
   if CGD[f]["image"] ~= nil and CGD[f]["spos"] == "r" then
   buffer.image(cx+75-cGlobalx,49-cy-CGD[f]["height"], imageBuffer[CGD[f]["image"]])
   elseif CGD[f]["image"] ~= nil and CGD[f]["spos"] == "l" then
   buffer.image(cx+75-cGlobalx,49-cy-CGD[f]["height"], image.flipHorizontal(image.duplicate(imageBuffer[CGD[f]["image"]])))
   else buffer.text(cx+75-cGlobalx,49-cy-CGD[f]["height"],0xcc2222,"ERROR")
   end
 
   if ( CGD[f]["rtype"] == "e" or CGD[f]["rtype"] == "p" or CGD[f]["rtype"] == "m" ) and cTarget == f then
   pbar(cx+75-cGlobalx+math.floor((CGD[f]["width"]/2-8/2)), 49-cy-2-CGD[f]["height"],8,math.ceil(CGD[f]["chp"])*100/CGD[f]["mhp"],0xFF0000,0x444444," ",0xFFFFFF)
   buffer.text(math.floor(cx+75-cGlobalx+(CGD[f]["width"]/2-8/2)+(math.floor((8 / 2) - (unicode.len(tostring(math.ceil(CGD[f]["chp"]))) / 2)))),49-cy-2-CGD[f]["height"],0xFFFFFF,tostring(math.ceil(CGD[f]["chp"])))
   local btname = gud[CGD[cTarget]["id"]]["name"]
   if unicode.len(tostring(btname)) >= 24 then btname = unicode.sub(btname,1,24).."…" end
   buffer.text(math.floor(cx+75-cGlobalx+(CGD[f]["width"]/2-24/2)+(math.floor((24 / 2) - (unicode.len(btname) / 2)))),49-cy-3-CGD[f]["height"],0xFFFFFF,btname)
   elseif pickingUp and cTarget ~= 0 and pckTarget == f and CGD[f]["rtype"] == "r" then
   local vpercentr = math.ceil((maxPckTime-pckTime)*100/maxPckTime)
   pbar(cx+75-cGlobalx+math.floor((CGD[f]["width"]/2-8/2)),49-cy-CGD[f]["height"]-2,8,vpercentr,0x009945,0x444444,vpercentr.."% ",0xFFFFFF)
   
   elseif CGD[f]["rtype"] == "f" then
    if gfunc.check_npc_cq(CGD[f]["id"]) == true then
	ccl = 0x009922
	elseif gfunc.check_npc_dq(CGD[f]["id"]) == true then
	ccl = 0xDCBC12
	end
    if ccl then
	buffer.text(cx+75-cGlobalx+math.floor((CGD[f]["width"]/2))-2,49-cy-CGD[f]["height"]-3,ccl,"▔██▔")
    buffer.text(cx+75-cGlobalx+math.floor((CGD[f]["width"]/2))-1,49-cy-CGD[f]["height"]-2,ccl,"◤◥")   
    ccl = nil
	end
   end
  end
  if getDistanceToId(1,f) <= 75 then
  subtextninfo = ""
   for m = 1, 2 do
    if CGD[f]["tlinfo"][m] then
    subtextninfo = CGD[f]["tlinfo"][m]
    if unicode.len(tostring(CGD[f]["tlinfo"][m])) >= 24 then subtextninfo = unicode.sub(CGD[f]["tlinfo"][m][1],1,24).."…" end
    buffer.text(math.floor(cx+75-cGlobalx+(CGD[f]["width"]/2-24/2)+(math.floor((24 / 2) - (unicode.len(subtextninfo) / 2)))),49-CGD[f]["y"]-3-m-CGD[f]["height"],0xFFFFFF,subtextninfo)
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
  if clicked(x, y, math.floor(CGD[f]["x"])+75-cGlobalx, 49-math.floor(CGD[f]["y"])-2-CGD[f]["height"], math.floor(CGD[f]["x"])+75-cGlobalx+CGD[f]["width"], 49-math.floor(CGD[f]["y"])) then
   if CGD[f]["living"] then 
   cTarget = f 
   console.debug("Выбрать цель","id:",tostring(cTarget),gud[CGD[cTarget]["id"]]["name"])
   end
  end
 end
end

local fPauselist = {
"Продолжить игру",
"Инвентарь",
"Умения персонажа",
"Характеристика",
"Текущие задания",
"Сохранить",
"Загрузить",
"Выйти из игры"
}

function gfunc.fPause()
buffer.square(1, 1, 30, 50, 0x9D9D9D, nil, nil, 20)
buffer.text(13,2,0xFFFFFF,"Пауза")
 for f = 1, #fPauselist do
 buffer.square(1, 1+f*4, 30, 3, 0x838383, nil, nil, 20)
 buffer.set(1,3+f*4,0x959595,0x000000," ")
 buffer.text(math.max(math.floor((30/2)-(unicode.len(fPauselist[f])/2)),0),2+f*4,0xFFFFFF,fPauselist[f])
 end
end

local svxpbar = false

local vshowEffDescr, sEffdx, sEffdy = 0, 1, 1

local function playerCInfoBar(x,y)
local isTrue = false
buffer.square(x, y, 25, 5, 0x8C8C8C, 0xFFFFFF, " ")
local fxpdt = tostring(cxp).."/"..tostring(mxp)
local percent1 = math.floor(CGD[1]["chp"]*100/CGD[1]["mhp"])
local percent2 = math.floor(cmp*100/mmp)
local percent3 = math.floor(cxp*100/mxp*10)/10
buffer.text(x+1, y, 0xFFFFFF, "Уровень "..CGD[1]["lvl"])
local tpbar1 = math.floor(CGD[1]["chp"]).."/"..math.floor(CGD[1]["mhp"])
local tpbar2 = math.floor(cmp).."/"..math.floor(mmp)
local tpbar3 = percent3.."% "
if percent3 == 0 then tpbar3 = percent3..".0% " end
pbar(x,y+1,25,percent1,0xFF0000,0x5B5B5B," ", 0xFFFFFF)
buffer.text(math.max(math.floor((25/2)-(#tpbar1/2)),0),y+1,0xFFFFFF,tpbar1)
pbar(x,y+2,25,percent2,0x0000FF,0x5B5B5B," ", 0xFFFFFF)
buffer.text(math.max(math.floor((25/2)-(#tpbar2/2)),0),y+2,0xFFFFFF,tpbar2)
pbar(x,y+3,25,percent3,0xFFFF00,0x5B5B5B," ", 0x333333)
buffer.text(math.max(math.floor((25/2)-(#tpbar3/2)),0),y+3,0x333333,tpbar3)
if svxpbar then buffer.text(x+25-#fxpdt, y+3, 0x4F4F4F, fxpdt) end
 for f = 1, #CGD[1]["effects"] do
  for h = 1, 2 do
   for w = 1, 3 do
   buffer.square(x+f*4-4+w,y+5+h,1,1,ged[CGD[1]["effects"][f][1]]["i"][2*(3*(h-1)+w)-1],0xFFFFFF,ged[CGD[1]["effects"][f][1]]["i"][2*(3*(h-1)+w)])
   end
  end
 end
 if vshowEffDescr ~= 0 and CGD[1]["effects"][vshowEffDescr]then
  buffer.square(sEffdx,sEffdy,math.max(unicode.len(ged[CGD[1]["effects"][vshowEffDescr][1]]["name"]),unicode.len(ged[CGD[1]["effects"][vshowEffDescr][1]]["descr"])),2,0xA1A1A1,0xFFFFFF," ")
  buffer.text(sEffdx,sEffdy,0xEDEDED,ged[CGD[1]["effects"][vshowEffDescr][1]]["name"])
  buffer.text(sEffdx,sEffdy+1,0xCECECE,ged[CGD[1]["effects"][vshowEffDescr][1]]["descr"])
 end
end

function gfunc.unicodeframe(x,y,w,h,c)
buffer.text(x,y,c,"┌")
 for t = 1, w-2 do
 buffer.text(x+t,y,c,"─")
 end
buffer.text(x+w-1,y,c,"┐")
 for f = 1, h-2 do
 buffer.text(x,y+f,c,"│")
 buffer.text(x+w-1,y+f,c,"│")
 end
buffer.text(x,y+h-1,c,"└")
 for t = 1, w-2 do
 buffer.text(x+t,y+h-1,c,"─")
 end
buffer.text(x+w-1,y+h-1,c,"┘")
end

local function sTargetInfo(x,y)
local cwtype = ""
if type(gud[CGD[cTarget]["id"]]["wtype"]) == "number" then
cwtype = baseWtype[gud[CGD[cTarget]["id"]]["wtype"]]
else
cwtype = gud[CGD[cTarget]["id"]]["wtype"]
end
local sTInfoArray1 = {
	unicode.sub(gud[CGD[cTarget]["id"]]["name"],1,23),
	"Тип: "..unicode.sub(tostring(cwtype),1,18),
	"Респ: "..tostring(gud[CGD[cTarget]["id"]]["vresp"]).." секунд",
	"ID: "..tostring(CGD[cTarget]["id"]),
}
local sTInfoArray2 = {
	"Физ.атака: "..CGD[cTarget]["ptk"][1].."-"..CGD[cTarget]["ptk"][2],
	"Маг.атака: "..CGD[cTarget]["mtk"][1].."-"..CGD[cTarget]["mtk"][2],
	"Физ.защита: "..tostring(CGD[cTarget]["pdef"].." ("..tostring(math.floor(100*(CGD[cTarget]["pdef"]/(CGD[cTarget]["pdef"]+CGD[1]["lvl"]*30)))).."%)"),
	"Маг.защита: "..tostring(CGD[cTarget]["mdef"].." ("..tostring(math.floor(100*(CGD[cTarget]["mdef"]/(CGD[cTarget]["mdef"]+CGD[1]["lvl"]*30)))).."%)"),
}
buffer.square(x, y, 25, 9, 0xABABAB, 0xFFFFFF, " ")
 for f = 1, #sTInfoArray1 do
 buffer.text(x+1,y+f-1,0xFFFFFF,tostring(sTInfoArray1[f]))
 end
 if CGD[cTarget]["rtype"] ~= "f" and CGD[cTarget]["rtype"] ~= "c" then
  for f = 1, #sTInfoArray2 do
  buffer.text(x+1,y+f-1+#sTInfoArray1,0xFFFFFF,tostring(sTInfoArray2[f]))
  end
 end
end

local function targetCInfoBar(x,y)
local bl = false
buffer.square(x, y, 35, 4, 0x9B9B9B)
if CGD[cTarget]["rtype"] == "e" or CGD[cTarget]["rtype"] == "p" or CGD[cTarget]["rtype"] == "m" then
local chp, mhp = CGD[cTarget]["chp"], CGD[cTarget]["mhp"] 
local namecolor, clvl, plvl = 0xFFFFFF, CGD[cTarget]["lvl"], CGD[1]["lvl"]
 if clvl >= plvl+2 and clvl <= plvl+4 then namecolor = 0xFFDB80
 elseif clvl >= plvl+5 and clvl <= plvl+7 then namecolor = 0xFF9200
 elseif clvl >= plvl+8 then namecolor = 0xFF1000
 elseif clvl <= plvl-2 and clvl >= plvl-5 then  namecolor = 0xBEBEBE
 elseif clvl <= plvl-6 then  namecolor = 0x00823A
 end
local pbtext, lbtext = gud[CGD[cTarget]["id"]]["name"], tostring(CGD[cTarget]["lvl"]).." уровень"
local percent = math.ceil(chp*100/mhp)
--pbar(x,y,35,percent,0xFF0000,0x5B5B5B," ", 0xFFFFFF)
gfunc.unicodeframe(x,y,35,3,0xA2A2A2)
pbar(x,y+1,35,percent,0xFF0000,0x5B5B5B," ", 0xFFFFFF)
buffer.text(x + (math.max(math.floor((35 / 2) - (unicode.len(lbtext) / 2)), 0)), y+1, 0xFFFFFF, lbtext)
buffer.text(x + (math.max(math.floor((35 / 2) - (unicode.len(pbtext) / 2)), 0)),y+2,namecolor,pbtext)
bl = true
elseif CGD[cTarget]["rtype"] == "f" then
local pntext, lbtext = gud[CGD[cTarget]["id"]]["wtype"], gud[CGD[cTarget]["id"]]["name"]
buffer.text(x,y,0x727272,"НИП")
buffer.text(x + (math.max(math.floor((35 / 2) - (unicode.len(lbtext) / 2)), 0)), y+1, 0xFFFFFF, lbtext)
buffer.text(x + (math.max(math.floor((35 / 2) - (unicode.len(pntext) / 2)), 0)), y+2, 0xC8C8C8, pntext)
bl = true
elseif CGD[cTarget]["rtype"] == "r" then
buffer.text(x,y,0x727272,"Ресурс")
local pntext = lang("Нажмите 'E' чтобы собрать")
buffer.text(x + (math.max(math.floor((35 / 2) - (unicode.len(gud[CGD[cTarget]["id"]]["name"]) / 2)), 0)), y+1, 0xFFFFFF, gud[CGD[cTarget]["id"]]["name"])
buffer.text(x + (math.max(math.floor((35 / 2) - (unicode.len(pntext) / 2)), 0)), y+2, 0x727272, pntext)
bl = false
elseif CGD[cTarget]["rtype"] == "c" then
local pntext = lang("Нажмите 'E' чтобы использовать")
buffer.text(x + (math.max(math.floor((35 / 2) - (unicode.len(gud[CGD[cTarget]["id"]]["name"]) / 2)), 0)), y+1, 0xFFFFFF, gud[CGD[cTarget]["id"]]["name"])
buffer.text(x + (math.max(math.floor((35 / 2) - (unicode.len(pntext) / 2)), 0)), y+2, 0x727272, pntext)
bl = false
end
if bl then buffer.text(x+1,y+3,0xFFFFFF,"О персонаже") end
 for f = 1, #CGD[cTarget]["effects"] do
  for h = 1, 2 do
   for w = 1, 3 do
   buffer.square(x+f*4-4+w,y+4+h,1,1,ged[CGD[cTarget]["effects"][f][1]]["i"][2*(3*(h-1)+w)-1],0xFFFFFF,ged[CGD[cTarget]["effects"][f][1]]["i"][2*(3*(h-1)+w)])
   end
  end
 end
 if showTargetInfo then
 sTargetInfo(x+1,y+4)
 end
end

local vtskillUsingMsg, skillUsingMsg = 0, {}

gfunc.sarray = {
{c = 0x614251, t = "/2"},
{c = 0x0000FF, t = "*3"},
{c = 0x008500, t = "@4"},
{c = 0x8600A0, t = "&5"},
{c = 0xEE0000, t = "!6"},
}

local function fSkillBar(x,y)
buffer.square(x, y, 30, 5, 0x9B9B9B, 0xFFFFFF, " ")
 for f = 1, #gfunc.sarray do
 buffer.square(x+4+(f*5-5), y+1, 2, 1, gfunc.sarray[f].c, 0xFFFFFF, " ")
 buffer.text(x+4+(f*5-5), y+1, 0xFFFFFF, gfunc.sarray[f].t)
  if cUskills[f+1] > 0 then
  buffer.text(x+4+(f*5-5), y+2, 0xFFFFFF, tostring(math.ceil(cPlayerSkills[cUskills[f+1]][2]/10)))
  end
 end
if vtskillUsingMsg > 0 then buffer.text(x+1,y+4,0xC1C1C1,skillUsingMsg[#skillUsingMsg]) end
end

local spdialogs = {
[1]={
	["text"]=string.rep("Лайк и репост в студию. ",5),
	{["text"]="Продолжить1",["action"]="close"},
	{["text"]="Продолжить2",["action"]="close"},
	{["text"]="Продолжить3",["action"]="close"}
	}
}

local spDialog = {w=160,h=12,current=1,trg=1}

function gfunc.specialDialog()
local x, y = math.floor(1+160/2-spDialog.w/2), 1+50-spDialog.h
buffer.square(x, y, spDialog.w, spDialog.h, 0x5E5E5E, nil, nil, 15)
buffer.square(x, y, spDialog.w, 1, 0x5E5E5E)
local num_h = math.ceil(unicode.len(spdialogs[spDialog.current]["text"])/(spDialog.w/2))
local text_y = 50-math.floor(spDialog.h/2-num_h/2)
local ctext 
 for f = 1, num_h do
 ctext = unicode.sub(spdialogs[spDialog.current]["text"],spDialog.w/2*f-spDialog.w/2,spDialog.w/2*f)
 buffer.text(1+math.floor(spDialog.w/2-unicode.len(ctext)/2), text_y+f-4, 0xEDEDED, ctext)
 end
 for f = 1, #spdialogs[spDialog.current] do
 ctext = spdialogs[spDialog.current][f]["text"]
 if spDialog.trg == f then buffer.square(x, text_y+f, spDialog.w, 1, 0x989898, nil, nil, 40) end
 buffer.text(1+math.floor(spDialog.w/2-unicode.len(ctext)/2),text_y+f, 0xEDEDED, ctext)
 end
end

function gfunc.drawDialog(x,y)
local sColor
local isQnComp, isQcomp = false, false
insertQuests(cTarget,cDialog)
 for f = 1, #cDialog do
  if not cDialog[f] then
  table.remove(cDialog,f)
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
    if isQnComp or gqd[cDialog[#cDialog-f+1]["q"]]["minlvl"] > CGD[1]["lvl"] or gqd[cDialog[#cDialog-f+1]["q"]]["comp"] == true then
    table.remove(cDialog,#cDialog-f+1)
    end
   elseif cDialog[#cDialog-f+1]["action"] == "setWorld" and CGD[1]["lvl"] < cDialog[#cDialog-f+1]["reqlvl"] then
   cDialog[#cDialog-f+1]["text"] = unicode.sub(cDialog[#cDialog-f+1]["text"],1,unicode.len(cDialog[#cDialog-f+1]["text"])-#tostring(cDialog[#cDialog-f+1]["reqlvl"])-2)
   cDialog[#cDialog-f+1]["text"] = cDialog[#cDialog-f+1]["text"].." "..cDialog[#cDialog-f+1]["reqlvl"].."+"
   end
  end
 end
buffer.square(x, y, 50, 24, 0x9B9B9B, 0xFFFFFF, " ")
buffer.square(x, y, 50, 1, 0x606060, 0xFFFFFF, " ")
buffer.square(x+1, y+1, 48, 12, 0x7A7A7A, 0xFFFFFF, " ")
buffer.square(x+1, y+14, 48, 9, 0x7A7A7A, 0xFFFFFF, " ")
buffer.text(x+49,y,0xFFFFFF,"X")
local text1 = gud[CGD[cTarget]["id"]]["name"]
buffer.text(x+(math.max(math.floor((50 / 2) - (unicode.len(text1) / 2)), 0)), y, 0xFFFFFF, text1) 
 for f = 1, math.ceil(#cDialog["text"]/46) do
 buffer.text(x+2,y+1+f,0xFFFFFF,unicode.sub(cDialog["text"],1+f*46-46,f*46))
 end
 for f = 1, #cDialog do
 sColor = 0xFFFFFF
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

function gfunc.itemSubtypeToRus(subtype)
local massiv = {
["helmet"] = "Шлем",
["bodywear"] = "Броня",
["pants"] = "Штаны",
["footwear"] = "Сапоги",
["pendant"] = "Кулон",
["robe"] = "Накидка",
["ring"] = "Кольцо",
["sword"] = "Меч",
["spear"] = "Копье",
["axe"] = "Короткая секира",
}
return massiv[subtype]
end

local invTItem = 0
local invcTItem, invcTargetItem, showItemData = 0, 0, false
local invIdx, invIdy = 1, 1

function gfunc.getItemInfo(id)
local info = {}
local function giiwcAdd(t,c) table.insert(info,{tostring(t),c}) end
local itemtype, itemsubtype = gid[id]["type"], gid[id]["subtype"] 
giiwcAdd(gid[id]["name"], gid[id]["ncolor"])
 if itemtype == "armor" or itemtype == "weapon" then
 giiwcAdd(lang(gfunc.itemSubtypeToRus(itemsubtype)), 0xBCBCBC)
 giiwcAdd(lang("Уровень").." "..tostring(gid[id]["lvl"]), 0xFFFFFF)
 end
 if itemtype == "weapon" then
 giiwcAdd(lang("Скорость атаки:").." "..tostring(math.ceil((1/weaponHitRate[gid[id]["subtype"]])*10)/10).." уд./сек.", 0xEFEFEF)
 giiwcAdd(lang("Дальность атаки:").." "..gfunc.watds[gid[id]["subtype"]], 0xEFEFEF)
 end
 if itemtype == "item" and itemsubtype == "res" then
 giiwcAdd(lang("Уровень материала").." "..tostring(gid[id]["lvl"]), 0xFFFFFF)
 end
 if itemtype == "armor" then
 if gid[id]["props"]["pdef"] ~= 0 then giiwcAdd(lang("Защита").." +"..tostring(gid[id]["props"]["pdef"]), 0xEFEFEF) end
 if gid[id]["props"]["mdef"] ~= 0 then giiwcAdd(lang("Магическая защита").." +"..tostring(gid[id]["props"]["mdef"]), 0xEFEFEF) end
 elseif itemtype == "weapon" then
 if gid[id]["props"]["phisat"] and gid[id]["props"]["phisat"] ~= 0 then giiwcAdd(lang("Физическая атака ")..gid[id]["props"]["phisat"][1].."-"..gid[id]["props"]["phisat"][2], 0xFFFFFF) end
 if gid[id]["props"]["magat"] and gid[id]["props"]["magat"] ~= 0 then giiwcAdd(lang("Магическая атака ")..gid[id]["props"]["magat"][1].."-"..gid[id]["props"]["magat"][2], 0xFFFFFF) end
 end
 if itemtype == "armor" or itemtype == "weapon" or itemtype == "potion" then
  if gid[id]["subtype"] == "health" then
  giiwcAdd("Восстановить "..tostring(ged[1]["val"][gid[id]["lvl"]]).." ед. здоровья за 10 секунд", 0xEFEFEF)
  elseif gid[id]["subtype"] == "mana" then
  giiwcAdd("Восстановить "..tostring(ged[2]["val"][gid[id]["lvl"]]).." ед. маны за 10 секунд", 0xEFEFEF)
  end
  if gid[id]["reqlvl"] > CGD[1]["lvl"] then
  giiwcAdd(lang("Требуемый уровень:").." "..gid[id]["reqlvl"], 0xFF0000)
  else
  giiwcAdd(lang("Требуемый уровень:").." "..gid[id]["reqlvl"], 0xFFFFFF)
  end
if itemtype == "armor" or itemtype == "weapon" then
local spisok1 = {
	["hp+"] = {"Здоровье"},
	["mp+"] = {"Мана"},
	["sur+"] = {"Выживаемость"},
	["str+"] = {"Сила"},
	["int+"] = {"Интеллект"},
	["pdm+"] = {"Физическая атака"},
	["mdm+"] = {"Магическая атака"},
	["pdf+"] = {"Физическая защита"},
	["mdf+"] = {"Магическая защита"},	
	["chc+"] = {"Вероятность нанесения критического удара","%"},
	["hp%"] = {"Максимальное здоровье","%"},
	["mp%"] = {"Максимальная мана","%"},
}
local banan
 if gid[id]["props"]["dds"] ~= nil then
  for e = 1, #gid[id]["props"]["dds"] do
  banan = ""
   if gid[id]["props"]["dds"][e] and gid[id]["props"]["dds"][e][2] > 0 then
   if #spisok1[gid[id]["props"]["dds"][e][1]] >= 2 then banan = spisok1[gid[id]["props"]["dds"][e][1]][2] end
   giiwcAdd(lang(spisok1[gid[id]["props"]["dds"][e][1]][1]).." + "..gid[id]["props"]["dds"][e][2]..banan,0x0044ee)
   end
  end
 end
end
 end
 if gid[id]["description"] ~= "" then
  for f = 1, math.ceil(unicode.len(gid[id]["description"])/35) do
  giiwcAdd(unicode.sub(gid[id]["description"],1+f*35-35,f*35), 0xBCBCBC)
  end
 end
local v = ""
if invTItem > 1 then v = " ("..tostring(gid[id]["cost"]*invTItem)..")" end
giiwcAdd(lang("Цена").." "..tostring(gid[id]["cost"])..v, 0xFFFFFF)
return info
end

local wItemTypes = {
	"helmet",
	"pendant",
	"bodywear",
	"robe",
	"pants",
	"weapon",
	"footwear",
	"ring",
}

function gfunc.drawInventory(x,y)
buffer.square(x, y, 160, 50, 0x9B9B9B, 0xFFFFFF, " ")
buffer.square(x, y, 160, 1, 0x525252, 0xFFFFFF, " ")
buffer.square(x, y+49, 160, 1, 0x525252, 0xFFFFFF, " ")
buffer.square(x, y+1, 105, 45, 0x767676, 0xFFFFFF, " ")
buffer.square(x+106, y+1, 43, 45, 0x4A4A4A, 0xFFFFFF, " ")
 for f = 1, 5 do
 buffer.square(x, y+1+(f*11-11), 105, 1, 0x4A4A4A, 0xFFFFFF, " ")
 end
  for f = 1, 6 do
 buffer.square(x+(f*21-21), y+1, 1, 45, 0x4A4A4A, 0xFFFFFF, " ")
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
buffer.text(x+1,y,0xC4C4C4,"Монеты:".." "..tostring(cCoins))
buffer.text(x+75,y,0xFFFFFF,"Инвентарь")
buffer.text(x+152,y,0xFFFFFF,"Закрыть") 
local formula, xps, yps
 for f = 1, 4 do
  for i = 1, 5 do
  xps, yps = x+1+i*21-21, y+2+f*11-11
  formula = (f-1)*5+i
   if inventory["bag"][formula][1] ~= 0 and inventory["bag"][formula][2] ~= 0 then    
    if iconImageBuffer[formula] then
	 if gid[inventory["bag"][formula][1]] then
	 buffer.image(xps, yps, iconImageBuffer[formula])
	  if inventory["bag"][formula][2] > 1 then
      buffer.square(xps, yps+9, #tostring(inventory["bag"][formula][2]), 1, 0x4A4A4A, 0xFFFFFF, " ")
	  buffer.text(xps,yps+9,0xFFFFFF,tostring(inventory["bag"][formula][2]))
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
 for f = 1, 4 do
  for i = 1, 2 do
   formula, xps, yps = (f-1)*2+i, 107+i*21-21, 3+f*11-11
   if inventory["weared"][wItemTypes[formula]] ~= 0 then
    if iconImageBuffer[wItemTypes[formula]] then
	 if gid[inventory["weared"][wItemTypes[formula]]] then
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
formula = nil
buffer.text(2,48,0x444444,sMSG3)
local textRemoveItem = "Выбросить предмет(ы)"
 if showItemData and invcTItem ~= 0 then
 buffer.square(x+1,y+46,unicode.len(textRemoveItem),1,0x3c539e, 0xFFFFFF," ")
 buffer.text(x+1,y+46,0xFEFEFE,textRemoveItem)
 local itemInfo
  if gid[invcTItem] then
  itemInfo = gfunc.getItemInfo(invcTItem)
  else
  itemInfo = {{"Неправильный ID предмета (id:"..invcTItem.." не существует)",0xFF0000}}
  end
 local hn, w, h = 0, 0, #itemInfo 
  for f = 1, #itemInfo do
  if unicode.len(itemInfo[f][1]) > w then w = unicode.len(itemInfo[f][1]) end
  end
 buffer.square(math.min(invIdx,160-w), math.min(invIdy,50-h), w, h, 0x828282, 0xFFFFFF, " ")
  for f = 1, #itemInfo do
  gfunc.scolorText(math.min(invIdx,160-w),math.min(invIdy+f-1,50-h+f-1),itemInfo[f][2],itemInfo[f][1])
  end

 end
end

function gfunc.changeOconchanie(rstring,number)
local numokn,numpokn,cletter = tonumber(string.sub(tostring(number),#tostring(number),#tostring(number))), tonumber(string.sub(tostring(number),#tostring(number)-1,#tostring(number)-1)), ""
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

function gfunc.showItemDescription(x,y,item)
  local itemInfo = gfunc.getItemInfo(item)
  local hn, w, h = 0, 0, #itemInfo
   for f = 1, #itemInfo do
   if unicode.len(itemInfo[f][1]) > w then w = unicode.len(itemInfo[f][1]) end
   end
  buffer.square(x, y, w, h, 0x828282)
   for f = 1, #itemInfo do
   buffer.text(x,y+f-1,itemInfo[f][2],itemInfo[f][1])
   end
end

local tradew = {
	titem = 0,
	titemcount = 1,
	sect = 1,
	tScrl = 1,
	torg = 1,
	asmt = {},
}

local smw, smh = 50, 15

function gfunc.tradeWindow(x,y)
buffer.square(x, y, 160, 50, 0x9B9B9B)
buffer.square(x, y, 160, 1, 0x525252)
buffer.square(x, y+1, 160, 3, 0x747474)
local hclr
local t = "Торговля"
buffer.text(math.max(80-(unicode.len(t)/2), 0), y, 0xFFFFFF, t)
buffer.text(x+152,y,0xFFFFFF,"Закрыть")
buffer.text(x+1,y,0xFFFFFF,"Монеты "..cCoins)
hclr = {"Перейти к продаже","Перейти к покупке"}
buffer.square(x+118, y+1, unicode.len(hclr[tradew.torg])+2, 3, 0x8a8a8a)
buffer.text(x+119, y+2,0xFFFFFF,hclr[tradew.torg])
 if tradew.torg == 1 then
 buffer.text(x+1,y+3,0xC2C2C2,"Наименование")
 buffer.text(x+65,y+3,0xC2C2C2,"Цена за единицу")
 local massiv = gameTradew[tradew.sect]
 local t1
  for f = 1, #gameTradew do
  t1 = unicode.sub(gameTradew[f]["s_name"],1,25)
  if tradew.sect == f then hclr = 0x525252 else hclr = 0x606060 end
  buffer.square(x+1+f*26-26, y+1, 25, 1, hclr)
  buffer.text(x+1+f*26-26, y+1, 0xCCCCCC, t1)
  end
  for f = 1, math.min(#massiv, 24) do
  if f+4*tradew.tScrl-4 == tradew.titem then buffer.square(x+1,y+4+f*2-2, 160, 3, 0x818181) end
  end
  for f = 1, math.min(#massiv+1, 24) do
   for m = 1, 158 do
   buffer.text(x+1+m,y+4+f*2-2,0xFFFFFF,"─")
   end
  end
  for f = 1, math.min(#massiv, 24) do
  buffer.text(x+1,y+4+f*2-1,0xFFFFFF,gid[massiv[f+4*tradew.tScrl-4]["item"]]["name"])
  buffer.text(x+65,y+4+f*2-1,0xFFFFFF,tostring(massiv[f+4*tradew.tScrl-4]["cost"])..gfunc.changeOconchanie(" монет",massiv[f+4*tradew.tScrl-4]["cost"]))
  end
 local clr, smx, smy, tn = 0xCCCCCC
 tn = "Купить"
  if tradew.titem > 0 then
  smx, smy = math.floor(80-smw/2), math.floor(25-smh/2)
  buffer.square(smx, smy, smw, smh, 0x828282)
  gfunc.unicodeframe(smx, smy, smw, smh, 0x4c4c4c)
  buffer.square(smx-23, smy, 22, 12, 0x828282)
  buffer.image(smx-22, smy+1, iconImageBuffer[1])
  buffer.text(smx+smw-2, smy, 0x4c4c4c, "X")
  buffer.text(smx+(smw/2-unicode.len(gid[massiv[tradew.titem]["item"]]["name"])/2), smy+1, clr, gid[massiv[tradew.titem]["item"]]["name"])
  buffer.text(smx+1,smy+2, clr, "Покупка предмета")
  buffer.text(smx+1,smy+3, clr, "Количество:")
  buffer.square(smx+13, smy+3, #tostring(tradew.titemcount)+4, 1, 0x616161)
  buffer.text(smx+13,smy+3, clr, "+ "..tradew.titemcount.." -")
  buffer.text(smx+1,smy+4, clr, "Цена: "..massiv[tradew.titem]["cost"]..gfunc.changeOconchanie(" монет",massiv[tradew.titem]["cost"]))
  local td
  if tradew.titemcount*massiv[tradew.titem]["cost"] <= cCoins then td = clr else td = 0xb71202 end
  buffer.text(smx+1,smy+5, td, "Стоимость: "..tostring(tradew.titemcount*massiv[tradew.titem]["cost"])..gfunc.changeOconchanie(" монет",tradew.titemcount*massiv[tradew.titem]["cost"]))
  buffer.square(smx, smy+smh, smw, 3, 0x0054cb5)
  buffer.text(smx+(smw/2-unicode.len(tn)/2), smy+smh+1, clr, tn)
  gfunc.showItemDescription(smx+smw+1,smy,massiv[tradew.titem]["item"])
  end
 elseif tradew.torg == 2 then
  buffer.text(x+2,y+3,0xC2C2C2,"#")
  buffer.text(x+5,y+3,0xC2C2C2,"Наименование")
  buffer.text(x+50,y+3,0xC2C2C2,"Количество")
  buffer.text(x+70,y+3,0xC2C2C2,"Цена за единицу")
  tradew.asmt = {}
  for f = 1, #inventory["bag"] do
   if inventory["bag"][f][1] ~= 0 and inventory["bag"][f][2] ~= 0 then
   table.insert(tradew.asmt,inventory["bag"][f])
   end
  end
  for f = 1, 25 do
  buffer.square(x+1,y+5+f*2-2,85,1,0x8C8C8C)
  end
  for f = 1, #tradew.asmt do
  buffer.text(x+2,y+4+f,0xDDDDDD,tostring(f))
  buffer.text(x+5,y+4+f,gid[tradew.asmt[f][1]]["ncolor"],"► "..gid[tradew.asmt[f][1]]["name"])
  buffer.text(x+50,y+4+f,0xDDDDDD,tostring(tradew.asmt[f][2]))
  buffer.text(x+70,y+4+f,0xDDDDDD,gid[tradew.asmt[f][1]]["cost"]..gfunc.changeOconchanie(" монет",gid[tradew.asmt[f][1]]["cost"]))
  end
   if tradew.titem > 0 then
   local ttext = "Продать предмет"
   buffer.square(90, 6, 22, 12, 0x828282)
   buffer.image(91, 7, iconImageBuffer[1])
   gfunc.showItemDescription(90,19,tradew.asmt[tradew.titem][1])
   buffer.text(118,6,0xFFFFFF,"Количество")
   buffer.square(118, 7, 10, 3, 0x828282)
   buffer.text(119,8,0xFFFFFF,"┼")
   buffer.text(126,8,0xFFFFFF,"─")
   buffer.text(121,9,0xFFFFFF,"Макс.")
   buffer.square(121, 8, 4, 1, 0x717171)
   buffer.text(121,8,0xFFFFFF,tostring(tradew.titemcount))
   buffer.square(130, 7, unicode.len(ttext)+2, 3, 0x00447C)
   buffer.text(131,8,0xFFFFFF,ttext)
   end
 end
end

local craftw = {
	titem = 0,
	titemcount = 1,
	sect = 1,
	tScrl = 1
}

local bmw, bmh = 50, 15

function gfunc.craftWindow(x,y)
buffer.square(x, y, 160, 50, 0x9B9B9B)
buffer.square(x, y, 160, 1, 0x525252)
buffer.square(x, y+1, 160, 3, 0x747474)
local hclr
local t = "Создание предметов"
buffer.text(math.max(80-(unicode.len(t)/2), 0), y, 0xFFFFFF, t)
buffer.text(x+1,y+3,0xC2C2C2,"Наименование")
buffer.text(x+65,y+3,0xC2C2C2,"Шанс создания")
buffer.text(x+130,y+3,0xC2C2C2,"Цена")
buffer.text(x+152,y,0xFFFFFF,"Закрыть")
buffer.text(x+1,y+2,0xFFFFFF,"Монеты "..cCoins)
local tn = "Создать предмет"
local massiv = gameCraftw[craftw.sect]
local t1
 for f = 1, #gameCraftw do
 t1 = unicode.sub(gameCraftw[f]["s_name"],1,25)
 if craftw.sect == f then hclr = 0x525252 else hclr = 0x606060 end
 buffer.square(x+1+f*26-26, y+1, 25, 1, hclr)
 buffer.text(x+1+f*26-26, y+1, 0xCCCCCC, t1)
 end
 for f = 1, math.min(#massiv, 24) do
 if f+4*craftw.tScrl-4 == craftw.titem then buffer.square(x+1,y+4+f*2-2, 160, 3, 0x818181) end
 end
  for f = 1, math.min(#massiv+1, 24) do
   for m = 1, 158 do
   buffer.text(x+1+m,y+4+f*2-2,0xFFFFFF,"─")
   end
  end
 for f = 1, math.min(#massiv, 24) do
 buffer.text(x+1,y+4+f*2-1,0xFFFFFF,gid[massiv[f+4*craftw.tScrl-4]["item"]]["name"])
 buffer.text(x+65,y+4+f*2-1,0xFFFFFF,tostring(massiv[f+4*craftw.tScrl-4]["chance"]).."%")
 buffer.text(x+130,y+4+f*2-1,0xFFFFFF,tostring(massiv[f+4*craftw.tScrl-4]["cost"])..gfunc.changeOconchanie(" монет",massiv[f+4*craftw.tScrl-4]["cost"]))
 end
local clr, bmx, bmy = 0xCCCCCC
 if craftw.titem ~= 0 then
 bmx, bmy = math.floor(80-bmw/2), math.floor(25-bmh/2)
 buffer.square(bmx, bmy, bmw, bmh, 0x828282)
 gfunc.unicodeframe(bmx, bmy, bmw, bmh, 0x4c4c4c)
 buffer.square(bmx-23, bmy, 22, 12, 0x828282)
 buffer.image(bmx-22, bmy+1, iconImageBuffer[1])
 buffer.text(bmx+bmw-2, bmy, 0x4c4c4c, "X")
 buffer.text(bmx+(math.floor(bmw/2-unicode.len(gid[massiv[craftw.titem]["item"]]["name"])/2)), bmy+1, clr, gid[massiv[craftw.titem]["item"]]["name"])
 buffer.text(bmx+1,bmy+2, clr, "Создание предмета")
 buffer.text(bmx+1,bmy+3, clr, "Количество:")
 buffer.square(bmx+13, bmy+3, #tostring(craftw.titemcount)+4, 1, 0x616161)
 buffer.text(bmx+13,bmy+3, clr, "+ "..craftw.titemcount.." -")
 local td
 if craftw.titemcount*massiv[craftw.titem]["cost"] <= cCoins then td = clr else td = 0xb71202 end
 buffer.text(bmx+1,bmy+4, td, "Стоимость: "..tostring(craftw.titemcount*massiv[craftw.titem]["cost"])..gfunc.changeOconchanie(" монет",craftw.titemcount*massiv[craftw.titem]["cost"]))
 buffer.text(bmx+1,bmy+5, clr, "Шанс создания: "..massiv[craftw.titem]["chance"].."%")
 buffer.text(bmx+1,bmy+6, clr, "Шанс улучшения: "..tostring(massiv[craftw.titem]["achance"]).."%")
 buffer.text(bmx+1,bmy+7, clr, "Требуются предметы:")
 local tcl, tcc = nil, 0
  for i = 1, math.min(#massiv[craftw.titem]["recipe"], 5) do
  if checkItemInBag(massiv[craftw.titem]["recipe"][i][1]) >= massiv[craftw.titem]["recipe"][i][2]*craftw.titemcount then tcl = 0xdcdcdc; tcc = tcc + 1 else tcl = 0x575757 end
  buffer.text(bmx+1,bmy+7+i, tcl, "▸"..gid[massiv[craftw.titem]["recipe"][i][1]]["name"].." ("..massiv[craftw.titem]["recipe"][i][2]*craftw.titemcount..")")
  end
 tcl = 0x0054cb5
 if #massiv[craftw.titem]["recipe"] > tcc or td == 0xb71202 then tcl = 0x7B7B7B end
 buffer.square(bmx, bmy+bmh, bmw, 3, tcl)
 buffer.text(bmx+18, bmy+bmh+1, clr, tn)
 tn = nil
 local itemInfo = gfunc.getItemInfo(massiv[craftw.titem]["item"])
 local hn, w, h = 0, 0, #itemInfo 
  for f = 1, #itemInfo do
  if unicode.len(itemInfo[f][1]) > w then w = unicode.len(itemInfo[f][1]) end
  end
 buffer.square(bmx+bmw+1, bmy, w, h, 0x828282)
  for f = 1, #itemInfo do
  buffer.text(bmx+bmw+1,bmy+f-1,itemInfo[f][2],itemInfo[f][1])
  end
 end
end

local ydd = {
	w=40,
	h=24,
	[1]={
		"Продолжить",
		f=function()
		local xpdec = math.floor(mxp*gfunc.random(2*(10/math.sqrt(CGD[1]["lvl"]))*100,5*(10/math.sqrt(CGD[1]["lvl"]))*100)*0.0001)
		 for f=1,#inventory["bag"] do
		  if gfunc.random(0,100) <= 1 then
		  inventory["bag"][f][2] = 0
		  end
		 end
		loadWorld(world[world.current].drespawn)
		teleport(world[world.current].drx)
		gfunc.playerRefreshVar()
		CGD[1]["chp"] = CGD[1]["mhp"]
		cmp = mmp
		 if cxp > xpdec then
		 cxp = cxp - xpdec
		 end
		CGD[1]["living"] = true
		cWindowTrd = nil
		paused = false
		end
		}
}

function gfunc.youDEAD()
paused = true
cTarget = 0
cWindowTrd = "ydd"
buffer.square(1, 1, 160, 50, 0x6B6B6B, nil, nil, 40)
local x, y = 160/2-ydd.w/2, 50/2-ydd.h/2
buffer.square(x, y, ydd.w, ydd.h, 0x7B7B7B, nil, nil, 25)
buffer.square(x-1, y+1, 1, ydd.h-2, 0x7B7B7B, nil, nil, 25)
buffer.square(x+ydd.w, y+1, 1, ydd.h-2, 0x7B7B7B, nil, nil, 25)
local yddTitle = "Персонаж помер"
buffer.text(x+ydd.w/2-unicode.len(yddTitle)/2,y+1,0xFCFCFC,yddTitle)
 for f = 1, #ydd do
 buffer.text(x+ydd.w/2-unicode.len(ydd[f][1])/2,y+2+f,0xCCCCCC,ydd[f][1])
 end
end

local cCnsScroll = 1

function gfunc.gameConsole(x,y)
buffer.square(x, y, 60, 35, 0xABABAB, 0xFFFFFF, " ")
buffer.square(x, y, 60, 1, 0x525252, 0xFFFFFF, " ")
buffer.square(x+1, y+1, 58, 31, 0x1A1A1A, 0xFFFFFF, " ")
buffer.square(x+1, y+33, 58, 1, 0x1A1A1A, 0xFFFFFF, " ")
local bColor, bSub
local text1 = "debug"
buffer.text(x+(math.max(math.floor((60 / 2) - (unicode.len(text1) / 2)), 0)), y, 0xFFFFFF, text1)
buffer.text(x+59,y,0xFFFFFF,"X")
 for f = 1, math.min(#consDataR,28) do
  if consDataR[f+(cCnsScroll*4-4)] then
   if unicode.sub(consDataR[f+(cCnsScroll*4-4)],1,2) == "!/" then 
   bColor = 0xFF0000
   bSub = 3
   else
   bColor = 0xFFFFFF
   bSub = 1
   end
  buffer.text(x+2,y+2+f,bColor,unicode.sub(consDataR[f+(cCnsScroll*4-4)],bSub,56))
  end
 end
end

function gfunc.remove_fsfm(str,cs)
local s = unicode.sub(str,1,1)
 if s == cs then
 return unicode.sub(str,2,#str)
 end
return str
end

local targetQuest = 0

function gfunc.questsList(x,y)
buffer.square(x, y, 100, 30, 0xABABAB, 0xFFFFFF, " ")
buffer.square(x, y, 100, 1, 0x525252, 0xFFFFFF, " ")
buffer.text(x+45,y,0xFFFFFF,"Задания")
buffer.text(x+92,y,0xFFFFFF,"Закрыть")
buffer.square(x+2, y+2, 29, 27, 0x7A7A7A, 0xFFFFFF, " ")
buffer.square(x+32, y+2, 66, 27, 0x7A7A7A, 0xFFFFFF, " ")
 for f = 1, math.min(#cUquests,25) do
 if cUquests[f][3] then buffer.text(x+3,y+3+f,0x00C222,"→") end
 buffer.text(x+3,y+3+f,0xDDDDDD,unicode.sub(gqd[cUquests[f][1]]["name"],1,28))
 end
 if targetQuest > 0 and cUquests[targetQuest] ~= nil then
 local qDeskList = {}
 local dstr
  for i = 1, math.floor(#gqd[cUquests[targetQuest][1]]["descr"]/60) do
  dstr = gfunc.remove_fsfm(gfunc.remove_fsfm(unicode.sub(gqd[cUquests[targetQuest][1]]["descr"],1+(60*i-60),60*i),",")," ")
  table.insert(qDeskList, dstr)
  end
 local qInfoList = {}
  if gqd[cUquests[targetQuest][1]]["qreward"] then
  qInfoList = {
	"Награда:",
	"Монеты "..tostring(gqd[cUquests[targetQuest][1]]["qreward"]["coins"]),
	"Опыт "..tostring(gqd[cUquests[targetQuest][1]]["qreward"]["xp"]),
	}
  end
  table.insert(qInfoList,1,"Описание:")
  for i = 1, #qDeskList do
   if qDeskList[i] ~= nil and qDeskList[i] ~= "" then
   table.insert(qInfoList,i+1,qDeskList[i])
   end
  end

  -- q kill
  if gqd[cUquests[targetQuest][1]]["type"] == "k" then
   if type(gqd[cUquests[targetQuest][1]]["targ"]) == "number" then
   table.insert(qInfoList,1,"► "..gud[gqd[cUquests[targetQuest][1]]["targ"]]["name"].." ("..cUquests[targetQuest][2].."/"..gqd[cUquests[targetQuest][1]]["num"]..")")
   else
    for j = 1, #gqd[cUquests[targetQuest][1]]["targ"] do
	table.insert(qInfoList,1,"► "..gud[gqd[cUquests[targetQuest][1]]["targ"][j]]["name"].." ("..cUquests[targetQuest][2][j].."/"..gqd[cUquests[targetQuest][1]]["num"][j]..")")
	end
   end
  table.insert(qInfoList,1,"Уничтожить: ")
  -- q find
  elseif gqd[cUquests[targetQuest][1]]["type"] == "f" then
   if type(gqd[cUquests[targetQuest][1]]["targ"][1]) == "number" then
   table.insert(qInfoList,1,"► "..gid[gqd[cUquests[targetQuest][1]]["targ"]]["name"].." ("..cUquests[targetQuest][2].."/"..gqd[cUquests[targetQuest][1]]["num"]..")")
   else
    for j = 1, #gqd[cUquests[targetQuest][1]]["targ"] do
	table.insert(qInfoList,1,"► "..gid[gqd[cUquests[targetQuest][1]]["targ"][j][1]]["name"].." ("..cUquests[targetQuest][2][j].."/"..gqd[cUquests[targetQuest][1]]["targ"][j][2]..")")
	end
   end
  table.insert(qInfoList,1,"Найти предметы: ")
  end
   if gqd[cUquests[targetQuest][1]]["qr"] > 0 then
   table.insert(qInfoList,1,"Задание закончено: "..gud[gqd[cUquests[targetQuest][1]]["qr"]]["name"])
   else
   table.insert(qInfoList,1,"Задание закончено: автоматически")
   end
   if gqd[targetQuest]["qstgve"] then
   table.insert(qInfoList,1,"Задание выдано: "..gud[gqd[cUquests[targetQuest][1]]["qstgve"]]["name"])
   end
  if gqd[cUquests[targetQuest][1]]["qreward"] and gqd[cUquests[targetQuest][1]]["qreward"]["item"] ~= nil then
  table.insert(qInfoList,"Предмет:")
   for o = 1, #gqd[cUquests[targetQuest][1]]["qreward"]["item"] do
   table.insert(qInfoList,unicode.sub(gid[gqd[cUquests[targetQuest][1]]["qreward"]["item"][o][1]]["name"].." ("..tostring(gqd[cUquests[targetQuest][1]]["qreward"]["item"][o][2])..")",1,45))
   end
  end
 local ub = ""
 if gqd[cUquests[targetQuest][1]]["repeat"] then ub = " (Повторяемое)" end
 buffer.text(x+33,y+3,0xFFFFFF,unicode.sub(gqd[cUquests[targetQuest][1]]["name"]..ub,1,60))
  for f = 1, #qInfoList do
  buffer.text(x+33,y+3+f,0xFFFFFF,qInfoList[f])
  end
 end
end

local pstatspntrs={x=0,y=0}

local chPointsAss = {0,0,0,0} -- не надо трогать этот массив, читеры!

function gfunc.playerStats(x,y)
buffer.square(x, y, 100, 35, 0xABABAB, 0xFFFFFF, " ")
buffer.square(x, y, 100, 1, 0x525252, 0xFFFFFF, " ")
local someText = "Персонаж"
buffer.text(x+(math.max(50-(unicode.len(someText)/2),0)),y,0xFFFFFF,someText)
buffer.text(x+92,y,0xFFFFFF,"Закрыть")
local info1 = {
	"Имя персонажа: "..gud[CGD[1]["id"]]["name"],
	"Уровень: "..CGD[1]["lvl"],
	"Здоровье: "..tostring(math.floor(CGD[1]["chp"]*10)/10).."/"..math.floor(CGD[1]["mhp"]),
	"Мана: "..tostring(math.floor(cmp*10)/10).."/"..math.floor(mmp),
	"Опыт: "..cxp.."/"..mxp.." ("..tostring(math.floor(cxp*100/mxp*10)/10).."%)",
	"Физическая атака: "..CGD[1]["ptk"][1].."-"..CGD[1]["ptk"][2].." ("..math.ceil((vaddsPnts.vPdm1+vaddsPnts.vPdm2)/2).." от снаряжения)",
	"Магическая атака: "..CGD[1]["mtk"][1].."-"..CGD[1]["mtk"][2].." ("..math.ceil((vaddsPnts.vMdm1+vaddsPnts.vMdm2)/2).." от снаряжения)",
	"Физическая защита: "..CGD[1]["pdef"].." ("..CGD[1]["armorpdef"].." от снаряжения)",
	"Магическая защита: "..CGD[1]["mdef"].." ("..CGD[1]["armormdef"].." от снаряжения)",
	"Вероятность нанесения критического удара: "..CGD[1]["criticalhc"].."%",
	"Количество атак в секунду: "..tostring(math.ceil((1/gsd[1]["reloading"])*10)/10),
}
 for f = 1, #info1 do
 buffer.text(x+3,y+1+f,0xFFFFFF,info1[f])
 end
pstatspntrs.x, pstatspntrs.y = x+3, y+14 
buffer.square(x+3, y+14, 37, 4, 0x898989, 0xFFFFFF, " ")
buffer.text(x+4,y+14,0xFFFFFF,"Очков для распределения "..charPoints)
buffer.text(x+4,y+15,0xEEEEEE,"Интеллект")
buffer.text(x+17,y+15,0xCECECE,tostring(intelligence+chPointsAss[1]+vaddsPnts.vInt))
buffer.text(x+4,y+16,0xEEEEEE,"Сила")
buffer.text(x+17,y+16,0xCECECE,tostring(strength+chPointsAss[2]+vaddsPnts.vStr))
buffer.text(x+4,y+17,0xEEEEEE,"Выносливость")
buffer.text(x+17,y+17,0xCECECE,tostring(survivability+chPointsAss[3]+vaddsPnts.vSur))
 for f = 1, 3 do
 buffer.square(x+20, y+14+f, 3, 1, 0x727272, 0xFFFFFF, " ")
 buffer.text(x+21,y+14+f,0xEEEEEE,"+")
 buffer.square(x+24, y+14+f, 3, 1, 0x727272, 0xFFFFFF, " ")
 buffer.text(x+25,y+14+f,0xEEEEEE,"-")
 end
 buffer.square(x+28, y+15, 9, 1, 0x737373, 0xFFFFFF, " ")
 buffer.text(x+28,y+15,0xEEEEEE,"→Принять")
 buffer.square(x+28, y+17, 9, 1, 0x737373, 0xFFFFFF, " ")
 buffer.text(x+28,y+17,0xEEEEEE,"×отменить")
end

local skillstr = {x=20,y=5,targ=0}

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

function gfunc.playerSkills(x,y)
buffer.square(x, y, 120, 40, 0xABABAB, 0xFFFFFF, " ")
buffer.square(x, y, 120, 1, 0x525252, 0xFFFFFF, " ")
buffer.text(x+57,y,0xFFFFFF,"Умения")
buffer.text(x+112,y,0xFFFFFF,"Закрыть")
buffer.square(x+1, y+2, 50, 37, 0x919191, 0xFFFFFF, " ")
gfunc.playerRefreshVar()
local cnm = ""
 for f = 1, #cPlayerSkills do
 if f == skillstr.targ then buffer.square(x+1, y+2+f*3-3, 50, 3, 0xABABAB); buffer.square(x+51, y+3+f*3-3, 1, 1, 0x919191); buffer.square(x+52, y+2+f*3-3, 1, 3, 0x919191) end
 cnm = gsd[cPlayerSkills[f][1]]["name"].." ("..cPlayerSkills[f][3].." ур.)"
 buffer.text(x+math.floor(25-unicode.len(cnm)/2),y+3+f*3-3,0xFFFFFF,cnm)
 end
local ntt, kfc
local stypes = {
["attack"] = "Атака",
["buff"] = "Бафф",
}
local blbl, abc, rv
 if skillstr.targ ~= 0 then
 buffer.square(x+53, y+2, 50, 37, 0x919191, 0xFFFFFF, " ")
 blbl = gsd[cPlayerSkills[skillstr.targ][1]] 
  if cPlayerSkills[skillstr.targ][3] < #blbl["manacost"] then
   buffer.square(x+55, y+30, 46, 8, 0xA3A3A3)  
   local buben = {
   {"Улучшение умения • следующий уровень "..cPlayerSkills[skillstr.targ][3]+1,0xEFEFEF}
   }
   if blbl["reqlvl"] then
   table.insert(buben,{"Требуемый уровень: "..blbl["reqlvl"][cPlayerSkills[skillstr.targ][3]+1],0xEFEFEF})
   if blbl["reqlvl"][cPlayerSkills[skillstr.targ][3]+1] > CGD[1]["lvl"] then buben[#buben][2] = 0xEE1414 end
   end
   if blbl["reqcn"] then
   table.insert(buben,{"Стоимость улучшения: "..blbl["reqcn"][cPlayerSkills[skillstr.targ][3]+1].." монет",0xEFEFEF})
   if blbl["reqcn"][cPlayerSkills[skillstr.targ][3]+1] > cCoins then buben[#buben][2] = 0xEE1414 end
   end
   if blbl["reqitem"] then
   table.insert(buben,{"Требуемый предмет: "..gid[blbl["reqitem"][cPlayerSkills[skillstr.targ][3]+1][1]]["name"].."("..checkItemInBag(blbl["reqitem"][cPlayerSkills[skillstr.targ][3]+1][1]).."/"..blbl["reqitem"][cPlayerSkills[skillstr.targ][3]+1][2]..")",0xEFEFEF})
   if checkItemInBag(blbl["reqitem"][cPlayerSkills[skillstr.targ][3]+1][1]) < blbl["reqitem"][cPlayerSkills[skillstr.targ][3]+1][2] then buben[#buben][2] = 0xEE1414 end
   end
   for f = 1, #buben do
   buffer.text(x+57,y+30+f,buben[f][2],tostring(buben[f][1]))
   end
   abc = "Изучить умение"
   buffer.square(x+70, y+35, unicode.len(abc)+2, 3, 0x077DAC)
   buffer.text(x+71,y+36,0xCECECE,abc)
  end
 

 local slvl = cPlayerSkills[skillstr.targ][3]
 kfc = {["p"]="физического",["m"]="магического"}
 rv = {}
 if slvl > 0 then
  if blbl["value"] then rv[1] = blbl["value"][slvl] else rv[1] = "" end
  if blbl["bseatckinc"] then rv[2] = blbl["bseatckinc"][slvl] else rv[2] = "" end
  if type(blbl["basedmgmlt"]) == "table" then rv[3] = blbl["basedmgmlt"][slvl]
  elseif type(blbl["basedmgmlt"]) == "number" then rv[3] = blbl["basedmgmlt"]
  else rv[3] = "" 
  end
  if blbl["weapondmgmlt"] then rv[4] = blbl["weapondmgmlt"][slvl] else rv[4] = "" end
  if blbl["eff"] and ged[blbl["eff"]]["dur"] then rv[5] = ged[blbl["eff"]]["dur"][slvl] else rv[5] = "" end
  if blbl["eff"] and ged[blbl["eff"]]["val"] then rv[6] = math.abs(ged[blbl["eff"]]["val"][slvl]) else rv[6] = "" end
 end
 ntt = {
 ["a"]=lang(kfc[blbl["typedm"]]),
 ["b"]=rv[1],
 ["c"]=rv[2],
 ["i"]=rv[3],
 ["e"]=rv[4],
 ["d"]=rv[5],
 ["v"]=rv[6],
 }
 
 gfunc.pSkillsPbar(x+55,y+25,slvl)
 buffer.text(x+54,y+3,0xFFFFFF,"•"..blbl["name"])
 buffer.text(x+54,y+4,0xFFFFFF,"Тип: "..stypes[blbl["type"]])
  if slvl > 0 then
  buffer.text(x+54,y+5,0xFFFFFF,"Уровень умения: "..slvl.." / "..#blbl["manacost"])
  buffer.text(x+54,y+6,0xFFFFFF,"Использует маны: "..blbl["manacost"][slvl].." ед.")
  buffer.text(x+54,y+7,0xFFFFFF,"Перезарядка: "..blbl["reloading"].." сек.")
   if blbl["type"] == "attack" then
   buffer.text(x+54,y+8,0xFFFFFF,"Дальность: "..(blbl["distance"]+(vAttackDistance or 8)))
   if blbl["eff"] then cnm = ged[blbl["eff"]]["name"] else cnm = "Нет эффекта" end
   buffer.text(x+54,y+8,0xFFFFFF,"Эффект умения: "..cnm)
   elseif blbl["type"] == "buff" then
   buffer.text(x+54,y+8,0xFFFFFF,"Эффект умения: "..ged[blbl["eff"]]["name"])
   end
  else
  buffer.text(x+54,y+5,0xCCCCCC,"Умение ещё не изучено")
  end
  if slvl > 0 then
   abc = {
   }

   for k = 1, #blbl["descr"] do
    abc[k] = ""
	rv = 1
    for m = 1, unicode.len(blbl["descr"][k]) do
     if unicode.sub(blbl["descr"][k],rv,rv) ~="$" then 
	 abc[k] = abc[k]..unicode.sub(blbl["descr"][k],rv,rv)
	 rv = rv+1
     else
	 abc[k] = abc[k]..tostring(ntt[(unicode.sub(blbl["descr"][k],rv+1,rv+1))])
	 rv = rv+2
	 end
    end
   end
  end
  if slvl > 0 then
   for f = 1, #abc do
   buffer.text(x+54,y+9+f,0xFFFFFF,tostring(abc[f]))
   end
  end
 blbl, abc, stypes, cnm = nil, nil, nil, nil
 buffer.text(x+105,y+3,0xFFFFFF,"Установить")
 buffer.text(x+105,y+4,0xFFFFFF,"на клавишу…")
  for p = 1, #gfunc.sarray do
  slvl = gfunc.sarray[p].c
   for n = 1, #cUskills do
   if cPlayerSkills[skillstr.targ][1] == cUskills[p+1] then slvl = 0xBBBBBB; break end
   end
  buffer.square(x+105, 6+y+4*p-4, 10, 3, slvl)
  buffer.text(x+109,6+y+4*p-3,0xFFFFFF,tostring(p+1))
  end
 end
end

local function killUnitWithoutLoot(id)
CGD[id]["living"] = false
CGD[id]["resptime"] = gud[CGD[id]["id"]]["vresp"]
end

local function spawnSingleUnit(id,x,y)
addUnit(id,x,y)
imageBuffer[#imageBuffer+1] = image.duplicate(image.load(dir.."sprpic/"..gud[id]["image"]..".pic"))
CGD[#CGD]["image"] = #imageBuffer
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
  if d[f] == "np" then
  addUnit(43,x+10,2)
  imageBuffer[#imageBuffer+1] = image.duplicate(image.load(dir.."sprpic/"..gud[43]["image"]..".pic"))
  CGD[#CGD]["image"] = #imageBuffer
  elseif type(d[f]) == "table" and d[f][1] == "sp" then
  spawnSingleUnit(d[f][2],x+gfunc.random(-10,10),1)
  elseif type(d[f]) == "table" and d[f][1] == "q_lock" then
   for i = 1, #d[f] - 1 do
   gqd[d[f][i+1]]["comp"] = true
	for e = 1, #cUquests do
	if cUquests[#cUquests-e+1][1] == d[f][i+1] then table.remove(cUquests,#cUquests-e+1) end
	end   
   end
  end
 end
end
local itemLoot
local function makeDamage(id, damage)
local eeee
local chchance = 1
if gfunc.random(1,100) <= CGD[1]["criticalhc"] then chchance = 2; damage = damage * 2 end
 if CGD[id]["chp"] > damage then
 CGD[id]["attPlayer"] = true
 CGD[id]["chp"] = CGD[id]["chp"] - damage
 console.debug("Урон нанесен персонажу",unicode.sub(gud[CGD[id]["id"]]["name"],1,15),tostring(damage):sub(1,5))
 elseif CGD[id]["chp"] <= damage then
 CGD[id]["effects"] = {}
 CGD[id]["attPlayer"] = false
 console.debug("Урон нанесен персонажу",unicode.sub(gud[CGD[id]["id"]]["name"],1,15),tostring(damage):sub(1,5))
 CGD[id]["chp"] = 0
 CGD[id]["living"] = false
 CGD[id]["resptime"] = gud[CGD[id]["id"]]["vresp"]
  for f = 1, #cUquests do
   if type(cUquests[f][2]) == "number" then
    if CGD[id]["id"] == gqd[cUquests[f][1]]["targ"] and cUquests[f][3] == false then
	 if cUquests[f][2] + 1 < gqd[cUquests[f][1]]["num"] then
	 cUquests[f][2] = cUquests[f][2] + 1
	 else
	 gqd[cUquests[f][1]]["comp"] = true
	 cUquests[f][2] = gqd[cUquests[f][1]]["num"]
	 cUquests[f][3] = true 
	 addsmsg1("Задание '"..gqd[cUquests[f][1]]["name"].."' выполнено!")
	 end
    end
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
	 addsmsg1("Задание '"..gqd[cUquests[f][1]]["name"].."' выполнено!") 
	 end
	gqd[cUquests[f][1]]["comp"] = true
	for j = 1, #gqd[cUquests[f][1]]["targ"] do cUquests[f][2][j] = gqd[cUquests[f][1]]["num"][j] end
	cUquests[f][3] = true 	  
    end
   end
  end
 local expr = gud[CGD[id]["id"]]["loot"]["exp"]+math.ceil(gfunc.random(-gud[CGD[id]["id"]]["loot"]["exp"]*0.1,gud[CGD[id]["id"]]["loot"]["exp"]*0.1))
 addXP(expr)
 local coinsLoot = gud[CGD[id]["id"]]["loot"]["coins"]
 local giveCoins = coinsLoot+math.ceil(coinsLoot*gfunc.random(-(50+1.1^math.min(CGD[id]["lvl"],35)),(50+1.1^math.min(CGD[id]["lvl"],35)))/100)
 addCoins(giveCoins)
 itemLoot = {}
  if gud[CGD[id]["id"]]["loot"]["drop"] then
   for f = 1, #gud[CGD[id]["id"]]["loot"]["drop"] do
   itemLoot[#itemLoot+1] = gud[CGD[id]["id"]]["loot"]["drop"][f]
   end
  end
  for f = 1, #t_loot[gud[CGD[id]["id"]]["loot"]["items"]] do
  itemLoot[#itemLoot+1] = t_loot[gud[CGD[id]["id"]]["loot"]["items"]][f]
  end
 -- рандомный лут с мобов
 itemLoot = getRandSeq(itemLoot)
 local nitemloop = 1 -- количество циклов рандома
 if gud[CGD[id]["id"]]["tcdrop"] then nitemloop = gud[CGD[id]["id"]]["tcdrop"] end
  for l = 1, nitemloop do
   for f = 1, #itemLoot do
    if itemLoot[f][1] ~= nil and gfunc.random(1,10^5) <= itemLoot[f][2]*10^3 then
    if gfunc.random(1,100) >= 25 then itemLoot[f][1] = createNewItem(itemLoot[f][1]) end
    addItem(itemLoot[f][1],1)
    console.debug("Получен предмет "..gid[itemLoot[f][1]]["name"])
    addsmsg1("Получен предмет "..gid[itemLoot[f][1]]["name"])
    break
    end
   end
  end
 CGD[id]["resptime"] = gud[CGD[id]["id"]]["vresp"]
 console.debug("опыт +",expr,"монеты +",giveCoins)
 if id == cTarget then cTarget = 0 end
 showTargetInfo = false
 if gud[CGD[id]["id"]]["daft_klz"] then dAfterkill(gud[CGD[id]["id"]]["daft_klz"],CGD[id]["x"]) end
 if gud[CGD[id]["id"]]["nres"] == true then gud[CGD[id]["id"]]["nres"] = false end
 end
 if damage > 0 then 
  if chchance == 1 then
  inserttunitinfo(id,"Урон "..math.ceil(damage)) 
  elseif chchance == 2 then
  inserttunitinfo(id,"Критический урон "..math.ceil(damage))
  end
 end
bce.bColorEffect(1,85,38)
end

local function playerGetDamage(fromID,tipedm,dmplus)
 if CGD[fromID]["x"] > CGD[1]["x"] then
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
 playerCanMove = true
 CGD[1]["image"] = 0
 end
local atck, dmgRedu = gfunc.random(CGD[fromID]["ptk"][1]*10,CGD[fromID]["ptk"][2]*10)/10, CGD[1]["pdef"]/(CGD[1]["pdef"]+CGD[fromID]["lvl"]*30)
 if tipedm == "m" then
 atck = gfunc.random(CGD[fromID]["mtk"][1]*10,CGD[fromID]["mtk"][2]*10)/10
 dmgRedu = CGD[1]["mdef"]/(CGD[1]["mdef"]+CGD[fromID]["lvl"]*30)
 end
local damage = math.max(math.floor(math.max((atck+dmplus)*(1-dmgRedu),0)),1)
if cTarget == 0 then cTarget = fromID end
 if damage < CGD[1]["chp"] then
 CGD[1]["chp"] = CGD[1]["chp"] - damage
 console.debug(unicode.sub(gud[CGD[fromID]["id"]]["name"],1,25),"нанес",tostring(damage):sub(1,5).." ед. урона ("..tipedm..")")
 else
 CGD[1]["living"] = false
 end
return damage
end

local function enemySkill(enemy,sl,lvl)
 if CGD[enemy]["living"] and getDistanceToId(1,enemy) <= 60 and CGD[enemy]["attPlayer"] == true and CGD[enemy]["ctck"] then
  local dist = gud[CGD[enemy]["id"]]["atds"]+eusd[sl]["distance"]
  if getDistanceToId(1,enemy) > dist then
   if CGD[enemy]["x"] > CGD[1]["x"] then
   CGD[enemy]["spos"] = "l"
   CGD[enemy]["mx"] = CGD[1]["x"]+CGD[1]["width"]+dist
   else
   CGD[enemy]["spos"] = "r"
   CGD[enemy]["mx"] = CGD[1]["x"]-dist
   end
  else
  CGD[enemy]["mx"] = CGD[enemy]["x"]
  playerGetDamage(enemy,eusd[sl]["typedm"],gfunc.random(eusd[sl]["mindamage"][lvl]*10,eusd[sl]["maxdamage"][lvl]*10)/10)
   if eusd[sl]["eff"] then
   addPlayerEffect(eusd[sl]["eff"][1],eusd[sl]["eff"][2])
   end
  end
 end
end

local function useSkill(skill)
local cskill = cPlayerSkills[cUskills[skill]][1]
local lvl = cPlayerSkills[cUskills[skill]][3]
local damage = 0
 if gsd[cskill]["type"] == "attack" and CGD[cTarget]["rtype"] ~= "p" and CGD[cTarget]["rtype"] ~= "f" and CGD[cTarget]["rtype"] ~= "r" and CGD[cTarget]["rtype"] ~= "c" then
  if CGD[cTarget]["x"] > CGD[1]["x"] then
  CGD[1]["spos"] = "r"
  else
  CGD[1]["spos"] = "l"
  end
 local weaponDmg
   if gsd[cskill]["typedm"] == "p" then
   damage = damage + gfunc.random(CGD[1]["ptk"][1]*10,CGD[1]["ptk"][2]*10)/10
   weaponDmg = gfunc.random(vaddsPnts.vPdm1,vaddsPnts.vPdm2)
   elseif gsd[cskill]["typedm"] == "m" then
   damage = damage + gfunc.random(CGD[1]["mtk"][1]*10,CGD[1]["mtk"][2]*10)/10
   weaponDmg = gfunc.random(vaddsPnts.vMdm1,vaddsPnts.vMdm2)
   end  
   if type(gsd[cskill]["basedmgmlt"]) == "table" then damage = damage + damage*gsd[cskill]["basedmgmlt"][lvl]*0.01 
   elseif type(gsd[cskill]["basedmgmlt"]) == "number" then damage = damage + damage*gsd[cskill]["basedmgmlt"]*0.01 
   end  
   if gsd[cskill]["weapondmgmlt"] and inventory["weared"]["weapon"] > 0 then damage = damage + weaponDmg*gsd[cskill]["weapondmgmlt"][lvl]*0.01 end
   if gsd[cskill]["bseatckinc"] then damage = damage + damage*gsd[cskill]["bseatckinc"][lvl]*0.01 end
   if gsd[cskill]["value"] then damage = damage + gsd[cskill]["value"][lvl] end
  if gsd[cskill]["typedm"] == "p" then
  damage = math.max(damage*(1-CGD[cTarget]["pdef"]/(CGD[cTarget]["pdef"]+CGD[1]["lvl"]*30)),0.1)
  elseif gsd[cskill]["typedm"] == "m" then
  damage = math.max(damage*(1-CGD[cTarget]["mdef"]/(CGD[cTarget]["mdef"]+CGD[1]["lvl"]*30)),0.1)
  end
  if cmp >= gsd[cskill]["manacost"][lvl] and cPlayerSkills[cUskills[skill]][2] == 0 and getDistanceToId(1,cTarget) <= vAttackDistance+gsd[cskill]["distance"] then
  cmp = cmp - gsd[cskill]["manacost"][lvl]
  damage = math.max(damage,1)
  makeDamage(cTarget, math.floor(damage))
  if cTarget ~= 0 and gsd[cskill]["eff"] ~= nil then addUnitEffect(cTarget,gsd[cskill]["eff"],cPlayerSkills[cUskills[skill]][3]) end
  cPlayerSkills[cUskills[skill]][2] = gsd[cskill]["reloading"]*10
  vtskillUsingMsg = 3
  skillUsingMsg[1] = gsd[cskill]["name"]
  end
 elseif gsd[cskill]["type"] == "buff" and cmp >= gsd[cskill]["manacost"][lvl] and cPlayerSkills[cUskills[skill]][2] == 0 then
 cmp = cmp - gsd[cskill]["manacost"][lvl]
 cPlayerSkills[cUskills[skill]][2] = gsd[cskill]["reloading"]*10
 if gsd[cskill]["eff"] ~= nil then addUnitEffect(1,gsd[cskill]["eff"],lvl) end
 skillUsingMsg[1] = gsd[cskill]["name"]
 end
end

function gfunc.pickUpResource()
pckTarget = cTarget
pickingUp = true
local mpcktime = gfunc.random(gud[CGD[cTarget]["id"]]["mnprs"]*10,gud[CGD[cTarget]["id"]]["mxprs"]*10)
pckTime, maxPckTime = mpcktime, mpcktime
playerCanMove = false
CGD[1]["image"] = -1
CGD[1]["mx"] = CGD[1]["x"]
end

function gfunc.getRawCount(array)
local count = 0
 for f, v in pairs(array) do
 count = count + 1
 end
return count
end

local function debugModeText()
local text = {
	"#CGD = "..#CGD,
	"#gid = "..#gid,
	"#imageBuffer = "..#imageBuffer,
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
 for f = 1, math.min(#cUquests,10) do
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
 local cx = math.min(x,159-math.min(w,45))
 if #cUquests > 0 then 
 buffer.square(cx,y,math.max(math.min(w,45),8),1,0x525252)
 cl = 50
 if limg < 2 then cl = nil end
 buffer.square(cx,y+1,math.max(math.min(w,45),8),#tablo,0x828282,nil,nil,cl)
 buffer.text(cx,y,0xEFEFEF,"Задания")
 end
 for f = 1, #tablo do
 buffer.text(cx,y+f,tablo[f][2],tablo[f][1])
 end
end

function gfunc.GetQuestReward(q)
addXP(gqd[q]["qreward"]["xp"])
cCoins = cCoins + gqd[q]["qreward"]["coins"]
 if gqd[q]["qreward"]["item"] then
  for u = 1, #gqd[q]["qreward"]["item"] do
  addItem(gqd[q]["qreward"]["item"][u][1],gqd[q]["qreward"]["item"][u][2])
  end
 end
end

local function dmain()
 if cWindowTrd ~= "inventory" and cWindowTrd ~= "tradeWindow" and cWindowTrd ~= "craftWindow" then
  if not debugMode then
  world[world.current].draw()
  else
  buffer.square(1,1,160,50,0x000000)
  end
  if CGD[1]["spos"] == "r" then buffer.image(pSprPicPos, 34, imageBuffer[CGD[1]["image"]])
  else buffer.image(pSprPicPos, 34, image.flipHorizontal(image.duplicate(imageBuffer[CGD[1]["image"]])))
  end
 drawCDataUnit()
  if cWindowTrd ~= "screen_save" then
   if CGD[1]["living"] then
    if cWindowTrd ~= "pause" then
    playerCInfoBar(1,1)
    end
   if cTarget ~= 0 then targetCInfoBar(60,2) end
   fSkillBar(110,1)
   end
  gfunc.questsCompList(qCompList.x,qCompList.y)
  buffer.text(156,2,0xFFFFFF,"█ █")
  buffer.text(156,3,0xFFFFFF,"█ █")
   if smsg1time > 0 then
   buffer.text(9,49,0x929292,">"..sMSG1[#sMSG1-1])
   buffer.text(9,50,0xC7C7C7,">"..sMSG1[#sMSG1])
   end
   if smsg2time > 0 then
   buffer.text(80-unicode.len(sMSG2[#sMSG2])/2,12,0xD3D3D3,sMSG2[#sMSG2])
   end
   if smsg4time > 0 then
   buffer.text(2,13,0x9C9C9C,sMSG4[#sMSG4-2])
   buffer.text(2,14,0xACACAC,sMSG4[#sMSG4-1])
   buffer.text(2,15,0xBCBCBC,sMSG4[#sMSG4])
   end
  end
 end
if cWindowTrd == "pause" then 
gfunc.fPause() 
elseif cWindowTrd == "inventory" then 
gfunc.drawInventory(1,1)
elseif cWindowTrd == "dialog" then
gfunc.drawDialog(12,11)
elseif cWindowTrd == "spdialog" then
gfunc.specialDialog()
elseif cWindowTrd == "quests" then
gfunc.questsList(30,12)
elseif cWindowTrd == "console" then
gfunc.gameConsole(50,10)
elseif cWindowTrd == "pstats" then
gfunc.playerStats(30,8)
elseif cWindowTrd == "tradeWindow" then
gfunc.tradeWindow(1,1)
elseif cWindowTrd == "craftWindow" then
gfunc.craftWindow(1,1)
elseif not CGD[1]["living"] then
gfunc.youDEAD()
elseif cWindowTrd == "skillsWindow" then
gfunc.playerSkills(skillstr.x,skillstr.y)
end
 if debugMode then
 debugModeText()
 end
buffer.text(1,50,0xFFFFFF,"fps: "..tostring(cfps))
usram = sram()
buffer.text(160-#usram,50,0xC7C7C7,usram)
buffer.draw()
end

function gfunc.mCheck()
if computer.totalMemory() >= 2*1024^2 then return true end
if computer.freeMemory() < 8192 then return false end
return true
end

function gfunc.openInventory()
	local tblgbldblk = {
	[1]={"helmet","image/gigd1.pic"},
	[2]={"bodywear","image/gigd2.pic"},
	[3]={"pants","image/gigd3.pic"},
	[4]={"footwear","image/gigd4.pic"},
	[5]={"weapon","image/gigd5.pic"},
	[6]={"pendant","image/gigd6.pic"},
	[7]={"robe","image/gigd7.pic"},
	[8]={"ring","image/gigd8.pic"},
	
	}
cWindowTrd = "inventory"
iconImageBuffer[0]={}
 for il = 1, #tblgbldblk do
  if gfunc.mCheck() then
  iconImageBuffer[0][tblgbldblk[il][1]] = image.load(dir..tblgbldblk[il][2])
  end
 end
 for f = 1, #inventory["bag"] do
  if inventory["bag"][f][1] ~= 0 and inventory["bag"][f][2] ~= 0 and gid[inventory["bag"][f][1]] and gfunc.mCheck() then
  iconImageBuffer[f] = image.load(dir.."itempic/"..aItemIconsSpr[gid[inventory["bag"][f][1]]["icon"]]..".pic")
  end
 end
 for f = 1, #wItemTypes do
  if inventory["weared"][wItemTypes[f]] ~= 0 and gfunc.mCheck() then 
  iconImageBuffer[wItemTypes[f]] = image.load(dir.."itempic/"..aItemIconsSpr[gid[inventory["weared"][wItemTypes[f]]]["icon"]]..".pic")
  end
 end
end

gfunc.fPauseMenuAction = {
[1]=function()
cWindowTrd = nil 
paused = false
end,
[2]=gfunc.openInventory,
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
saveGame(dir.."saves","save")
end,
[7]=function()
loadGame(dir.."saves","save")
end,
[8]=function()
ingame = false
end,
}

loadWorld(world.current)
gfunc.playerRefreshVar()
CGD[1]["chp"] = CGD[1]["mhp"]
cmp = mmp
dmain()

local uMoveRef = 1
local healthReg, manaReg

local huynya = {}

local function functionPS()
local value, duration, efftype
local itemLootarray
local qwert
 while ingame do
 table.insert(huynya,gamefps) 
 cfps = gamefps
 gamefps = 0
  if not paused then
  if cTarget ~= 0 and getDistanceToId(1,cTarget) > 99 then cTarget = 0 end
  gfunc.playerRefreshVar()
  uMoveRef = uMoveRef - 1
  if vtskillUsingMsg > 0 then vtskillUsingMsg = vtskillUsingMsg - 1 end
  manaReg = math.min(0.26+(CGD[1]["lvl"]-1)*0.015,2) 
  healthReg = math.min(0.08+(CGD[1]["lvl"]-1)*0.008,1) 
   
   if CGD[1]["living"] then
    -- восстановление маны персонажа
	if cmp < mmp - manaReg then
    cmp = cmp + manaReg
	else
	cmp = mmp
    end
    
    -- восстановление здоровья персонажа
    if CGD[1]["chp"] < CGD[1]["mhp"] - healthReg then
    CGD[1]["chp"] = CGD[1]["chp"] + healthReg
    else
	CGD[1]["chp"] = CGD[1]["mhp"]
	end
   end
  
   for f = 2, #CGD do
    -- произвольное восстановление хп на 5%/сек.
	if not CGD[f]["attPlayer"] and CGD[f]["living"] then
	 if CGD[f]["chp"]+math.ceil(CGD[f]["mhp"]*0.05)<CGD[f]["mhp"] then 
	 CGD[f]["chp"]=CGD[f]["chp"]+math.ceil(CGD[f]["mhp"]*0.05)
	 else
	 CGD[f]["chp"] = CGD[f]["mhp"]
	 end
	end
	-- респавн юнитов
	if not CGD[f]["living"] and CGD[f]["resptime"] > 0 then
	CGD[f]["resptime"] = CGD[f]["resptime"] - 1
	end
    if not CGD[f]["living"] and CGD[f]["resptime"] == 0 then
	CGD[f]["chp"] = CGD[f]["mhp"]
	CGD[f]["x"] = CGD[f]["sx"]
	CGD[f]["living"] = true
	end
	-- рандомное движение мобов
	if getDistanceToId(1,f) <= 384 and CGD[f]["rtype"] == "e" and CGD[f]["living"] and gfunc.random(1,3) == 3 and uMoveRef == 0 then
	CGD[f]["mx"] = CGD[f]["sx"] + gfunc.random(-16, 16)
	end 
    --
	 if CGD[f]["rtype"] == "e" then
	  qwert = {gud[CGD[f]["id"]]["skill"][#gud[CGD[f]["id"]]["skill"]][1],gud[CGD[f]["id"]]["skill"][#gud[CGD[f]["id"]]["skill"]][2]}
	  for o = 1, #gud[CGD[f]["id"]]["skill"] do
	   if gfunc.random(1,100) <= gud[CGD[f]["id"]]["skill"][o][3] then
	   qwert = {gud[CGD[f]["id"]]["skill"][o][1],gud[CGD[f]["id"]]["skill"][o][2]}
	   break
	   end
	  end
	 enemySkill(f,qwert[1],qwert[2])
	 end
	qwert = nil
	if CGD[f]["living"] and CGD[f]["attPlayer"] == true and getDistanceToId(1,f) > 60  then
	CGD[f]["attPlayer"] = false
	CGD[f]["mx"] = CGD[f]["sx"]
	end
    -- агр мобов
	if CGD[f]["living"] and gud[CGD[f]["id"]]["agr"] == true and getDistanceToId(1,f) <= gud[CGD[f]["id"]]["atds"]*2 then
    CGD[f]["attPlayer"] = true
    end
	-- самотаргет
	if cTarget == 0 and CGD[f]["attPlayer"] == true then cTarget = f end	
    
    for m = 1, #CGD[f]["tlinfo"] do
     if CGD[f]["tlinfo"][1] then
	 table.remove(CGD[f]["tlinfo"],1)
	 end
    end
   end
   -- обслуживание всех эффектов на всех объектах
   for f = 1, #CGD do
    CGD[f]["cmove"] = true
	CGD[f]["ctck"] = true
	if f ~= 1 then
	 if not gud[CGD[f]["id"]]["pdef"] then CGD[f]["pdef"] = math.ceil(gud[CGD[f]["id"]]["lvl"]*19.84+(gud[CGD[f]["id"]]["lvl"]^2/1.5)) else CGD[f]["pdef"] = gud[CGD[f]["id"]]["pdef"] end
     if not gud[CGD[f]["id"]]["mdef"] then CGD[f]["mdef"] = math.ceil(gud[CGD[f]["id"]]["lvl"]*18.31+(gud[CGD[f]["id"]]["lvl"]^2/1.5)) else CGD[f]["mdef"] = gud[CGD[f]["id"]]["mdef"] end	
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
	   if cmp + value/duration < mmp and cmp + value/duration >= 0 then
	   cmp = cmp + value/duration
	   elseif cmp + value/duration >= mmp then cmp = mmp
	   end
	  elseif efftype == "hpi%" then
	  CGD[f]["chp"] = math.min(CGD[f]["chp"] + CGD[f]["mhp"]*value*0.01,CGD[f]["mhp"])
	  elseif efftype == "hpd" then
      makeDamage(f,value/duration)
	  elseif efftype == "pdfi%" then
	  CGD[f]["pdef"] = CGD[f]["pdef"]+math.ceil(value/100*CGD[f]["pdef"])
	  elseif efftype == "mdfi%" then
	  CGD[f]["mdef"] = CGD[f]["mdef"]+math.ceil(value/100*CGD[f]["mdef"])
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
	   table.remove(CGD[f]["effects"],#CGD[f]["effects"]-eff+1) 
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

  setScreenNewPosition() -- отображает часть мира независимо от координат игрока
  if sScreenTimer1 > 0 then sScreenTimer1 = sScreenTimer1 - 1 end
 
	if lostItem and not gfunc.checkInventoryisFull() then -- дает предмет который не поместился в инвентарь
	addItem(lostItem[1],lostItem[2])
	lostItem = nil
	end
 
   for f = 1, #cUquests do
   if gqd[cUquests[f][1]]["type"] == "t" and cUquests[f][3] == false then cUquests[f][3] = true end
   end
   
   for f = 1, #inventory["bag"] do
    if inventory["bag"][f][1] > 0 and gid[inventory["bag"][f][1]] and inventory["bag"][f][2] > 0 and CGD[1]["living"] and gid[inventory["bag"][f][1]]["type"] == "elementmul" then
     if gid[inventory["bag"][f][1]]["subtype"] == "hp" and CGD[1]["chp"] <= CGD[1]["mhp"]*(gid[inventory["bag"][f][1]]["props"]["r"]*0.01) then
	 CGD[1]["chp"] = math.min(CGD[1]["chp"]+CGD[1]["mhp"]*0.01*gid[inventory["bag"][f][1]]["props"]["ics"],CGD[1]["mhp"])
	 inventory["bag"][f][2] = inventory["bag"][f][2] - 1
	 break
	 elseif gid[inventory["bag"][f][1]]["subtype"] == "mp" and cmp <= mmp*(gid[inventory["bag"][f][1]]["props"]["r"]*0.01) then
	 cmp = math.min(cmp+mmp*0.01*gid[inventory["bag"][f][1]]["props"]["ics"],mmp)
	 inventory["bag"][f][2] = inventory["bag"][f][2] - 1
	 break
	 end
    end
   end
  end
 os.sleep(1) 
 end
local jo = io.open("/w16log.txt", "a")
for f = 1, #huynya do
jo:write(huynya[f].."\n")
end
jo:close()
end

local tblpbl

local function funcP4()
 while ingame do
  if not paused then
   for f = 2, #CGD do
    if getDistanceToId(1,f) <= 140 and CGD[f]["x"] ~= CGD[f]["mx"] and not gud[CGD[f]["id"]]["cmve"] and CGD[f]["cmove"] then
	tblpbl = 0.25
	if CGD[f]["attPlayer"] then 
	tblpbl = 0.5 
	if getDistanceToId(1,f) >= gud[CGD[f]["id"]]["atds"]*2 then tblpbl = 1 end
	end	
	movetoward(f, CGD[f]["mx"], 100, tblpbl)
	end
   end
  end
 os.sleep(0.25)
 end
end

local function funcP10()
 while ingame do
 if not paused then
  if pickingUp then
   CGD[1]["mx"] = CGD[1]["x"]
   pckTime = pckTime - 1
   if CGD[1]["image"] ~= -1 then CGD[1]["image"] = -1 end
   end
   if pickingUp and pckTime == 0 then
   CGD[1]["image"] = 0
   pickingUp = false
   itemLootarray = getRandSeq(gud[CGD[pckTarget]["id"]]["items"])
	for item = 1, #itemLootarray do
	 if itemLootarray[item][1] ~= nil and 1000-itemLootarray[item][2]*10 <= gfunc.random(1,1000) then
     if gfunc.random(1,15) == 5 then itemLootarray[item][1] = createNewItem(itemLootarray[item][1]) end
     addItem(itemLootarray[item][1],1)
     console.debug('Получен предмет "'..gid[itemLootarray[item][1]]["name"]..'"')
     addsmsg1('Получен предмет "'..gid[itemLootarray[item][1]]["name"]..'"')
     break
     end
	end
   addXP(gud[CGD[pckTarget]["id"]]["exp"])
   addCoins(gud[CGD[pckTarget]["id"]]["coins"])
   playerCanMove = true
   CGD[pckTarget]["living"] = false
   CGD[pckTarget]["resptime"] = gud[CGD[pckTarget]["id"]]["vresp"]
   if pckTarget == cTarget then cTarget = 0 end
   end
  
   for f = 1, #cUskills do
    if cUskills[f] > 0 and cPlayerSkills[cUskills[f]][1] > 0 and cPlayerSkills[cUskills[f]][2] > 0 then
    cPlayerSkills[cUskills[f]][2] = cPlayerSkills[cUskills[f]][2] - 1
    end
   end
   if #consDataR >= 10 then table.remove(consDataR,1) end
  
 end
 os.sleep(0.1)
 end
end

gfunc.cim = 1
gfunc.pmovlck = false

local function funcP20()
while ingame do
 if not paused then
  if gfunc.usepmx and CGD[1]["x"] ~= CGD[1]["mx"] then
  gfunc.playerAutoMove(math.floor(CGD[1]["mx"]), 3555, 3)
  end
  
  gfunc.pmovlck = false
  if CGD[1]["x"] <= world[world.current].limitL and pmov < 0 then 
  gfunc.pmovlck = true
  CGD[1]["image"] = 0
  elseif CGD[1]["x"] >= world[world.current].limitR and pmov > 0 then 
  gfunc.pmovlck = true
  CGD[1]["image"] = 0
  end
  
  event.listen("key_up",
  function() 
  if gfunc.keyactionmove then
  pmov = 0
  gfunc.keyactionmove = false
  gfunc.pmovlck = true
  pmov = 0
  gfunc.cim = 1
  gfunc.usepmx = false
  CGD[1]["image"] = 0
  event.ignore("key_up",function() end)
  end
  end)
 
  if not gfunc.pmovlck and pmov ~= 0 then
  CGD[1]["x"] = CGD[1]["x"] + pmov
  cGlobalx = cGlobalx + pmov
  cBackgroundPos = cBackgroundPos + pmov
  if gfunc.cim <= 3 then
  CGD[1]["image"] = -3
  elseif gfunc.cim > 3 and gfunc.cim <= 6 then
  CGD[1]["image"] = 0
  else
  CGD[1]["image"] = -2
  end
  if gfunc.cim > 9 then gfunc.cim = 1 end
  gfunc.cim = gfunc.cim + 1  
  end
 end
 os.sleep(0.05)
end
end

local function screen()
 while ingame do
  if not stopDrawing then
  dmain()
  gamefps = gamefps + 1
  end
 os.sleep(0.01) 
 end
end

local someVar1
local plcmx, tenb

local function main()
local vseffdescrig, pItem, mpcktime, checkVar1, tpskp
while ingame do
someVar1 = true
local ev, p2, p3, p4, p5 = event.pull()
 if ev == "key_down" then
  if p4 == 44 then ingame = false end
  
  if (p4 == 205 or p4 == 32) and not paused and CGD[1]["x"] <= world[world.current].limitR and playerCanMove and CGD[1]["cmove"] then -- вправо
   gfunc.usepmx = false
   if keyboard.isAltDown() then
   CGD[1]["mx"] = world[world.current].limitR
   gfunc.usepmx = true  
   else
   pmov = 3
   CGD[1]["spos"] = "r"
   gfunc.keyactionmove = true
   end
  elseif (p4 == 203 or p4 == 30) and not paused and CGD[1]["x"] >= world[world.current].limitL and playerCanMove and CGD[1]["cmove"] then -- влево
   gfunc.usepmx = false
   if keyboard.isAltDown() then
   CGD[1]["mx"] = world[world.current].limitL
   gfunc.usepmx = true
   else
   pmov = -3
   CGD[1]["spos"] = "l"
   gfunc.keyactionmove = true
   end
  end
  if not paused then
   for f = 1, 6 do
	if cTarget ~= 0 and cUskills[f] ~= 0 and p4 == 1+f and cPlayerSkills[cUskills[f]][1] ~= 0 and gsd[cPlayerSkills[cUskills[f]][1]]["type"] ~= "buff" then
	 vAttackDistance = vAttackDistance or 8
	 if gfunc.roundupnum(CGD[cTarget]["x"]) > CGD[1]["x"] then
	 plcmx = gfunc.roundupnum(CGD[cTarget]["x"]) - (vAttackDistance+gsd[cPlayerSkills[cUskills[f]][1]]["distance"]) - CGD[1]["width"] + 1
	 elseif gfunc.roundupnum(CGD[cTarget]["x"]) < CGD[1]["x"] then
	 plcmx = gfunc.roundupnum(CGD[cTarget]["x"]) + CGD[cTarget]["width"] + (vAttackDistance+gsd[cPlayerSkills[cUskills[f]][1]]["distance"]) - 1
	 end	 
	 if getDistanceToId(1,cTarget) > vAttackDistance+gsd[cPlayerSkills[cUskills[f]][1]]["distance"] then
	 gfunc.usepmx = true
	 CGD[1]["mx"] = plcmx
	 plcmx = CGD[1]["x"]
	 elseif cPlayerSkills[cUskills[f]][1] ~= 0 and cPlayerSkills[cUskills[f]][3] > 0 and getDistanceToId(1,cTarget) <= vAttackDistance+gsd[cPlayerSkills[cUskills[f]][1]]["distance"] then
	 useSkill(f)
	 pmov = 0
	 plcmx = CGD[1]["x"]
	 CGD[1]["mx"] = CGD[1]["x"]
	 end
	elseif p4 == 1+f and cUskills[f] ~= 0 and cPlayerSkills[cUskills[f]][1] ~= 0 and cPlayerSkills[cUskills[f]][3] > 0 and gsd[cPlayerSkills[cUskills[f]][1]]["type"] == "buff" then
	useSkill(f)
	pmov = 0
	end
   end
  end
  if not paused and cTarget ~= 0 and CGD[cTarget]["rtype"] == "f" and p4 == 18 and getDistanceToId(1,cTarget) <= 40 then
  CGD[1]["mx"] = CGD[1]["x"]
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
  -- cDialog = dialogs[CGD[cTarget]["dialog"]]
  cDialog["im"] = 0
  cDialog = insertQuests(cTarget,cDialog)
  end
  if not pickingUp and not paused and cTarget ~= 0 and CGD[cTarget]["rtype"] == "r" and p4 == 18 and getDistanceToId(1,cTarget) <= 11 then
   if gud[CGD[cTarget]["id"]]["reqquest"] then
    for m = 1, #cUquests do
	 if cUquests[m][1] == gud[CGD[cTarget]["id"]]["reqquest"] and cUquests[m][3] ~= true then
	 gfunc.pickUpResource()
	 end
	end
   else
   gfunc.pickUpResource()
   end
  end
  if not paused and not pickingUp and cTarget ~= 0 and CGD[cTarget]["rtype"] == "c" and p4 == 18 and getDistanceToId(1,cTarget) <= 10 then
   if gud[CGD[cTarget]["id"]]["tlp"] == "r" then
   loadWorld(world[world.current].drespawn)
   elseif type(gud[CGD[cTarget]["id"]]["tlp"]) == "table" then
   teleport(gud[CGD[cTarget]["id"]]["tlp"][2],gud[CGD[cTarget]["id"]]["tlp"][1])
   end
  end
  if not paused and p4 == 46 then
  paused = true
  cCnsScroll = math.floor(#consDataR/4)
  cWindowTrd = "console"
  end
  if not paused and cWindowTrd == nil and p4 == 48 then paused = true; gfunc.openInventory() elseif cWindowTrd == "inventory" then paused = false; cWindowTrd = nil; iconImageBuffer = {} end
  if not paused and cWindowTrd == nil then   
   for f = 1, #inventory["bag"] do
	if inventory["bag"][f][1] > 0 and inventory["bag"][f][2] > 0 and gid[inventory["bag"][f][1]]["type"] == "potion" and CGD[1]["lvl"] >= gid[inventory["bag"][f][1]]["reqlvl"] then
	 if p4 == 20 and gid[inventory["bag"][f][1]]["subtype"] == "health" then
	 addPlayerEffect(1,gid[inventory["bag"][f][1]]["lvl"])
	 inventory["bag"][f][2] = inventory["bag"][f][2] - 1
	 break
	 elseif p4 == 21 and gid[inventory["bag"][f][1]]["subtype"] == "mana" then
	 addPlayerEffect(2,gid[inventory["bag"][f][1]]["lvl"])
	 inventory["bag"][f][2] = inventory["bag"][f][2] - 1
	 break	  
	 end
	end
   end
  end
  
 end
 if ev == "key_up" then
  -- if ( p4 == 205 or p4 == 32 or p4 == 203 or p4 == 30 ) and not keyboard.isAltDown()then
  -- if not pickingUp then CGD[1]["image"] = 0 end
  -- gfunc.usepmx = false
  -- pmov = 0
  -- end
 end
 if ev == "touch" then
  if cWindowTrd == nil and not paused then
   if clicked(p3,p4,1,4,25,4) then
   svxpbar = true
   else
   svxpbar = false
   end
  end
 if cWindowTrd == nil and cTarget ~= 0 and p5 == 0 and gud[CGD[cTarget]["id"]]["rtype"] ~= "r" and clicked(p3,p4,60,5,71,5) then showTargetInfo = true 
 elseif cWindowTrd == nil and cTarget ~= 0 and p5 == 0 and not clicked(p3,p4,60,5,71,5) then showTargetInfo = false end
 if p5 == 0 and clicked(p3,p4,1,1,25,5) and cWindowTrd == nil and not paused then cTarget = 1 end
  if p5 == 0 and clicked(p3,p4,156,2,158,3) and cWindowTrd == nil then
  cWindowTrd = "pause"
  paused = true
  elseif p5 == 0 and clicked(p3,p4,156,2,158,3) and cWindowTrd == "pause" then 
  cWindowTrd = nil 
  paused = false
  end
  
  if p5 == 0 and not paused and not clicked(p3,p4,1,1,160,8) then target(p3,p4) end
  
  if p5 == 0 and not paused then
   vseffdescrig = false
   for f = 1, #CGD[1]["effects"] do
    if clicked(p3,p4,f*4-3,7,f*4,8) then
	vshowEffDescr, sEffdx, sEffdy = f, p3, p4+1
	vseffdescrig = true
	break
	end
   end
  if not vseffdescrig then vshowEffDescr = 0 end
  end
  if p5 == 0 and cWindowTrd == "pause" then
   for f = 1, #fPauselist do
    if clicked(p3,p4,1,4+f*4-3,30,3+f*4) then
	gfunc.fPauseMenuAction[f]()
	p3, p4 = 0, 0
	break
	end
   end
  elseif cWindowTrd == "inventory" then
   if clicked(p3,p4,152,1,159,1) then
   cWindowTrd = "pause"
   iconImageBuffer = {}
   end
   if showItemData and invcTargetItem ~= 0 and clicked(p3,p4,2,47,16,47) then
   if inventory["bag"][invcTargetItem][1] >= 200 then gid[inventory["bag"][invcTargetItem][1]] = nil end
   inventory["bag"][invcTargetItem] = {0,0}  
   iconImageBuffer[invcTargetItem] = nil
   showItemData, invcTargetItem = false, 0
   end
  local fbParam = true
  local nwitemuwr, xps, yps
   for f = 1, 4 do
    for i = 1, 5 do
    xps, yps = 2+i*21-21, 3+f*11-11
    local formula = (f-1)*5+i
	 if inventory["bag"][formula][1] ~= 0 and inventory["bag"][formula][2] ~= 0 then
      if clicked(p3,p4,xps,yps,xps+19,yps+9) then
	  pItem = gid[inventory["bag"][formula][1]]
	   if p5 == 0 then
	   invcTItem = inventory["bag"][formula][1]
	   invcTargetItem = formula
	   invTItem = inventory["bag"][formula][2]
	   showItemData = true
       invIdx, invIdy = p3, p4
	   fbParam = false
	   break
	   elseif p5 == 1 and gid[inventory["bag"][formula][1]] then
	    -- armor
		if pItem["type"] == "armor" and CGD[1]["lvl"] >= pItem["reqlvl"] then
		 if inventory["weared"][pItem["subtype"]] == 0 then
	     inventory["weared"][pItem["subtype"]] = inventory["bag"][formula][1]
		 iconImageBuffer[pItem["subtype"]] = image.load(dir.."itempic/"..aItemIconsSpr[gid[inventory["bag"][formula][1]]["icon"]]..".pic")
		 inventory["bag"][formula][1] = 0
		 inventory["bag"][formula][2] = 0
		  if iconImageBuffer[formula] ~= nil then
		  iconImageBuffer[formula] = nil
		  end
	     else
		 nwitemuwr = inventory["weared"][pItem["subtype"]]
		 inventory["weared"][pItem["subtype"]] = inventory["bag"][formula][1]
		 iconImageBuffer[gid[nwitemuwr]["subtype"]] = image.load(dir.."itempic/"..aItemIconsSpr[gid[inventory["bag"][formula][1]]["icon"]]..".pic")
		 inventory["bag"][formula][1] = nwitemuwr
		 inventory["bag"][formula][2] = 1
		 iconImageBuffer[formula] = image.load(dir.."itempic/"..aItemIconsSpr[gid[nwitemuwr]["icon"]]..".pic")
		 end
		-- weapon
		elseif pItem["type"] == "weapon" and CGD[1]["lvl"] >= pItem["reqlvl"] then
		 if inventory["weared"]["weapon"] == 0 then
	     inventory["weared"]["weapon"] = inventory["bag"][formula][1]
		 iconImageBuffer["weapon"] = image.load(dir.."itempic/"..aItemIconsSpr[gid[inventory["bag"][formula][1]]["icon"]]..".pic")
		 inventory["bag"][formula][1] = 0
		 inventory["bag"][formula][2] = 0
		  if iconImageBuffer[formula] ~= nil then
		  iconImageBuffer[formula] = nil
		  end		 
		 else
		 nwitemuwr = inventory["weared"]["weapon"]
		 inventory["weared"]["weapon"] = inventory["bag"][formula][1]
		 iconImageBuffer["weapon"] = image.load(dir.."itempic/"..aItemIconsSpr[gid[inventory["bag"][formula][1]]["icon"]]..".pic")
		 inventory["bag"][formula][1] = nwitemuwr
		 inventory["bag"][formula][2] = 1
		 iconImageBuffer[formula] = image.load(dir.."itempic/"..aItemIconsSpr[gid[nwitemuwr]["icon"]]..".pic")
		 end
		-- potion
		elseif pItem["type"] == "chest" then
		 for t = 1, #pItem["props"] do
		  if 1000-pItem["props"][t][3]*10 <= gfunc.random(1,1000) then
		  addItem(pItem["props"][t][1],pItem["props"][t][2])
		  break
		  end
		 end
        addsmsg3(unicode.sub(os.date(), #os.date()-7, #os.date()).." Использован предмет "..pItem["name"])
		inventory["bag"][formula][2] = inventory["bag"][formula][2] - 1
		elseif pItem["type"] == "tlp" then
		CGD[1]["x"], cGlobalx, cBackgroundPos = 1, 1, 1
		addsmsg3(unicode.sub(os.date(), #os.date()-7, #os.date()).." Использован предмет "..pItem["name"])
		inventory["bag"][formula][2] = inventory["bag"][formula][2]	- 1	
		elseif pItem["type"] == "potion" and CGD[1]["lvl"] >= pItem["reqlvl"] then
		 if pItem["subtype"] == "health" then
		 addPlayerEffect(1,pItem["lvl"])
		 inventory["bag"][formula][2] = inventory["bag"][formula][2] - 1
		 elseif pItem["subtype"] == "mana" then
		 addPlayerEffect(2,pItem["lvl"])
		 inventory["bag"][formula][2] = inventory["bag"][formula][2] - 1
		 end
		addsmsg3(unicode.sub(os.date(), #os.date()-7, #os.date()).." Использован предмет "..pItem["name"])
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
     if inventory["weared"][wItemTypes[formula]] ~= 0 then
      if clicked(p3,p4,xps,yps,xps+19,yps+9) then
	   if p5 == 0 then
	   invcTItem = inventory["weared"][wItemTypes[formula]]
	   invTItem = 1
	   showItemData = true
       invIdx, invIdy = p3, p4
	   fbParam = false
	   break
	   else
       nwitemuwr = addItem(inventory["weared"][wItemTypes[formula]],1)
	   iconImageBuffer[nwitemuwr] = image.load(dir.."itempic/"..aItemIconsSpr[gid[inventory["weared"][wItemTypes[formula]]]["icon"]]..".pic")
	   inventory["weared"][wItemTypes[formula]] = 0
	   	if iconImageBuffer[wItemTypes[formula]] ~= nil then
		iconImageBuffer[wItemTypes[formula]] = nil
		end	   
	   nwitemuwr = nil
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
 gfunc.playerRefreshVar()
 elseif cWindowTrd == "dialog" then
   for f = 1, #cDialog do
    if cDialog[f]["action"] == "getquest" and gqd[cDialog[f]["do"]]["comp"] == true then
    table.remove(cDialog[f])
    end
   end
   for f = 1, #cDialog do
    if p5 == 0 and clicked(p3,p4,14,25+f,58,25+f) then
	 if cDialog[f]["action"] == "close" then
	 cWindowTrd = nil
	 cDialog = nil
	 paused = false
	 elseif cDialog[f]["action"] == "trade" then
	 gameTradew = loadfile(dir.."data/trade.data")(cDialog[f]["do"])
	 tradew.sect = 1
	 cWindowTrd = "tradeWindow"
	 elseif cDialog[f]["action"] == "craft" then
	 gameCraftw = loadfile(dir.."data/manufacturing.data")(cDialog[f]["do"])
	 craftw.sect = 1
	 cWindowTrd = "craftWindow"
	 elseif cDialog[f]["action"] == "dialog" then
	 cDialog = cDialog[f]["do"]
	 elseif cDialog[f]["action"] == "qdialog" and CGD[1]["lvl"] >= gqd[cDialog[f]["q"]]["minlvl"] then
	 cDialog = cDialog[f]["do"]
	 elseif cDialog[f]["action"] == "getquest" and gqd[cDialog[f]["do"]]["comp"] == 0 and CGD[1]["lvl"] >= gqd[cDialog[f]["do"]]["minlvl"] then
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
		  for k = 1, #inventory["bag"] do
		   if inventory["bag"][k][1] == gqd[cDialog[f]["do"]]["targ"][l][1] and inventory["bag"][k][2] >= gqd[cDialog[f]["do"]]["targ"][l][2] then
		   inventory["bag"][k][2] = inventory["bag"][k][2] - gqd[cDialog[f]["do"]]["targ"][l][2]
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
		 addsmsg1("Необходимо "..#gqd[cDialog[f]["do"]]["qreward"]["item"].." ячеек в инвентаре")
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
	    table.remove(cUquests,t)
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
		  addsmsg1("Задание '"..gqd[gqd[cDialog[f]["do"]]["value"]]["name"].."' получено") 
		  gqd[gqd[cDialog[f]["do"]]["value"]]["qstgve"] = CGD[cTarget]["id"]
		  gqd[gqd[cDialog[f]["do"]]["value"]]["comp"] = false
		  table.remove(cUquests,t)
	      cWindowTrd = nil
	      cDialog = nil
	      paused = false
		  break
		 end
		end
	   end
	  end
	 elseif cDialog[f]["action"] == "setWorld" and CGD[1]["lvl"] >= cDialog[f]["reqlvl"] then
	 teleport(cDialog[f]["do"][2] or 1,cDialog[f]["do"][1] or 1)
	 end
	end
   end
   if clicked(p3,p4,61,11,61,11) then
   cWindowTrd = nil
   cDialog = nil
   paused = false   
   end
  elseif cWindowTrd == "quests" then
   if p5 == 0 and clicked(p3,p4,122,12,129,12) then
   cWindowTrd = "pause"
   end
   for f = 1, #cUquests do
    if cUquests[f] ~= nil and clicked(p3,p4,32,15+f,60,15+f) then
	someVar1 = false
	targetQuest = f
	break
	end
   if not someVar1 then targetQuest = 0 end
   end
  elseif cWindowTrd == "console" then
   if p5 == 0 and clicked(p3,p4,109,10,109,10) then
   cWindowTrd = nil
   paused = false
   end
  elseif cWindowTrd == "pstats" then
  if p5 == 0 and clicked(p3,p4,122,8,129,8) then cWindowTrd = "pause" end
   for t = 1, 3 do
    if p5 == 0 and charPoints > 0 and clicked(p3,p4,pstatspntrs.x+17,pstatspntrs.y+t,pstatspntrs.x+20,pstatspntrs.y+t) then
	chPointsAss[t] = chPointsAss[t] + 1
	charPoints = charPoints - 1
	chPointsAss[4] = chPointsAss[4] + 1
	elseif p5 == 0 and charPoints > 0 and clicked(p3,p4,pstatspntrs.x+22,pstatspntrs.y+t,pstatspntrs.x+25,pstatspntrs.y+t) and chPointsAss[t] > 0 then
	chPointsAss[t] = chPointsAss[t] - 1
	charPoints = charPoints + 1
	chPointsAss[4] = chPointsAss[4] - 1	
	end
   end
   if p5 == 0 and clicked(p3,p4,pstatspntrs.x+28,pstatspntrs.y+1,pstatspntrs.x+34,pstatspntrs.y+1) then
   intelligence = intelligence + chPointsAss[1]
   strength = strength + chPointsAss[2]
   survivability = survivability + chPointsAss[3]
   chPointsAss = {0,0,0,0}
   gfunc.playerRefreshVar()
   elseif p5 == 0 and chPointsAss[4] > 0 and clicked(p3,p4,pstatspntrs.x+28,pstatspntrs.y+3,pstatspntrs.x+34,pstatspntrs.y+3) then
   charPoints = charPoints + chPointsAss[4]
   chPointsAss = {0,0,0,0}
   gfunc.playerRefreshVar()
   end
  elseif cWindowTrd == "tradeWindow" then
   if p5 == 0 and clicked(p3,p4,152,1,159,1) then
    tradew = {
	titem = 0,
	titemcount = 1,
	sect = 1,
	tScrl = 1,
	torg = 1,
	asmt = {},
	}
   cWindowTrd = nil
   cDialog = nil
   paused = false
   end
    if p5 == 0 and tradew.torg == 1 and tradew.titem == 0 and clicked(p3,p4,119,2,136,4) then 
	tradew.torg = 2 
	tradew.titem = 0
    elseif p5 == 0 and tradew.torg == 2 and clicked(p3,p4,119,2,136,4) then
	tradew.torg = 1 
	tradew.titem = 0
	tradew.titemcount = 1
    iconImageBuffer = {}
	end
   if tradew.torg == 2 then
    for f = 1, #tradew.asmt do
	 if p5 == 0 and clicked(p3,p4,2,5+f,85,5+f) then
	 iconImageBuffer[1] = image.load(dir.."itempic/"..aItemIconsSpr[gid[tradew.asmt[f][1]]["icon"]]..".pic")
	 tradew.titem = f
	 tradew.titemcount = 1
	 end
	end
	if tradew.titem > 0 then
	 if p5 == 0 then
	  if clicked(p3,p4,119,8,119,8) and tradew.titemcount < tradew.asmt[tradew.titem][2] then
	  tradew.titemcount = tradew.titemcount + 1
	  elseif clicked(p3,p4,126,8,126,8) and tradew.titemcount > 1 then
	  tradew.titemcount = tradew.titemcount - 1
	  elseif clicked(p3,p4,121,9,125,9) then
	  tradew.titemcount = tradew.asmt[tradew.titem][2]
	  end
	  if clicked(p3,p4,130,7,145,9) then
	   for d = 1, #inventory["bag"] do
		if inventory["bag"][d][1] == tradew.asmt[tradew.titem][1] then 
		cCoins = cCoins + tradew.titemcount*gid[tradew.asmt[tradew.titem][1]]["cost"]
		inventory["bag"][d][2] = inventory["bag"][d][2] - tradew.titemcount
		for h = 1, #inventory["bag"] do if inventory["bag"][h][2] <= 0 then inventory["bag"][h][1] = 0 end end
		iconImageBuffer = {}
		tradew.titem = 0
		tradew.titemcount = 1
	    break
		end
	   end
	  end
	 end
	end
   elseif tradew.torg == 1 and tradew.titem == 0 then
    for c = 1, #gameTradew do
	 if p5 == 0 and clicked(p3,p4,2+c*26-26, 2, 2+c*25, 2) then
	 tradew.sect = c
	 break
	 end
	end
	for c = 1, math.min(#gameTradew[tradew.sect], 24) do
     if clicked(p3,p4,2,5+c*2-2,160,5+c*2) then
	 tradew.titem = c+4*tradew.tScrl-4
	 iconImageBuffer = {[1]=image.load(dir.."itempic/"..aItemIconsSpr[gid[gameTradew[tradew.sect][tradew.titem]["item"]]["icon"]]..".pic")}
	 break
	 end
    end
   elseif tradew.torg == 1 and tradew.titem > 0 then
    if p5 == 0 and gid[gameTradew[tradew.sect][tradew.titem]["item"]]["stackable"] and tradew.titemcount < 100 and clicked(p3,p4,math.floor(80-smw/2)+13, math.floor(25-smh/2)+3,math.floor(80-smw/2)+13, math.floor(25-smh/2)+3) then -- +
    tradew.titemcount = tradew.titemcount + 1
    elseif p5 == 0 and tradew.titemcount > 1 and clicked(p3,p4,math.floor(80-smw/2)+16+#tostring(tradew.titemcount), math.floor(25-smh/2)+3,math.floor(80-smw/2)+16+#tostring(tradew.titemcount), math.floor(25-smh/2)+3) then -- -
    tradew.titemcount = tradew.titemcount - 1
    end
    -- купить
	if clicked(p3,p4,math.floor(80-smw/2),math.floor(25-smh/2)+smh,math.floor(80-smw/2)+smw,math.floor(25-smh/2)+smh+3) and cCoins >= tradew.titemcount*gameTradew[tradew.sect][tradew.titem]["cost"] then
	cCoins = cCoins - tradew.titemcount*gameTradew[tradew.sect][tradew.titem]["cost"]
	addItem(gameTradew[tradew.sect][tradew.titem]["item"],tradew.titemcount)
	tradew.titem = 0
	tradew.titemcount = 1	
	iconImageBuffer = {}
	end
	-- закрыть
	if clicked(p3,p4,math.floor(80-smw/2)+smw-2, math.floor(25-smh/2),math.floor(80-smw/2)+smw-2, math.floor(25-smh/2)) then
	tradew.titem = 0
	tradew.titemcount = 1
	iconImageBuffer = {}
	end
   end
  elseif cWindowTrd == "craftWindow" then
   if p5 == 0 and clicked(p3,p4,152,1,159,1) then
    craftw = {
	titem = 0,
	titemcount = 1,
	sect = 1,
	tScrl = 1
	}
   cWindowTrd = nil
   cDialog = nil
   paused = false
   end  
   if craftw.titem == 0 then
    for c = 1, #gameCraftw do
	 if p5 == 0 and clicked(p3,p4,2+c*26-26, 2, 2+c*25, 2) then
	 craftw.sect = c
	 break
	 end
	end
	for c = 1, math.min(#gameCraftw[craftw.sect], 24) do
     if clicked(p3,p4,2,5+c*2-2,160,5+c*2) then
	 craftw.titem = c+4*tradew.tScrl-4
	 iconImageBuffer[1] = image.load(dir.."itempic/"..aItemIconsSpr[gid[gameCraftw[craftw.sect][craftw.titem]["item"]]["icon"]]..".pic")
	 break
	 end
    end
   else
    if p5 == 0 and gid[gameCraftw[craftw.sect][craftw.titem]["item"]]["stackable"] and craftw.titemcount < 100 and clicked(p3,p4,math.floor(80-bmw/2)+13, math.floor(25-bmh/2)+3,math.floor(80-bmw/2)+13, math.floor(25-bmh/2)+3) then
    craftw.titemcount = craftw.titemcount + 1
    elseif p5 == 0 and craftw.titemcount > 1 and clicked(p3,p4,math.floor(80-bmw/2)+16+#tostring(craftw.titemcount), math.floor(25-bmh/2)+3,math.floor(80-bmw/2)+16+#tostring(craftw.titemcount), math.floor(25-bmh/2)+3) then
    craftw.titemcount = craftw.titemcount - 1
    end
    if clicked(p3,p4,math.floor(80-bmw/2),math.floor(25-bmh/2)+bmh,math.floor(80-bmw/2)+bmw,math.floor(25-bmh/2)+bmh+3) and cCoins >= craftw.titemcount*gameCraftw[craftw.sect][craftw.titem]["cost"] then
	 -- нажатие на кнопку 'создать предмет'
	 checkVar1 = true
	 for i = 1, #gameCraftw[craftw.sect][craftw.titem]["recipe"] do
	  if checkItemInBag(gameCraftw[craftw.sect][craftw.titem]["recipe"][i][1]) < gameCraftw[craftw.sect][craftw.titem]["recipe"][i][2]*craftw.titemcount then
	  checkVar1 = false
	  end
	 end
	if gameCraftw[craftw.sect][craftw.titem]["cost"] > cCoins then checkVar1 = false end
	 if checkVar1 then
	  for d = 1, #gameCraftw[craftw.sect][craftw.titem]["recipe"] do
	   for i = 1, #inventory["bag"] do
	    if inventory["bag"][i][1] == gameCraftw[craftw.sect][craftw.titem]["recipe"][d][1] then
	    inventory["bag"][i][2] = inventory["bag"][i][2] - gameCraftw[craftw.sect][craftw.titem]["recipe"][d][2]*craftw.titemcount
	    if inventory["bag"][i][2] == 0 then inventory["bag"][i][1] = 0 end
		break
		end
	   end
	  end
	 local Citem
	 for d = 1, craftw.titemcount do
	  Citem = gameCraftw[craftw.sect][craftw.titem]["item"]
	  cCoins = cCoins - gameCraftw[craftw.sect][craftw.titem]["cost"]
       if Citem ~= nil and 10^10-gameCraftw[craftw.sect][craftw.titem]["chance"]*10^10 <= gfunc.random(1,10^10) then
       if 10^10-(gameCraftw[craftw.sect][craftw.titem]["achance"] or 0)*10^10 <= gfunc.random(1,10^10) then Citem = createNewItem(Citem) end
       addItem(Citem,1)
	   end
	  Citem = nil
	  end
	 craftw.titem = 0
	 craftw.titemcount = 1	 
	 iconImageBuffer = {}
	 end
	end
	if clicked(p3,p4,math.floor(80-bmw/2)+bmw-2, math.floor(25-bmh/2),math.floor(80-bmw/2)+bmw-2, math.floor(25-bmh/2)) then
	craftw.titem = 0
	craftw.titemcount = 1
	iconImageBuffer = {}
	end
   -------
   end
  elseif cWindowTrd == "ydd" then
   for e = 1, #ydd do
    if clicked(p3,p4,160/2-ydd.w/2,50/2-ydd.h/2+2+e,160/2-ydd.w/2+ydd.w-1,50/2-ydd.h/2+2+e) then
    pcall(ydd[e].f)
    end
   end
  elseif cWindowTrd == "skillsWindow" then
  if clicked(p3,p4,skillstr.x+112,skillstr.y,skillstr.x+119,skillstr.y) then cWindowTrd = "pause" end
   for e = 1, #cPlayerSkills do
    if p5 == 0 and clicked(p3,p4,skillstr.x+1, skillstr.y+2+e*3-3, skillstr.x+50, skillstr.y+2+e*3) then
    skillstr.targ = e
    end
   end
   if skillstr.targ > 0 then
    if p5 == 0 and clicked(p3,p4,skillstr.x+70,skillstr.y+35,skillstr.x+84,skillstr.y+37) and cPlayerSkills[skillstr.targ][3] < #gsd[cPlayerSkills[skillstr.targ][1]]["manacost"] then
    local blbl, checkv1, checkv2 = gsd[cPlayerSkills[skillstr.targ][1]], true, {}
	 if blbl["reqlvl"] then
	  if blbl["reqlvl"][cPlayerSkills[skillstr.targ][3]+1] > CGD[1]["lvl"] then 
	  checkv1 = false 
	  end	 
	 end
	 if blbl["reqcn"] then
	  if blbl["reqcn"][cPlayerSkills[skillstr.targ][3]+1] > cCoins then 
	  checkv1 = false 
	  else
	  checkv2.c = true
	  end	 
	 end
	 if blbl["reqitem"] then
	  if checkItemInBag(blbl["reqitem"][cPlayerSkills[skillstr.targ][3]+1][1]) < blbl["reqitem"][cPlayerSkills[skillstr.targ][3]+1][2] then
	  checkv1 = false 
	  else
	  checkv2.o, checkv2.i = checkItemInBag(blbl["reqitem"][cPlayerSkills[skillstr.targ][3]+1][1])
	  end	 
	 end
	 if checkv1 == true then
	  if checkv2.c then cCoins = cCoins - blbl["reqcn"][cPlayerSkills[skillstr.targ][3]+1] end
	  if checkv2.i then
	   for y = 1, #inventory["bag"] do
	    if inventory["bag"][y][1] == checkv2.i and inventory["bag"][y][2] >= checkv2.o then
		inventory["bag"][y][2] = inventory["bag"][y][2] - blbl["reqitem"][cPlayerSkills[skillstr.targ][3]+1][2]
		break
		end
	   end
	  end
	 cPlayerSkills[skillstr.targ][3] = cPlayerSkills[skillstr.targ][3] + 1
	 end
	blbl, checkv1, checkv2 = nil, nil, nil
	end
	blbl = false
    for p = 1, #cUskills do
	 if p5 == 0 and cPlayerSkills[skillstr.targ][1] > 1 and clicked(p3,p4,skillstr.x+105,skillstr.y+6+4*p-4,skillstr.x+115,skillstr.y+6+4*p-1) and cPlayerSkills[skillstr.targ][3] > 0 then
	  for n = 1, #cUskills do
	  if cUskills[n] == cPlayerSkills[skillstr.targ][1] then cUskills[n] = 0 end
      end
	 cUskills[p+1] = cPlayerSkills[skillstr.targ][1]
	 blbl = true
	 break
	 end
	end
   end
  end
 end
 if ev == "scroll" then
  if cWindowTrd == "console" then
   if clicked(p3,p4,50,10,109,42) and p5 == 1 and cCnsScroll > 1 then
   cCnsScroll = cCnsScroll - 1
   elseif clicked(p3,p4,50,10,109,42) and p5 == -1 and math.ceil(cCnsScroll*4) < #consDataR then
   cCnsScroll = cCnsScroll + 1
   end
  end
 end
 end
end

thread.create(main)
thread.create(screen)
thread.create(functionPS)
thread.create(funcP4)
thread.create(funcP10)
thread.create(funcP20)

thread.waitForAll()

gpu.setBackground(0x000000)
gpu.setForeground(0xFFFFFF)
term.clear()
term.setCursor(1,1)
io.write("Wirthe16 game "..TextVersion)
