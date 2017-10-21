local unicode = require "unicode"
local computer = require "computer"
local term = require "term"

-- local function textWrap(text,length)
-- local u, h, n, k, anchor = {}, 1, 1, 1, {}
 -- while true do
 -- if not u[h] then u[h] = "" end
 -- k = {n,anchor[1]}
  -- while true do
   -- if n > unicode.len(text) then anchor = nil; break end
   -- if unicode.sub(text,n,n) ~= " " then
   -- u[h] = u[h]..unicode.sub(text,n,n)
   -- elseif unicode.sub(text,n,n) == " " and unicode.len(u[h]) <= length then
   -- u[h] = u[h].." "
   -- anchor[1] = n
   -- elseif unicode.sub(text,n,n) == " " and unicode.len(u[h]) > length then   
   -- anchor[2] = n
   -- break
   -- end 
   -- term.setCursor(2,1)
   -- io.write(math.floor(n*100/unicode.len(text)).."%  ")
   -- term.setCursor(5,1) 
   -- io.write(string.rep("█",math.floor(n*150/unicode.len(text))))
   -- n = n + 1
   -- os.sleep()
  -- end
  -- term.setCursor(2,2)
  -- io.write(tostring(math.floor((computer.totalMemory()-computer.freeMemory())/1024)).." KB/"..tostring(math.ceil(computer.totalMemory()/1048576*10)/10).." MB")
  -- if anchor == nil then break end
  -- u[h+1] = unicode.sub(text,anchor[1],anchor[2])
  -- u[h] = unicode.sub(text,k[1]-(k[1]-(k[2] or 0)),anchor[1])
  -- while true do 
  -- if unicode.sub(u[h],1,1) == " " then u[h] = unicode.sub(u[h],2,unicode.len(u[h])) else break end
  -- end
 -- h = h + 1
 -- os.sleep()
 -- end
-- return u
-- end

local function textWrap(text,length)
local u, h, n, k, anchor = {}, 1, 1, 1, {}
 while true do
 if not u[h] then u[h] = {} end
 k = {n,anchor[1]}
  while true do
   if n > unicode.len(text) then anchor = nil; break end
   if unicode.sub(text,n,n) ~= " " then
   table.insert(u[h],unicode.sub(text,n,n))
   elseif unicode.sub(text,n,n) == " " and #u[h] <= length then
   table.insert(u[h]," ")
   anchor[1] = n
   elseif unicode.sub(text,n,n) == " " and #u[h] > length then   
   anchor[2] = n
   break
   end 
   term.setCursor(1,1)
   io.write(math.floor(n*100/unicode.len(text)).."%  ")
   term.setCursor(5,1) 
   io.write(string.rep("█",math.floor(n*150/unicode.len(text))))
   n = n + 1
   os.sleep()
  end
  term.setCursor(1,2)
  io.write(tostring(math.floor((computer.totalMemory()-computer.freeMemory())/1024)).." KB/"..tostring(math.ceil(computer.totalMemory()/1048576*10)/10).." MB")
  if anchor == nil then break end 
  u[h+1] = {}
   for m = anchor[1], anchor[2] do
   table.insert(u[h+1],unicode.sub(text,m,m))
   end
  u[h] = {}
   for m = k[1]-(k[1]-(k[2] or 0)), anchor[1] do
   table.insert(u[h],unicode.sub(text,m,m))
   end
  while true do 
  if u[h][1] == " " then table.remove(u[h],1) else break end
  end
 h = h + 1
 os.sleep()
 end
local result = {}
for f = 1, #u do result[f] = table.concat(u[f]) end
return result
end

local text1 = "Практический опыт показывает, что рамки и место обучения кадров напрямую зависит от экономической целесообразности принимаемых решений. Таким образом, постоянное информационно-техническое обеспечение нашей деятельности обеспечивает широкому кругу специалистов участие в формировании дальнейших направлений развитая системы массового участия! Равным образом начало повседневной работы по формированию позиции обеспечивает актуальность экономической целесообразности принимаемых решений!Не следует, однако, забывать о том, что новая модель организационной деятельности позволяет выполнить важнейшие задания по разработке модели развития. Практический опыт показывает, что рамки и место обучения кадров играет важную роль в формировании экономической целесообразности принимаемых решений? Повседневная практика показывает, что реализация намеченного плана развития обеспечивает актуальность ключевых компонентов планируемого обновления. Не следует, однако, забывать о том, что сложившаяся структура организации создаёт предпосылки качественно новых шагов для всесторонне сбалансированных нововведений. Равным образом курс на социально-ориентированный национальный проект напрямую зависит от всесторонне сбалансированных нововведений. Соображения высшего порядка, а также рамки и место обучения кадров способствует подготовке и реализации новых предложений! Соображения высшего порядка, а также реализация намеченного плана развития требует от нас системного анализа дальнейших направлений развитая системы массового участия. Задача организации, в особенности же новая модель организационной деятельности требует определения и уточнения форм воздействия!"

local u = textWrap(text1,50)

print("")
for m = 1, #u do
print(u[m])
end

-- local function textWrap(text,length)
-- local u, h, n, k, anchor = {}, 1, 1, 1, {}
 -- while true do
 -- if not u[h] then u[h] = {} end
 -- k = {n,anchor[1]}
  -- while true do
   -- if n > unicode.len(text) then anchor = nil; break end
   -- if unicode.sub(text,n,n) ~= " " then
   -- table.insert(u[h],unicode.sub(text,n,n))
   -- elseif unicode.sub(text,n,n) == " " and #u[h] <= length then
   -- table.insert(u[h]," ")
   -- anchor[1] = n
   -- elseif unicode.sub(text,n,n) == " " and #u[h] > length then   
   -- anchor[2] = n
   -- break
   -- end 
   -- n = n + 1
   -- os.sleep()
  -- end
  -- if anchor == nil then break end 
  -- print(anchor[1],anchor[2])
  -- u[h+1] = {}
   -- for m = anchor[1], anchor[2] do
   -- table.insert(u[h+1],unicode.sub(text,m,m))
   -- end
  -- u[h] = {}
   -- for m = k[1]-(k[1]-(k[2] or 0)), anchor[1] do
   -- table.insert(u[h],unicode.sub(text,m,m))
   -- end
  -- while true do 
  -- if u[h][1] == " " then table.remove(u[h],1) else break end
  -- end
 -- h = h + 1
 -- os.sleep()
 -- end
-- local result = {}
-- for f = 1, #u do result[f] = table.concat(u[f]) end
-- return result
-- end



-- local base = {
-- {"A0",27.5},
-- {"A#0",29.13},
-- {"B0",30.86},
-- {"C1",32.7},
-- {"C#1",34.65},
-- {"D1",36.7},
-- {"D#1",38.9},
-- {"E1",41.2},
-- {"F1",43.65},
-- {"F#1",46.24},
-- {"G1",49},
-- {"G#1",51.9},
-- {"A1",55},
-- {"A#1",58.27},
-- {"B1",61.73},
-- {"C2",65.4},
-- {"C#2",69.3},
-- {"D2",73.41},
-- {"D#2",77.78},
-- {"E2",82.4},
-- {"F2",87.3},
-- {"F#2",92.5},
-- {"G2",98},
-- {"G#2",103.82},
-- {"A2",110},
-- {"A#2",116.54},
-- {"B2",123.47},
-- {"C3",130.81},
-- {"C#3",138.59},
-- {"D3",146.83},
-- {"D#3",155.56},
-- {"E3",164.814},
-- {"F3",174.614},
-- {"F#3",185},
-- {"G3",196},
-- {"G#3",207.65},
-- {"A3",220},
-- {"A#3",233},
-- {"B3",247},
-- {"C4",261.62},
-- {"C#4",277.18},
-- {"D4",293.665},
-- {"D#4",311.127},
-- {"E4",329.63},
-- {"F4",349.228},
-- {"F#4",370},
-- {"G4",392},
-- {"G#4",415.3},
-- {"A4",440},
-- {"A#4",466.164},
-- {"B4",493.9},
-- {"C5",523.25},
-- {"C#5",553.365},
-- {"D5",587.33},
-- {"D#5",622.254},
-- {"E5",659.255},
-- {"F5",698.456},
-- {"F#5",830.6},
-- {"A5",880},
-- {"A#5",932.33},
-- {"B5",987.767},
-- {"C6",1046.5},
-- {"C#6",1108.73},
-- {"D6",1174.66},
-- {"D#6",1244.51},
-- {"E6",1318.51},
-- {"F6",1396.91},
-- {"F#6",1479.98},
-- {"G6",1567.98},
-- {"G#6",1661.22},
-- {"A6",1760},
-- {"A#6",1864.66},
-- {"B6",1975.53},
-- }