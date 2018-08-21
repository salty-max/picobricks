pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- ball deflection sandbox
-- by jellycat

local box, ray

debug = "debug"

function _init()
  box = {
    x = 32,
    y = 58,
    w = 64,
    h = 12
  }

  ray = {
    x = 0,
    y = 0,
    vx = -2,
    vy = -2
  }
end

function _update()
  if btn(1) then
    ray.x += 1
  end
  if btn(0) then
    ray.x -= 1
  end
  if btn(2) then
    ray.y -= 1
  end
  if btn(3) then
    ray.y += 1
  end 
end

function _draw()
  local px, py = ray.x, ray.y

  cls()
  rect(box.x, box.y, box.x + box.w, box.y + box.h, 7)

  repeat
    pset(px, py, 8)
    px += ray.vx
    py += ray.vy
  until px < 0 or px > 128 or py < 0 or py > 128

  if deflect(ray, box) then
    print("horizontal")
  else
    print("vertical")
  end

  print(debug)
end

function deflect(ball, target)
  -- calculate whether to deflect the ball
  -- horizontally and or vertical when it hits a box

  -- calculate the slope
  local slp = ball.vy / ball.vx
  local cx, cy

  if ball.vx == 0 then
      -- moving vertically
      return false
  elseif ball.vy == 0 then
      -- moving horizontally
      return true
  elseif slp > 0 and ball.vx > 0 then
      debug = "dr"
      cx = target.x - ball.x
      cy = target.y - ball.y
      return cx > 0 and cy/cx < slp
  elseif slp < 0 and ball.vx > 0 then
      debug = "ur" 
      cx = target.x - ball.x
      cy = target.y + target.h - ball.y
      return cx > 0 and cy/cx >= slp
  elseif slp > 0 and ball.vx < 0 then
      debug = "ul"
      cx = target.x + target.w - ball.x
      cy = target.y + target.h - ball.y
      return cx < 0 and cy/cx <= slp
  else
      debug = "dl"
      cx = target.x + target.w - ball.x
      cy = target.y - ball.y
      return cx < 0 and cy/cx >= slp
  end
end