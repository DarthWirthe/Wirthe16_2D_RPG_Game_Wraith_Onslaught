local shell = require("shell")
local term = require("term")
local event = require("event")
local computer = require("computer")
local unicode = require("unicode")
local fs = require("filesystem")
local buffer = require("doubleBuffering")
local image = require("image")
local component = require("component")
local gpu = component.gpu
gpu.setResolution(160,50)

local useos = true
local sVarMenu1 = false


local function drawTime()
local ctime = unicode.sub(os.date(), 1, -4)
buffer.text(buffer.screen.width - unicode.len(ctime), 1, 0xFFFFFF, ctime)
end

local function clicked(x,y,x1,y1,x2,y2)
 if x >= x1 and x <= x2 and y >= y1 and y <= y2 then 
 return true 
 end    
 return false
end

local dfolders = {
 "/home/desktop/",

}

for f = 1, #dfolders do
 if not fs.exists(dfolders[f]) then fs.makeDirectory(dfolders[f]) end
end

local sArrayMenu1 = {
 "Устройство",
 "function = nil",
 "OpenOS Shell",
 "Информация",
 "Перезагрузка",
 "Выключение",
}

local function funcMenu1()
local x, y, w, h, color, nazvanie = 1, 2, 25, 10, 0x4499FF, "test"
buffer.square(x, y, w, h, color, 0xFFFFFF, " ")
local ramka1 = "┌"..string.rep("─",w-2).."┐"
local ramka2 = "│"..string.rep(" ",w-2).."│"
local ramka3 = "└"..string.rep("─",w-2).."┘"
buffer.text(x,y,0xFFFFFF,ramka1)
 for f = 1, h-2 do
 buffer.text(x,y+f,0x0000FF,ramka2)
 end
buffer.text(x,y+h-1,0xFFFFFF,ramka3)
 for f = 1, #sArrayMenu1 do
 buffer.text(x+1,y+1+f,0xFFFFFF,sArrayMenu1[f])
 end
end

local function getFileList(path)
local list = fs.list(path)
local array = {}
 for file in list do
 table.insert(array, file)
 end
list = nil
return array
end

local folder = {}

folder.currentPath = nil
folder.cScroll = 1
folder.fav = {}
folder.cProp = {x = 25, y = 7, w = 110, h = 32, favWidth = 20}

function folder.scroll(par)
local flist = getFileList(folder.currentPath)
local svh = math.min(math.ceil(#flist/math.ceil((folder.cProp.w-folder.cProp.favWidth)/14)),math.floor(folder.cProp.h/7)) 
 if folder.cScroll > 1 and par == -1 then folder.cScroll = folder.cScroll - 1
 elseif svh >= math.floor(folder.cProp.h/7) and folder.cScroll <= svh and par == 1 then folder.cScroll = folder.cScroll + 1
 end
end

function folder.getPrevPath(wPath)
 if wPath ~= "/" and wPath ~= nil then
 local npath = string.sub(wPath,1,#wPath-#fs.name(wPath)-1)
 return npath
 end
end

function folder.getType(wPath)
local ctype
 if fs.isDirectory(wPath) then
 ctype = "folder"
 else
 local razh = string.sub(wPath,#wPath-3,#wPath)
  if razh == ".lua" then ctype = "lua"
  elseif razh == ".txt" then ctype = "txt"
  elseif razh == ".pic" then ctype = "pic"
  elseif razh == ".sht" then ctype = "shortcut"
  elseif razh == ".bdl" then ctype = "bdl"
  else ctype = "none"
  end
 end
return ctype
end

function folder.openFolder(wPath)
local x, y, scl = folder.cProp.x, folder.cProp.y, folder.cScroll
buffer.square(x, y, folder.cProp.w, folder.cProp.h, 0xFFFFFF, 0xFFFFFF, " ")
buffer.square(x, y, folder.cProp.favWidth, folder.cProp.h, 0xAAAAAA, 0xFFFFFF, " ")
buffer.square(x, y, folder.cProp.w, 2, 0x3399FF, 0xFFFFFF, " ")
buffer.text(x,y,0xFFFFFF,wPath)
buffer.text(x+2,y+3,0x000000,"Избранное")
 for f = 1, #folder.fav do
 buffer.text(x+3,y+3+f,0x454545,folder.fav[f]["name"])
 end
buffer.square(x+folder.cProp.w-5, y, 5, 1, 0xFF0000, 0xFFFFFF, " ")
buffer.text(x+folder.cProp.w-3,y,0xFFFFFF,"X")
buffer.text(x+2,y+1,0xFFFFFF,"◄─")
local flist = getFileList(wPath)
local svw = math.floor((folder.cProp.w-folder.cProp.favWidth)/14)
local svh = math.min(math.ceil(#flist/svw),math.floor(folder.cProp.h/7))
local xps, yps
local cftype, finpath 
 for f = 1, svh do
  for i = 1, svw do
   xps, yps = x+folder.cProp.favWidth+2+i*14-14, y+8+f*7-7
   local formula = (f-1+(scl-1))*svw+i
   if flist[formula] then
   	if string.sub(wPath,#wPath,#wPath) == "/" and not wPath ~= "/" then finpath = wPath..flist[formula]
	else finpath = wPath.."/"..flist[formula]
	end 
   cftype = folder.getType(finpath)
	if cftype == "folder" then
    buffer.square(xps+2, yps-5, 6, 5, 0xFFFF00, 0xFFFFFF, " ")
    elseif cftype == "lua" then
	buffer.image(xps+2, yps-5, image.load("/home/nfimages/luaico.pic"))
	elseif cftype == "pic" then
	buffer.image(xps+2, yps-5, image.load("/home/nfimages/imageico.pic"))
	elseif cftype == "shortcut" then
	buffer.square(xps+2, yps-5, 6, 5, 0x9E9E9E, 0xFFFFFF, " ")
	buffer.set(xps+2,yps-1,0x888888, 0x000000, "^")
	elseif cftype == "bdl" then
	buffer.image(xps+2, yps-5, image.load("/home/nfimages/bdlico.pic"))
	else buffer.square(xps+2, yps-5, 6, 5, 0x9D9D9D, 0xFFFFFF, " ")
	end
   buffer.text(xps, yps, 0x454545, string.sub(flist[formula],1,12))
   buffer.text(xps,yps+1,0x454545, string.sub(flist[formula],13,24))
   end
  end
 end
end

function folder.addFav(wPath)
 if wPath ~= "/" then
 folder.fav[#folder.fav+1] = {}
 folder.fav[#folder.fav]["name"] = string.sub(fs.name(wPath),1,folder.cProp.favWidth-3)
 folder.fav[#folder.fav]["path"] = wPath
 end
end

function folder.getShortcutPath(wPath)
local shortcut = fs.open(wPath,"r")
local data = shortcut:read(fs.size(wPath))
shortcut:close()
return data
end

local function gethddinfo()
local massiv = {}
 for address in component.list("filesystem") do
 local proxy = component.proxy(address)
  if proxy.address ~= computer.tmpAddress() and proxy.getLabel() ~= "internet" then
  local isFloppy, spaceTotal = false, math.floor(proxy.spaceTotal() / 1024)
  if spaceTotal < 600 then isFloppy = true end
  table.insert(massiv, {
  ["spaceTotal"] = spaceTotal,
  ["spaceUsed"] = math.floor(proxy.spaceUsed() / 1024),
  ["label"] = proxy.getLabel(),
  ["address"] = proxy.address,
  ["isReadOnly"] = proxy.isReadOnly(),
  ["isFloppy"] = isFloppy,
  })
  end
 end
return massiv
end

local osFunction = {}
osFunction.cWindow = nil
osFunction.osInfoWindowProp = {x = 40, y = 7, w = 80, h = 26}



function osFunction.osInfoWindow()
local hddinfo = gethddinfo()
local massivtexta = {
"       Информация",
" Версия Slipper OS: test 0.107",
" Жесткий диск: "..hddinfo[1]["spaceUsed"].." / "..hddinfo[1]["spaceTotal"],
" Память (RAM): "..tostring(math.ceil(computer.totalMemory()/1048576)).." MB",
" ",
" Используемые библиотеки:",
" DoubleBuffering API; Image API",
}
local x, y, w, h = osFunction.osInfoWindowProp.x, osFunction.osInfoWindowProp.y, osFunction.osInfoWindowProp.w, osFunction.osInfoWindowProp.h
buffer.square(x, y, w, h, 0xFFFFFF, 0xFFFFFF, " ")
buffer.square(x, y, w, 2, 0x3399FF, 0xFFFFFF, " ")
buffer.text(x,y,0xFFFFFF," Свойства системы")
buffer.square(x+w-5, y, 5, 1, 0xFF0000, 0xFFFFFF, " ")
buffer.text(x+w-3,y,0xFFFFFF,"X")
 for f = 1, #massivtexta do
 buffer.text(x+1,y+10+f,0x000000,massivtexta[f])
 end
end

local function desktopIcons()
local x, y, wPath = 1, 2, "/home/desktop"
local flist = getFileList("/home/desktop")
local svw = math.floor(160/14)
local svh = math.min(math.ceil(#flist/svw),math.floor(40/7))
local xps, yps
local cftype, filename
 for f = 1, svh do
  for i = 1, svw do
   xps, yps = x+2+i*14-14, y+8+f*7-7
   local formula = (f-1)*svw+i
   if flist[formula] then
    if string.sub(wPath,#wPath,#wPath) == "/" and not wPath ~= "/" then finpath = wPath..flist[formula]
	else finpath = wPath.."/"..flist[formula]
	end 
   cftype = folder.getType(finpath)
	if cftype == "folder" then
    buffer.square(xps+2, yps-5, 6, 5, 0xFFFF00, 0xFFFFFF, " ")
    elseif cftype == "lua" then
	buffer.image(xps+2, yps-5, image.load("/home/nfimages/luaico.pic"))
	elseif cftype == "pic" then
	buffer.image(xps+2, yps-5, image.load("/home/nfimages/imageico.pic"))
	elseif cftype == "shortcut" then
	buffer.square(xps+2, yps-5, 6, 5, 0x9E9E9E, 0xFFFFFF, " ")
	buffer.set(xps+2,yps-1,0x888888, 0x000000, "^")
	elseif cftype == "bdl" then
	buffer.image(xps+2, yps-5, image.load("/home/nfimages/bdlico.pic"))	
	else buffer.square(xps+2, yps-5, 6, 5, 0x9D9D9D, 0xFFFFFF, " ")
	end
    filename = flist[formula]
	if cftype == "shortcut" then filename = string.sub(filename,1,#filename-4) end
   buffer.text(xps, yps, 0x454545, string.sub(filename,1,12))
   buffer.text(xps,yps+1,0x454545, string.sub(filename,13,24))
   end
  end
 end
end

local function dclear(color)
buffer.clear(color)
buffer.draw()
end

local function executeFile(wPath)
local execStartTime = os.time()
dclear(0xFFFFFF)
term.setCursor(1, 1)
shell.execute(wPath)
local sExecfTime = (os.time()-execStartTime)/20
local tSec, tMin, tHour, sSec, sMin, sHour = 0, 0, 0, "", "", ""
tHour = math.floor(sExecfTime/60/60)
tMin = math.floor(sExecfTime/60)-tHour*60
tSec = sExecfTime-tMin*60-tHour*60*60
local ig, clnum = "", tonumber(string.sub(tostring(tSec),#tostring(tSec),#tostring(tSec)))
 if clnum >= 2 and clnum <= 4 then ig = "ы"
 elseif clnum == 1 then ig = "а"
 end
if tHour ~= 0 then sHour = tostring(tHour).." часов" end
if tMin ~= 0 then sMin = tostring(tMin).." минут" end
if tSec ~= 0 then sSec = tostring(tSec).. " секунд"..ig end
 while true do
 buffer.square(1, 50, 160, 1, 0x000000, 0xFFFFFF, " ")
 buffer.text(1,50,0xFFFFFF,"Нажмите любую клавишу чтобы продолжить.")
 buffer.text(50,50,0xFFFFFF,"Время работы программы: "..sHour.." "..sMin.." "..sSec)
 buffer.text(160-#fs.name(wPath),50,0xFFFFFF,fs.name(wPath))
 buffer.draw() 
 local event = event.pull()  
 if event == "key_up" then dclear(0xFFFFFF); break end 
 end
end

local funcMenu1Action = {}

funcMenu1Action[1] = function()
folder.currentPath = "/"
end
funcMenu1Action[2] = function()
end
funcMenu1Action[3] = function()
useos = false
dclear(0x000000)
buffer.draw()
gpu.setBackground(0x000000)
gpu.setForeground(0xFFFFFF)
term.clear()
end
funcMenu1Action[4] = function()
osFunction.cWindow = "osInfoWindow"
end
funcMenu1Action[5] = function()
computer.shutdown(true)
end
funcMenu1Action[6] = function()
computer.shutdown(false)
end

local function dmain()
buffer.square(1, 2, 160, 49, 0x00AAFF, 0xFFFFFF, " ")
desktopIcons()
buffer.square(1, 1, 160, 1, 0x0044FF, 0xFFFFFF, " ")
buffer.text(2,1,0xFFFFFF," ≡ Меню")
drawTime()
if folder.currentPath ~= nil then folder.openFolder(folder.currentPath) end
if osFunction.cWindow == "osInfoWindow" then osFunction.osInfoWindow() end
if sVarMenu1 then funcMenu1() end
-- buffer.image(10, 10, image.load("/home/qwertb.pic"))
buffer.draw()
end
 
folder.addFav("/home")
folder.addFav("/home/desktop")
term.clear()
dclear(0x000000)
dmain()
 
while useos do
 local ev, _, x, y, button = event.pull()
  if sVarMenu1 then
   for f = 1, 6 do
    if ev == "touch" and button == 0 and clicked(x,y,1,3+f,25,3+f) then
    funcMenu1Action[f]()
	end
   end
  end 
 if ev == "touch" and button == 0 and clicked(x,y,folder.cProp.x+folder.cProp.w-5,folder.cProp.y,folder.cProp.x+folder.cProp.w-1,folder.cProp.y) and folder.currentPath ~= nil then
 folder.cScroll = 1
 folder.currentPath = nil
 end 
 if ev == "touch" and button == 0 and folder.currentPath ~= nil and not sVarMenu1 and clicked(x,y,folder.cProp.x+2,folder.cProp.y+1,folder.cProp.x+5,folder.cProp.y+1) then
 folder.cScroll = 1
 folder.currentPath = folder.getPrevPath(folder.currentPath)
 end
 if ev == "touch" and folder.currentPath ~= nil and not sVarMenu1 then
 local x1, y1, scl = folder.cProp.x, folder.cProp.y, folder.cScroll
 local flist = getFileList(folder.currentPath)
 local svw = math.floor((folder.cProp.w-folder.cProp.favWidth)/14)
 local svh = math.min(math.ceil(#flist/svw),math.floor(folder.cProp.h/7))
 local finpath, cftype, xps, yps, formula
  for f = 1, svh do
   for i = 1, svw do
    xps, yps = x1+folder.cProp.favWidth+2+i*14-14, y1+8+f*7-7
	formula = (f-1+(scl-1))*svw+i
	if flist[formula] and clicked(x,y,xps,yps-7,xps+13,yps) then
	 if string.sub(folder.currentPath,#folder.currentPath,#folder.currentPath) == "/" and not folder.currentPath ~= "/" then finpath = folder.currentPath..flist[formula]
	 else finpath = folder.currentPath.."/"..flist[formula]
	 end
	cftype = folder.getType(finpath)
	 if button == 0 then
	  if cftype == "folder" then
	  folder.cScroll = 1
	  folder.currentPath = finpath
	  break
	  elseif cftype == "lua" then
      executeFile(finpath)
	  break
	  elseif cftype == "txt"  then
	  executeFile("edit "..finpath)	
	  elseif cftype == "pic" then
	  executeFile("/home/paint.lua open "..finpath)	 
	  end
	 elseif button == 1 then
	  if cftype == "lua" or cftype == "none" then
	  executeFile("edit "..finpath)	
	  end
	 end
    end
   end
  end
 end
 if ev == "touch" and button == 0 and folder.currentPath == nil and not sVarMenu1 then
 local x1, y1, wPath = 1, 2, "/home/desktop"
 local flist = getFileList(wPath)
 local svw = math.floor(160/14)
 local svh = math.min(math.ceil(#flist/svw),math.floor(40/7))
 local finpath, cftype, xps, yps, formula
  for f = 1, svh do
   for i = 1, svw do
    xps, yps = x1+2+i*14-14, y1+8+f*7-7
	formula = (f-1)*svw+i
	if flist[formula] and clicked(x,y,xps,yps-7,xps+13,yps) then
	 if string.sub(wPath,#wPath,#wPath) == "/" and not wPath ~= "/" then finpath = wPath..flist[formula]
	 else finpath = wPath.."/"..flist[formula]
	 end
	cftype = folder.getType(finpath)
	 if button == 0 then
	  if cftype == "folder" then
	  folder.cScroll = 1
	  folder.currentPath = finpath
	  break
	  elseif cftype == "lua" then
      executeFile(finpath)
	  break 
	  elseif cftype == "shortcut" then
	   local cshtpath = folder.getShortcutPath(finpath)
	   if folder.getType(cshtpath) == "folder" then
	   folder.cScroll = 1
	   folder.currentPath = cshtpath	  
	   elseif folder.getType(cshtpath) == "lua" then
	   executeFile(cshtpath)
	   end
	  break
	  elseif cftype == "txt" then
	  executeFile("edit "..finpath)
	  elseif cftype == "pic" then
	  executeFile("/home/paint.lua open "..finpath)	 
	  end
	 elseif button == 1 then
	  if cftype == "lua" or cftype == "none" then
	  executeFile("edit "..finpath)
      end	 
	 end
	end
   end
  end 
 end
 if ev == "touch" and button == 0 and clicked(x,y,2,1,8,1) and not sVarMenu1 then sVarMenu1 = true 
 elseif ev == "touch" and button == 0 and sVarMenu1 then sVarMenu1 = false 
 end
 if folder.currentPath ~= nil and not sVarMenu1 and ev == "scroll" then 
  if button == 1 then
  folder.scroll(-1)
  else 
  folder.scroll(1)
  end
 end
 dmain()
 end
 
 
 