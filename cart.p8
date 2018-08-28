pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
------ comments ------
-- todo
-- 7.   more juicyness
--        arrow animation
--        particles
--          death
--          collision
--          brick shatter
--          powerup pickup
--          explosive brick detonation
--        level setup
-- 8.   high score
-- 9.   ui
--        combo text
--        powerup text
--        powerup %bar
-- 10.  better collisions
-- 11.  gameplay tweaks
-- 12.   timer
--        smaller paddle ?  

-- brick types
-- b -> regular
-- h -> hardened
-- i -> indestructible
-- s -> explosive
-- p -> powerup

-- powerups
-- spd -> orange -> timer                   ->  ball speed down
-- 1up -> white  -> instant                 ->  extra life
-- sty -> green  -> no timer                ->  sticky ball
-- exp -> pink   -> timer / cancels reduce  ->  increase paddle size
-- rdc -> red    -> timer / cancels expand  ->  decrease paddle size &
--                                              double score
-- mlt -> yellow -> no timer                ->  spawn 2 other balls
-- meg -> blue   -> timer                   ->  one shot hardened
--                                              go through all bricks 
--                                              except indestructibles

-- sfx
-- 00 -> wall hit
-- 01 -> pad hit
-- 02 -> lose ball
-- 03 -> brick chain x1
-- 04 -> brick chain x2
-- 05 -> brick chain x3
-- 06 -> brick chain x4
-- 07 -> brick chain x5
-- 08 -> brick chain x6
-- 09 -> brick chain x7
-- 10 -> brick chain x8
-- 11 -> indestructible brick hit
-- 12 -> powerup pickup
-- 13 -> start game

-->8
------ init ------

local ball, balls, pad, bricks, powups, stars, lives, score, mult, chain, levels, level, scene, debug, powerup, powerup_t, shake, blink_f, blink_ci, fade,menu_cd, menu_blink_speed, menu_transition, go_cd, go_transition, preview_f

function _init()
  scene = "start"
  debug = ""

  levels = {
    "b3xb3xb3/xbxxh1b1h1xxbx/xpxxh1s1h1xxpx/b1h1b1xb3xb1h1b1",
    "x5b1x5/sbsbsbsbsbs",
    "b9b2/x1p9",
    "b9b2/b9b2/b9b2",
    "x5p1x5/x4b3x4/x1i9",
  }
  level = 1
  
  lives = 1
  score = 0
  mult = 1

  -- screenshake intensity
  shake = 0

  -- blink variables
  blink_f = 0
  blink_ci = 1

  -- menu animation helpers
  menu_cd = -1
  menu_blink_speed = 20
  menu_transition = 60

  -- gameover animation helpers
  go_cd = -1
  go_transition = 30

  -- fading percentage
  fade = 0

  -- preview arrow frame counter
  preview_f = 0
end

function start()
  -- brick global variables
  local brick_w = 10
  local brick_h = 5
  local brick_offset = 1
  
  scene = "game"
  balls = {}
  bricks = {}
  powups = {}
  stars = {}
  chain = 1
  score = 0

  pad = make_pad()
  build_bricks(levels[level], brick_w, brick_h, brick_offset)

  -- reset game
  serve_ball()
end

function nextlevel()
  level += 1
  shake = 0
  start()
end

function gameover()
  scene = "gameoverwait"
  go_cd = 60
  sfx(20)
end

function serve_ball()
  balls = {}
  balls[1] = make_ball()
  balls[1].x = 64
  balls[1].y = pad.y - balls[1].r
  balls[1].vx = 1
  balls[1].vy = -1
  balls[1].a = 1
  balls[1].stuck = true
  balls[1].sticky_x = flr(pad.w / 2)

  chain = 1
  powerup = ""
  powerup_s = 0
  powerup_t = 0
end

function build_bricks(lvl, w, h, o)
  local i, j, k, id, chr, last
  j = 0
  id = 0

  for i = 1,#lvl do
    j += 1
    id += 1
    -- extract current character from level string
    chr = sub(lvl, i, i)
    -- check for bricks characters
    if chr == "b" or chr == "h" or chr =="i" or chr == "s" or chr == "p" then
      last = chr
      set_brick(id, chr, j, w, h, o)
    -- check for spaces
    elseif chr == "x" then
      last = "x"
    -- check for line breaks
    elseif chr == '/' then
      j = flr((j - 1) / 11) * 11
    -- create n bricks of last character type
    elseif chr >= "0" and chr <= "9" then
      for k = 1,tonum(chr) - 1 do
        set_brick(id, last, j, w, h, o)
        j += 1
        id += 1
      end
      j -= 1
      id -= 1
    end
    
  end
end

function set_brick(id, t, n, w, h, o)
  if t == "x" then
    -- do nothing
  else
    add(bricks, make_brick(id, 4 + ((n - 1) % 11) * (w + o), 20 + flr((n - 1) / 11) * (h + o), w, h, t))
  end
end

function handle_score()
  local chain_color

  -- combo indicator color management
  if chain > 2 and chain < 5 then
    chain_color = 10
  elseif chain >= 5 and chain <= 7 then
    chain_color = 9
  elseif chain == 8 then
    chain_color = 8
  else
    chain_color = 7
  end

  -- multiplier
  print("x"..chain, 60, 2, chain_color)
  -- score
  print("score: "..score, 72, 2, 6)
end

function hit_brick(b, combo)
  -- check brick type on hit and apply behavior based on it
  if b.t == "b" then
    sfx(3 + (chain - 1))
    if combo then
      score += (b.pts * chain) * mult
      chain += 1
      chain = mid(1, chain, 8)
    end
    del(bricks, b)
  elseif b.t == 's' then
    b.t = "rex"
    sfx(3 + (chain - 1))
    if combo then
      score += (b.pts * chain) * mult
      chain += 1
      chain = mid(1, chain, 8)
    end
  elseif b.t == "h" then
    if powerup == "meg" then
      if combo then
        score += (b.pts * chain) * mult
        chain += 1
        chain = mid(1, chain, 8)
      end
      del(bricks, b)
    else
      b.t = "b"
    end
    sfx(3 + (chain - 1))
  elseif b.t == "i" then
    sfx(11)
  elseif b.t == "p" then
    sfx(3 + (chain - 1))
    if combo then
      score += (b.pts * chain) * mult
      chain += 1
      chain = mid(1, chain, 8)
    end
    b:spawn_pill("spd")
    del(bricks, b)
  end
end


function check_explosions()
  -- check if bricks will explode
  for brick in all(bricks) do
    if brick.t == "rex" then
      brick.t = "ex"
    elseif brick.t == "ex" then
      explode_bricks(brick)
      shake += 0.4
      if (shake > 1) shake = 1
    elseif brick.t == "rex" then
      brick.t = "ex"
    end 
  end
end

function explode_bricks(b)
  -- explosion spread management
  for brick in all(bricks) do
    if brick.id != b.id and abs(brick.x - b.x) <= brick.w + 1 and abs(brick.y - b.y) <= brick.h + 1 then
      hit_brick(brick, false)
    end
  end
  del(bricks, b)
end

function collide(a, b)
  -- check for collision between two rectangle hitboxes
  if (a.x > b.x + b.w) return false 
  if (a.x + a.w < b.x) return false 
  if (a.y > b.y + b.h) return false 
  if (a.y + a.h < b.y) return false 

  return true
end

function copyball(ob)
  b = make_ball()
  b.x = ob.x
  b.y = ob.y
  b.vx = ob.vx
  b.vy = ob.vy
  b.a = ob.a

  return b
end

function multiball()
  ob = balls[flr(rnd(#balls)) + 1]
  cb = copyball(ob)

  if ob.a == "0" then
    cb:set_angle(2)
  elseif ob.a == "1" then
    ob:set_angle(0)
    cb:set_angle(2)
  else
    cb:set_angle(0)
  end

  add(balls, cb)
end

-->8
------ update functions ------

function _update60()
  if fade != 0 then
    fade -= 0.05
    if (fade < 0) fade = 0
  end

  if scene == "game" then
    update_game()
  elseif scene == "start" then
    update_start()
  elseif scene == "gameoverwait" then
    update_gameoverwait()
  elseif scene == "gameover" then
    update_gameover()
  elseif scene == "levelend" then
    shake = 0
    camera()
    update_levelend()
  end
end

function update_game()
  local dest_bricks = {}

  for ball in all(balls) do
    ball:update()
  end

  pad:update()

  for brick in all(bricks) do
    brick:update()
    brick:set_type()

    -- remove indestructiblr bricks from bricks counter
    if (brick.t != "i") add(dest_bricks, brick)
  end

  for pow in all(powups) do
    pow:update()
  end

  make_stars(1)

  if (#dest_bricks < 1) then 
    
    if level == #levels then
      -- todo
      -- nice end game screen
      scene = "start"
    else
      _draw()
      scene = "levelend"
    end
  end

  -- powerup timer handling
  if (powerup != "") powerup_t -= 1
  if (powerup_t <= 0) powerup = ""

  -- score multiplier
  if powerup == "rdc" then
    mult = 2
  else
    mult = 1
  end
end

function update_start()
  menu_blink_speed = 20
  if menu_cd < 0 then
    if (btnp(5)) then
      menu_cd = menu_transition
      sfx(13)
    end
  else
    fade = (menu_transition - menu_cd) / menu_transition
    menu_cd -= 1
    menu_blink_speed = 5

    if menu_cd <= 0 then
      menu_cd = -1
      start()
    end
  end
end

function update_gameover()
  menu_blink_speed = 20
  if go_cd < 0 then
    if (btnp(5)) then
      go_cd = go_transition
      sfx(13)
    end
  else
    go_cd -= 1
    menu_blink_speed = 5
    fade = (go_transition - go_cd) / go_transition
    if go_cd <= 0 then
      go_cd = -1
      scene = "start"
    end
  end
end

function update_gameoverwait()
  -- stop background scrolling
  for star in all(stars) do
    star.dy = 0
  end

  go_cd -= 1

  if go_cd <= 0 then
    go_cd = -1
    scene = "gameover"
  end
end

function update_levelend()
  if (btnp(5)) nextlevel()
  camera(0, 0)
  shake = 0
end
-->8
------ draw functions ------
function _draw()
  if scene == "game" then
    draw_game()
  elseif scene == "start" then 
    draw_start()
  elseif scene == "gameoverwait" then
    draw_game()
  elseif scene == "gameover" then
    draw_gameover()
  elseif scene == "levelend" then
    draw_levelend()
  end

  -- fade screen
  pal()
  if (fade != 0) fadepal(fade)

  -- show FPS
  print("fps: "..stat(7), 100, 120, 7)
  -- debug text
  if (debug != "") print(debug, 100, 120, 6)
end

function draw_game()
  cls()
  
  draw_stars()

  --map(0,0,0,0,16,16)
  draw_ui()
  shake_screen()
  for ball in all(balls) do
    ball:draw()
  end
  pad:draw()  
  for brick in all(bricks) do
    brick:draw()
  end

  for pow in all(powups) do
    pow:draw()
  end
end

function draw_start()
  local title = "picobricks"
  local subtitle = "alpha version" 
  local cta = "press ❎ to start"
  cls(0)
  print(title, 64 - (#title / 2) * 4, 30, 8)
  print(subtitle, 64 - (#subtitle / 2) * 4, 38, 6)
  print(cta, 64 - (#cta / 2) * 4, 60, blink_text(menu_blink_speed, {1, 12}))
end

function draw_gameover()
  local go_text = "game over !"
  local score_text = "your score: "..score
  local cta = "press ❎ to try again"
  rectfill(-8, 30, 128, 72, 0)
  rect(-8, 30, 128, 72, 6)
  print(go_text, 64 - (#go_text / 2) * 4, 38, 8)
  print(score_text, 64 - (#score_text / 2) * 4, 46, 7)
  print(cta, 64 - (#cta / 2) * 4, 60, blink_text(menu_blink_speed, {0, 6}))
end

function draw_levelend()
  local lo_text = "stage clear !"
  local cta = "press ❎ to continue"
  local score_text = "your score: "..score
  rectfill(-8, 30, 128, 72, 0)
  rect(-8, 30, 128, 72, 6)
  print(lo_text, 64 - (#lo_text / 2) * 4, 38, 11)
  print(score_text, 64 - (#score_text / 2) * 4, 46, 7)
  print(cta, 64 - (#cta / 2) * 4, 60, 6)
end

function draw_ui()
  rectfill(0, 0, 127, 8, 0)
  for i=1,lives do print("♥", 4 + 8*i - 8, 2, 8) end
  handle_score()
  if powerup != "" then
  spr(powerup_s, 4, 120)
  print((powerup_t + 1) / 60, 12, 120, 7)
  end
end

function draw_stars()
	for s in all(stars) do
		pset(s.x,s.y,s.c)
		s.y+=s.dy
		if (s.y>128) del(stars,s)
	end
end
-->8
------ objects ------
function make_ball()
  local ball = {
    x = 0,
    y = 0,
    vx = 0,
    vy = 0,
    a = 1,
    w = 4,
    h = 4,
    r = 2,
    s = 16,
    c = 10,
    sticky_x = 0,
    stuck = false,

    update = function(self)
      local nextx, nexty

      if self.stuck then
        -- make ball move alongside paddle
        self.x = pad.x + self.sticky_x
        self.y = pad.y - self.r - 1
      else
        -- ball movement
        if powerup == "spd" then
          nextx = self.x + (self.vx / 2)
          nexty = self.y + (self.vy / 2)
        else
          nextx = self.x + self.vx
          nexty = self.y + self.vy
        end

        -- make ball bounce off screen boundaries
        if nextx <= 0  or nextx >= 127 then
          nextx = mid(0, nextx, 127)
          self.vx = -self.vx
          sfx(0)
        end
        if nexty <= 8 + self.r then 
          nexty = mid(0, nexty, 127)
          self.vy = -self.vy
          sfx(0)
        end

        if self:bounce(nextx, nexty, pad) then
          -- check if ball hits pad
          -- find out which direction ball will deflect
          if self:deflect(pad) then
            -- ball hits paddle sideways
            self.vx = -self.vx
            if self.x < pad.x + pad.w / 2 then
              nextx = pad.x - self.r
            else
              nextx = pad.x + pad.w + self.r
            end
          else
            -- ball hits paddle on top / bottom
            self.vy = -self.vy
            if self.y > pad.y then
              -- bottom
              nexty = pad.y + pad.h + self.r
            else
              -- top
              nexty = pad.y - self.r

              if abs(pad.vx) > 2 then
                -- change angle
                if sgn(self.vx) == sgn(pad.vx) then
                  -- flatten angle
                  self:set_angle(mid(0, self.a - 1, 2))
                else
                  -- raise angle
                  if (self.a == 2) self.vx = -self.vx
                  self:set_angle(mid(0, self.a + 1, 2))  
                end
              end
            end
          end

          chain = 1
          sfx(1)

          -- make ball sticky
          if pad.sticky and self.vy < 0 then
            pad:release_ball()
            pad.sticky = false
            self.stuck = true
            self.sticky_x = self.x - pad.x
          end
        end

        local brick_hit = false
        for brick in all(bricks) do 
          if self:bounce(nextx, nexty, brick) then
            -- check if ball hits brick
            -- find out which direction ball will deflect
            if not brick_hit then
              if (powerup == "meg" and brick.t == "i") or powerup != "meg" then
                if self:deflect(brick) then
                  -- ball hits brick sideways
                  self.vx = -self.vx
                  if self.x < brick.x + brick.w / 2 then
                    nextx = brick.x - self.r
                  else
                    nextx = brick.x + brick.w + self.r
                  end
                else
                  -- ball hits brick on top / bottom
                  self.vy = -self.vy
                  if self.y > brick.y then
                    -- bottom
                    nexty = brick.y + brick.h + self.r
                  else
                    -- top
                    nexty = brick.y - self.r
                  end
                end
              end
            end

            brick_hit = true
            hit_brick(brick, true)
          end

          self.x = nextx
          self.y = nexty
        end
      end

      -- ball falls out of screen
      if self.y > 127 then
        if #balls > 1 then
          sfx(2)
          shake += 0.2
          del(balls, self)
        else
          if lives <= 1 then
          gameover()
        else
          lives -= 1
          sfx(2)
          shake += 0.5
          serve_ball()
        end
        end
      end

      check_explosions()
    end,

    draw = function(self)

      -- manage ball sprite
      if powerup == "meg" then
        self.s = 17
      else
        self.s = 16
      end

      spr(self.s, self.x - self.r, self.y - self.r)

      -- serve preview
      if (self.stuck) serve_preview()
    end,

    -- check for collision between ball and rect hitboxes
    bounce = function(self, nextx, nexty, other)
      if (nexty - self.r > other.y + other.h) return false -- top
      if (nexty + self.r < other.y) return false -- bottom
      if (nextx - self.r > other.x + other.w) return false -- left
      if (nextx + self.r < other.x) return false -- right

      return true
    end,

    -- calculate ball direction based on where it hits another entity
    deflect = function(self, target)
      local slp = self.vy / self.vx
      local cx, cy
      if self.vx == 0 then
          return false
      elseif self.vy == 0 then
          return true
      elseif slp > 0 and self.vx > 0 then
          cx = target.x - self.x
          cy = target.y - self.y
          return cx > 0 and cy/cx < slp
      elseif slp < 0 and self.vx > 0 then
          cx = target.x - self.x
          cy = target.y + target.h - self.y
          return cx > 0 and cy/cx >= slp
      elseif slp > 0 and self.vx < 0 then
          cx = target.x + target.w - self.x
          cy = target.y + target.h - self.y
          return cx < 0 and cy/cx <= slp
      else
          cx = target.x + target.w - self.x
          cy = target.y - self.y
          return cx < 0 and cy/cx >= slp
      end
    end,

    -- calculate ball angle
    set_angle = function(self, a)
      self.a = a

      if a == 2 then
        self.vx = 0.50 * sgn(self.vx)
        self.vy = 1.30 * sgn(self.vy)
      elseif a == 0 then
        self.vx = 1.30 * sgn(self.vx)
        self.vy = 0.50 * sgn(self.vy)
      else
        self.vx = 1 * sgn(self.vx)
        self.vx = 1 * sgn(self.vx)
      end
    end
  }

  return ball
end

function make_pad()
  local pad = {
    x = 52,
    y = 120,
    vx = 0,
    w = 24,
    h = 3,
    s = 3,
    c = 6,
    sticky = false,

    update = function(self)

       -- release ball
      if btnp(5) then
        self:release_ball()
      end

      -- move left
      if btn(0) then
        self.vx = -self.s
        self:point_ball(-1)
      end

      -- move right
      if btn(1) then
        self.vx = self.s
        self:point_ball(1)
      end
      
      -- apply friction
      self.vx *= 0.85

      -- apply velocity
      self.x += self.vx
      -- paddle don't go offscreen
      self.x = mid(0, self.x, 127 - self.w)

      -- paddle size management
      if (powerup == "exp") then
        self.w = 32
      elseif (powerup == "rdc") then 
        self.w = 16
      else
        self.w = 24
      end
    end,

    -- draw paddle based on its size
    draw = function(self)
      if (powerup == "exp") then
        spr(37, self.x, self.y - 2, 4, 1)
      elseif (powerup == "rdc") then 
        spr(35, self.x, self.y - 2, 2, 1)
      else
        spr(32, self.x, self.y - 2, 3, 1)
      end
    end,

    release_ball = function(self)
      for ball in all(balls) do
        if ball.stuck then
          ball.x = mid(3, ball.x, 124)
          ball.stuck = false
        end
      end
    end,

    point_ball = function(self, sign)
      for ball in all(balls) do
        if ball.stuck then
          ball.vx = abs(ball.vx) * sign
        end
      end
    end
  }

  return pad
end

function make_brick(id, x, y, w, h, t)
  local brick = {
    id = id,
    x = x,
    y = y,
    w = w,
    h = h,
    t = t,
    --hp = 0,
    c = 0,
    sx = 0,
    sy = 0,
    pts = 0,
    --v = true,

    update = function(self)
    end,

    draw = function(self)
      palt(0, false)
      sspr(self.sx, self.sy, self.w, self.h, self.x, self.y)
      palt()
    end,

    set_type = function(self)
      if self.t == "b" then
        self.sx = 8
        self.c = 14
        --self.hp = 1
        self.pts = 50
      elseif self.t == "h" then
        self.sx = 18
        self.c = 12
        --self.hp = 2
        self.pts = 100
      elseif self.t == "i" then
        self.sx = 48
        self.c = 13
        --self.hp = 1
        self.pts = 0
      elseif self.t == "s" then
        self.sx = 28
        self.c = 9
        --self.hp = 1
        self.pts = 300
      elseif self.t == "p" then
        self.sx = 38
        self.c = 11
        --self.hp = 1
        self.pts = 200
      end
    end,

    -- randomly spawn powerups
    spawn_pill = function(self)
      local types = {"spd", "1up", "sty", "exp", "rdc", "meg", "mlt"}
      add(powups, make_powup(types[flr(rnd(7)) + 1], self.x + self.w / 2, self.y + self.h + 2))
      --types[flr(rnd(7)) + 1]
    end
  }

  return brick
end

function make_powup(t, x, y)
  local pow = {
    x = x,
    y = y,
    vy = 0.7,
    w = 4,
    h = 4,
    s = 0,
    t = t,

    update = function(self)
      self.y += self.vy

      -- delete pill when it exits screen
      if (self.y >= 128) del(powups, self)

      if collide(self, pad) then
        self:activate()
        sfx(12)
        del(powups, self)
      end
    end,

    draw = function(self)
      -- pill sprite management
      if self.t == "spd" then
        self.s = 48
      elseif self.t == "1up" then
        self.s = 49
      elseif self.t == "sty" then
        self.s = 50
      elseif self.t == "exp" then
        self.s = 51
      elseif self.t == "rdc" then
        self.s = 52
      elseif self.t == "meg" then
        self.s = 53
      elseif self.t == "mlt" then
        self.s = 54
      end
      spr(self.s, self.x, self.y)
    end,


    -- set active powerup type, and duration
    activate = function(self)
      if self.t == "spd" then     -- speed down
        -- slow down ball
        self:reset(self.t, 600)
      elseif self.t == "1up" then -- extra life
        lives += 1
      elseif self.t == "sty" then -- sticky ball
        local has_stuck = false
        for ball in all(balls) do
          if (ball.stuck) has_stuck = true
        end

        if (not has_stuck) pad.sticky = true
      elseif self.t == "exp" then -- expand paddle
        self:reset(self.t, 600)
        -- expand paddle
      elseif self.t == "rdc" then -- shrink paddle
        self:reset(self.t, 600)
        -- reduce paddle
      elseif self.t == "meg" then -- megaball
        self:reset(self.t, 600)
        -- megaball
      elseif self.t == "mlt" then -- multiball
        -- multiball
        pad: release_ball()
        multiball()
      end
    end,

    reset = function(self, type, timer)
      powerup = type
      powerup_t = 600
      powerup_s = self.s
    end
  }

  return pow
end

function make_stars(n)
	while n > 0 do
		star = {}
		star.x = flr(rnd(128))
		star.y = -2
		star.c = 5 + flr(rnd(2))
		star.dy = 3
		add(stars,star)
		n -= 1
	end
end

-->8
------ juicyness ------

function shake_screen()
  local shakex = 16 - rnd(32)
  local shakey = 16 - rnd(32)

  shakex *= shake
  shakey *= shake

  camera(shakex, shakey)

  shake *= 0.95
  if(shake < 0.05) shake = 0
end

function blink_text(speed, seq)
  blink_f += 1

  if blink_f > speed then
    blink_f = 0
    blink_ci += 1

    if (blink_ci > #seq) blink_ci = 1
  end
  return seq[blink_ci]
end

function fadepal(perc)
  -- o -> normal color
  -- 1 -> black

  local p = flr(mid(0, perc, 1) * 100)

  -- helper variables
  local kmax, col, dpal, j ,k

  -- take each color and determine in which color it will fade
  dpal = {
    0,1,1,
    2,1,13,6,
    4,4,9,3,
    13,1,13,14
  }

  -- iterate through colors
  for j = 1, 15 do
    -- grab current color
    col = j

    -- calculate how many times color will be darken
    kmax = (p + (j * 1.46)) / 22
    for k = 1, kmax do
      col = dpal[col]
    end

    -- change palette
    pal(j, col, 1)  
  end

end

function serve_preview()
  local offset, offset2
  local speed = 30

  preview_f += 1

  if (preview_f > speed) preview_f = 0

  offset = 1 + (2 * (preview_f / speed))

  local preview_f2 = preview_f + 15

  if (preview_f2 > speed) preview_f2 -= speed

  offset2 = 1 + (2 * (preview_f2 / speed))

  pset(balls[1].x + balls[1].vx * 4 * offset,
       balls[1].y + balls[1].vy * 4 * offset, 10)
  
  pset(balls[1].x + balls[1].vx * 4 * offset2,
       balls[1].y + balls[1].vy * 4 * offset2, 10)
end

__gfx__
00000000277777777717777777775aa55aa55a377777777757777777770000000000000000000000000000000000000000000000000000000000000000550055
000000002eeeeeeee71cccccccc799009900993bbbbbbbb756dd66dd670000000000000000000000000000000000000000000000000000000000000005500550
007007002eeeeeeee71cccccccc790099009903bbbbbbbb75dd66dd6670000000000000000000000000000000000000000000000000000000000000055005500
000770002eeeeeeee71cccccccc700990099003bbbbbbbb75d66dd66d70000000000000000000000000000000000000000000000000000000000000050055005
00077000222222222711111111170440044004333333333755555555570000000000000000000000000000000000000000000000000000000000000000550055
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005500550
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055005500
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050055005
0a7000000ef000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaa70000eeef00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9aaa00002eee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09a0000002e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06700000000000000000077006700000000007700670000000000000000000000000077000000000000000000000000000000000000000000000000000000000
56677777777777777777766756677777777776675667777777777777777777777777766700000000000000000000000000000000000000000000000000000000
56666666666666666666666756666666666666675666666666666666666666666666666700000000000000000000000000000000000000000000000000000000
56655555555555555555566756655555555556675665555555555555555555555555566700000000000000000000000000000000000000000000000000000000
05500000000000000000056005500000000005600550000000000000000000000000056000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06670000066700000667000006670000066700000667000006670000000000000000000000000000000000000000000000000000000000000000000000000000
69997000677770006bbb70006eee7000688870006ccc70006aaa7000000000000000000000000000000000000000000000000000000000000000000000000000
69996000677760006bbb60006eee6000688860006ccc60006aaa6000000000000000000000000000000000000000000000000000000000000000000000000000
59996000577760005bbb60005eee6000588860005ccc60005aaa6000000000000000000000000000000000000000000000000000000000000000000000000000
05660000056600000566000005660000056600000566000005660000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0002020202020002020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010100001836018360183501833018320183100030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
010100002436024360243502433024320243100030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
01080000155651356511555105550e5450c5450b53509531095210951109511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002a34030340303303032030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000200002c34032340323303232030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000200002e34034340343303432030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000200003034036340363303632030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000200003234038340383303832030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
00020000343403a3403a3303a32030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
00020000363403c3403c3303c32030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
00020000383403e3403e3303e32030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
010200003b5530c5020c5000c5000c5000c5000c5000c5000c5000c5020c5020c5000c50110501105000c5000e5000c5000e5020e5000e5010c5010c5000c5000c500005000b5000b5010c5010c5020c5020c502
0108000024344283352635429355283542b3550030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
0108000028055285402f0552f54027055275402f0552f54028035285202f0352f52027025275102f0252f51000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000071760010000100131551515517155101550c1420c1320c1220c112001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011100002874028740287422874228752287522875228752297452a7452b7422b7422b7322b7322b7322b732347452f7452b74528745347552f7552b75528755347452f7452b74528745347352f7352b73528735
01100000047300473004730047300473204732047320473207730077300773007730077320773207732077320e7300e7300e7300e7300e7320e7320e7320e7320973009730097300973009732097320973209732
01100000030530c000000000000003053000000000000000030530000000000000000305300000000000000003053000000000000000030530000000000000000305300000000000000003053000000000000000
000e0000187001a700197001b7001c700187001c700197001d7002170022700237002470025700267002770028700297002a7002b7002c7002d7002e7002f7003070000000000000000000000000000000000000
__music__
03 1f201e44

