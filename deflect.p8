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
    vx = 2,
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

-- function hit_ballbox(bx,by,tx,ty,tw,th)
--  if bx+ball_r < tx then return false end
--  if by+ball_r < ty then return false end
--  if bx-ball_r > tx+tw then return false end
--  if by-ball_r > ty+th then return false end
--  return true
-- end

function deflect(ball, target)
  -- calculate whether to deflect the ball
  -- horizontally and or vertical when it hits a box
  if ball.vx == 0 then
    -- moving vertically
    return false
  elseif ball.vy == 0 then
    -- moving horizontally
    return true
  else
    -- moving diagonally
    -- calculate slope
    local slp = ball.vx / ball.vy
    local cx, cy
    --check variants
    if slp > 0 and ball.vx > 0 then
      -- moving down right
      debug = "dr"
      cx = target.x - ball.x
      cy = target.y - ball.y
      if cx <= 0 then
        return false
      elseif cy / cx < slp then
        return true
      else
        return false
      end
    elseif slp < 0 and ball.vx > 0 then
      -- moving up right
      debug = "ur"
      cx = target.x - ball.x
      cy = target.y + target.h - ball.y
      if cx <= 0 then
        return false
      elseif cy / cx < slp then
        return false
      else
        return true
      end
    elseif slp > 0 and ball.vx < 0 then
      -- moving up left
      debug = "ul"
      cx = target.x + target.w - ball.x
      cy = target.y + target.h - ball.y
      if cx >= 0 then
        return false
      elseif cy / cx > slp then
        return false
      else
        return true
      end
    else
      -- moving down left
      debug = "dl"
      cx = target.x + target.w - ball.x
      cy = target.y - ball.y
      if cx >= 0 then
        return false
      elseif cy / cx < slp then
        return false
      else
        return true
      end
    end
  end
  return false
end