pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
local ball
local pad

function _init()
  ball = {
    x = 62,
    y = 62,
    vx = 4,
    vy = 2,
    w = 4,
    h = 4,
    r = 2,
    dr = 0.5,
    c = 10,

    update = function(self)
      local nextx, nexty

      nextx = self.x + self.vx
      nexty = self.y + self.vy

      if nextx <= 0  or nextx >= 127 then
        nextx = mid(0, nextx, 127)
        self.vx = -self.vx
        sfx(0)
      end
      if nexty <= 0 or nexty >= 127 then 
        nexty = mid(0, nexty, 127)
        self.vy = -self.vy
        sfx(0)
      end

      if self:collide(nextx, nexty, pad) then
        -- check if ball hits pad
        -- find out which direction ball will deflect
        if self:deflect(pad) then
          ball.vx = -ball.vx
        else
          ball.vy = -ball.vy
        end

        sfx(1)
      end

      ball.x = nextx
      ball.y = nexty
    end,

    draw = function(self)
      circfill(self.x, self.y, self.r, self.c)
    end,

    collide = function(self, nextx, nexty, other)
      if (nexty - self.r > other.y + other.h) return false -- top
      if (nexty + self.r < other.y) return false -- bottom
      if (nextx - self.r > other.x + other.w) return false -- left
      if (nextx + self.r < other.x) return false -- right

      return true
    end,

    deflect = function(self, target)
      -- calculate whether to deflect the ball
      -- horizontally and or vertical when it hits a box
      if self.vx == 0 then
        -- moving vertically
        return false
      elseif self.vy == 0 then
        -- moving horizontally
        return true
      else
        -- moving diagonally
        -- calculate slope
        local slp = self.vx / self.vy
        local cx, cy
        --check variants
        if slp > 0 and self.vx > 0 then
          -- moving down right
          debug = "dr"
          cx = target.x - self.x
          cy = target.y - self.y
          if cx <= 0 then
            return false
          elseif cy / cx < slp then
            return true
          else
            return false
          end
        elseif slp < 0 and self.vx > 0 then
          -- moving up right
          debug = "ur"
          cx = target.x - self.x
          cy = target.y + target.h - self.y
          if cx <= 0 then
            return false
          elseif cy / cx < slp then
            return false
          else
            return true
          end
        elseif slp > 0 and self.vx < 0 then
          -- moving up left
          debug = "ul"
          cx = target.x + target.w - self.x
          cy = target.y + target.h - self.y
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
          cx = target.x + target.w - self.x
          cy = target.y - self.y
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
  }

  pad = {
    x = 52,
    y = 120,
    vx = 0,
    w = 24,
    h = 3,
    s = 5,
    c = 6,

    update = function(self)
      if btn(0) then
        self.vx = -self.s
      end
      if btn(1) then
        self.vx = self.s
      end
      self.vx *= 0.75
      self.x += self.vx
    end,

    draw = function(self)
      rectfill(self.x, self.y, self.x + self.w, self.y + self.h, self.c)
    end
  }
end

function _update()
  ball:update()
  pad:update()
end

function _draw()
  cls(1)
  print("fps: "..stat(7), 4, 4, 7)
  ball:draw()
  pad:draw()  
end

__sfx__
010100001836018360183501833018320183100030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
010100002436024360243502433024320243100030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
