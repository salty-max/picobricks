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
      self.x += self.vx
      self.y += self.vy

      if self.x <= 0  or self.x >= 127 then
        self.vx = -self.vx
        sfx(0)
      end
      if self.y <= 0 or self.y >= 127 then 
        self.vy = -self.vy
        sfx(0)
      end

      if self:collide(pad) then
        pad.c = 8
      else
        pad.c = 7
      end
    end,

    draw = function(self)
      circfill(self.x, self.y, self.r, self.c)
    end,

    collide = function(self, other)
      if (self.y - self.r > other.y + other.h) return false -- top
      if (self.y + self.r < other.y) return false -- bottom
      if (self.x - self.r > other.x + other.w) return false -- left
      if (self.x + self.r < other.x) return false -- right

      return true
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
000100001834018340183301832018310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
