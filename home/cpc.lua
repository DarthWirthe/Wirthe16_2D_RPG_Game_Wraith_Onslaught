local component = require("component")
local nb = component.note_block
nb.setPitch(10)
nb.trigger()
for pitch = 1, 25 do
  nb.trigger(pitch)
end