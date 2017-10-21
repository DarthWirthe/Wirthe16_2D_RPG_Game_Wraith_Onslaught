local koef = 2 -- коэффициент стартового запуска
 
local component = require("component")
local gpu = component.gpu
local term = require('term')
local event = require('event')
 
local h = {['x'] = 20,['y'] = 30,['dx'] = 5,['dy'] = -3}
local xm,ym = gpu.getResolution()
 
function line(x1,y1,x2,y2)
	x= x1
	y= y1
	for i = 1 , math.floor( ( (x2-x1 )^2+( y1-y2 )^2)^0.5) do
		gpu.set(math.floor(x),math.floor(y),'-')
 
		rad = math.atan2(y1-y2,x2-x1)
		x = x + math.cos(rad)
		y = y - math.sin(rad)
	end
end
 
function fiz(usl,dxx,dyy,xx,yy)
	if usl then
		h.dx = h.dx * dxx
		h.dy = h.dy * dyy
		h.x = xx
		h.y = yy
	end
end
 
term.clear()
while true do
 
	local e1 = {event.pull(0.05)}
	gpu.set(math.floor(h.x),math.floor(h.y),' ')
 
	if e1[1] == 'touch' then
		local e2 
		repeat
			e2 = {event.pull()}
			if e2[1] == 'drag' then term.clear() line(e1[3],e1[4],e2[3],e2[4]) end
			if (e2[1] == 'touch') then break end
			gpu.set(1,1,'dx '..tostring((e1[3] - e2[3])/koef))
			gpu.set(1,2,'dy '..tostring((e1[4] - e2[4])/koef))
		until e2[1] == 'drop'
		term.clear()
		if e2[1] == 'drop' then
			h.x = e1[3]
			h.y = e1[4]
			h.dx = (e1[3] - e2[3])/koef
			h.dy = (e1[4] - e2[4])/koef
		end
	end	
	h.dx = h.dx
	h.dy = h.dy + 0.45
	h.x = h.x + h.dx
	h.y = h.y + h.dy
 
	fiz(h.y > ym,0.9,-0.85,h.x,ym) -- низ
	fiz(h.y < 0 ,0.9,-0.85,h.x,0) -- верх
	fiz(h.x > xm,-0.85,0.9,xm,h.y) -- право
	fiz(h.x < 0 ,-0.85,0.9 ,0,h.y) -- лево
	gpu.set(math.floor(h.x),math.floor(h.y),'в—¦')
	gpu.set(1,1,'dx '..tostring(h.dx))
	gpu.set(1,2,'dy '..tostring(h.dy))
end