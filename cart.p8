pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
------ comments ------
-- todo
-- 10.  better collisions
-- 11.  level design
-- 13.  sounds
--------- level over fanfare
--------- high score screen music
--------- start screen music  
-- 14.  gameplay tweaks
--------- timer
--------- smaller paddle ?

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
-- 14 -> brick shatter
-- 15 -> confirm
-- 16 -> menu blip
-- 17 -> error
-- 18 -> menu bloop
-- 19 -> woosh

-->8
------ init ------

local balls, pad, bricks, powups, parts, lives, score, mult, chain, levels, level, scene, debug, powerup, powerup_t, shake, blink_f, blink_ci, fade,menu_cd, menu_blink_speed, menu_transition, go_cd, go_transition, preview_f, lasthit_x, lasthit_y, hs, hsc, hs_x, hs_dx, hschars, initials, selected_initial,loghs, name_confirm

function _init()
  -- save file
  cartdata("picobricks")

  scene = "start"
  debug = ""

  parts = {}
  part_timer = 0
  part_row = 0

  levels = {
    "b3xb3xb3/xbxxh1b1h1xxbx/xpxxh1s1h1xxpx/b1h1b1xb3xb1h1b1",
    "x5b1x5/sbsbsbsbsbs",
    "b9b2/x1p9",
    "b9b2/b9b2/b9b2",
    "x5b1x5/x3s5x3",
    "x5b",
    "b9b2/b9b2/x9x2/x1i9",
  }
  level = 3
  
  lives = 1
  score = 0
  mult = 1

  -- screenshake intensity
  shake = 0

  -- powerup bar width
  powupbar_w = 0

  -- blink variables
  blink_f = 0
  blink_ci = 1

  -- menu animation helpers
  menu_cd = -1
  menu_blink_speed = 20
  menu_transition = 60

  -- gameover animation helpers
  go_cd = -1
  go_transition = 80

  -- fading percentage
  fade = 1

  -- preview arrow frame counter
  preview_f = 0

  -- ball momentum
  lasthit_x = 0
  lasthit_y = 0

  -- high score
  hs = {}
  hsc = {
    c1 = {},
    c2 = {},
    c3 = {} 
  }
  hsb = {true, false, false, false, false}
  hs_x = 128
  hs_dx = 128
  hschars = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"}
  --reseths()
  loadhs()

  -- initials typing
  loghs = true
  initials = {1, 1, 1}
  selected_initial = 1
  name_confirm = false

  --sash
  sash = {} 

  -- start screen
  logo_ox = 0
  logo_oy = 0
  start_parts()
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
  parts = {}
  chain = 1
  shake = 0

  pad = make_pad()
  build_bricks(levels[level], brick_w, brick_h, brick_offset)

  -- level begin sash
  show_sash("stage "..level, 12, 1)

  -- reset game
  serve_ball()
end

function islevelfinished()
 if #bricks == 0 then return true end
 
 for b in all(bricks) do
  if b.v == true and b.t != "i" then
   return false
  end
 end
 return true
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
  resethsb()
end

function levelover()
  scene = "leveloverwait"
  go_cd = 15
end

function wingame()
  scene = "winscreenwait"
  go_cd = 120
  level = 1

  -- is score good enough for high scores
  if score > hs[5] then
    loghs = true
    selected_initial = 1
    name_confirm = false
  else
    loghs = false
    resethsb()
  end
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

function hit_brick(b, ball, combo)
  -- check brick type on hit and apply behavior based on it

  local flash_t = 8
  b.ox = ball.vx
  b.oy = ball.vy

  if b.t == "b" then
    sfx(3 + (chain - 1))
    if combo then
      score += (b.pts * chain) * mult
      boost_combo()
    end
    b.flash = flash_t
    b.v = false
    shatter_brick(b, lasthit_x, lasthit_y)
  elseif b.t == 's' then
    b.t = "rex"
    sfx(3 + (chain - 1))
    --shatter_brick(b, lasthit_x, lasthit_y)
    if combo then
      score += (b.pts * chain) * mult
      boost_combo()
    end
  elseif b.t == "h" then
    if powerup == "meg" then
      if combo then
        score += (b.pts * chain) * mult
        chain += 1
        chain = mid(1, chain, 8)
      end
      b.flash = flash_t
      b.v = false
      shatter_brick(b, lasthit_x, lasthit_y)
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
      boost_combo()
    end
    b:spawn_pill()
    b.flash = flash_t
    b.v = false
    shatter_brick(b, lasthit_x, lasthit_y)
  end
end

function boost_combo()
  if chain >= 7 then
    show_sash("sick combo!", 10, 9)
  elseif chain >= 5 then
    show_sash("you got it brah!", 0, 9, 4)
  end

  chain += 1
  chain = mid(1, chain, 8)
end


function check_explosions()
  -- check if bricks will explode
  for brick in all(bricks) do
    if brick.t == "rex" then
      brick.t = "ex"
    elseif brick.t == "ex" and brick.v then
      explode_bricks(brick)
      spawn_explosion(brick.x, brick.y)
      sfx(14)
      if (shake < 0.4) shake += 0.1
    elseif brick.t == "rex" then
      brick.t = "ex"
    end 
  end
end

function explode_bricks(b)
  b.v = false
  for ball in all(balls) do
    -- explosion spread management
    for brick in all(bricks) do
      if brick.id != b.id and brick.v and abs(brick.x - b.x) <= brick.w + 1 and abs(brick.y - b.y) <= brick.h + 1 then
        hit_brick(brick, ball, false)
      end
    end
  end
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

  for part in all(parts) do
    part:update()
  end

  if scene == "game" then
    update_game()
  elseif scene == "start" then
    update_start()
  elseif scene == "gameoverwait" then
    update_gameoverwait()
  elseif scene == "gameover" then
    update_gameover()
  elseif scene == "leveloverwait" then
    update_leveloverwait()
  elseif scene == "levelend" then
    update_levelend()
  elseif scene == "winscreenwait" then
    update_winscreenwait()
  elseif scene == "winscreen" then
    update_winscreen()
  end
end

function update_game()
  check_explosions()

  powupbar_w = 100 / powerup_t 

  sash:update()

  for ball in all(balls) do
    ball:update()
  end

  pad:update()

  for brick in all(bricks) do
    brick:update()
    brick:set_type()
    brick:animate()
  end

  for pow in all(powups) do
    pow:update()
  end

  if islevelfinished() then
    _draw()
    if level == #levels then
      wingame()
    else
      levelover()
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
  part_timer += 1
  if part_timer % 60 == 0 then
    logo_ox = -2 + flr(rnd(3))
    logo_oy = -2 + flr(rnd(3))
  else
    logo_ox = 0
    logo_oy = 0
  end

  logo_ox = mid(-2, logo_ox, 2)
  logo_oy = mid(-2, logo_oy, 2)

  spawn_bg_parts(true, part_timer)

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
      parts = {}
    end
  end

  if hs_x != hs_dx then
    hs_x += (hs_dx - hs_x) / 5
    if abs(hs_dx-hs_x) < 0.3 then
      hs_x=hs_dx
    end
  end

  if btnp(0) then
    if hs_dx != 0 then
      sfx(19)
      hs_dx = 0
    else
      sfx(17)
    end
  end

  if btnp(1) then
    if hs_dx != 128 then
      sfx(19)
      hs_dx = 128
    else
      sfx(17)
    end
  end
end

function update_gameover()
  spawn_sash_smoke(43, 86, {8, 8, 2}, 120)

  menu_blink_speed = 20
  if go_cd < 0 then
    if (btnp(5)) then
      go_cd = go_transition
      sfx(15)
    end
  else
    go_cd -= 1
    menu_blink_speed = 5
    fade = (go_transition - go_cd) / go_transition
    if go_cd <= 0 then
      go_cd = -1
      scene = "start"
      parts = {}
      start_parts()
    end
  end
end

function update_gameoverwait()
  go_cd -= 1

  if go_cd <= 0 then
    go_cd = -1
    scene = "gameover"
  end
end

function update_leveloverwait()
  go_cd -= 1

  if go_cd <= 0 then
    go_cd = -1
    scene = "levelend"
  end
end

function update_levelend()
  spawn_sash_smoke(43, 86, {12, 12, 1}, 120)

  menu_blink_speed = 20
  if go_cd < 0 then
    if (btnp(5)) then
      go_cd = go_transition
      sfx(15)
    end
  else
    go_cd -= 1
    fade = (go_transition - go_cd) / go_transition
    if go_cd <= 0 then
      menu_blink_speed = 5
      go_cd = -1
      nextlevel()
    end
  end
end

function update_winscreenwait()
  go_cd -= 1

  if (go_cd <= 20) fade = (go_transition - go_cd) / go_transition

  if go_cd <= 0 then
    go_cd = -1
    scene = "winscreen"
  end
end

function update_winscreen()
  menu_blink_speed = 30

  if go_cd < 0 then
    if loghs then

      -- select previous initial
      if btnp(0) then
        name_confirm = false
        selected_initial -= 1
        if (selected_initial < 1) selected_initial = 3
        sfx(16)

      -- select next initial
      elseif btnp(1) then
        name_confirm = false
        selected_initial += 1
        if (selected_initial > 3) selected_initial = 1
        sfx(16)

      -- move down in alphabet
      elseif btnp(2) then
        name_confirm = false
        initials[selected_initial] -= 1
        if (initials[selected_initial] < 1) initials[selected_initial] = #hschars
        sfx(18)

      -- move up in alphabet
      elseif btnp(3) then
        name_confirm = false
        initials[selected_initial] += 1
        if (initials[selected_initial] > #hschars) initials[selected_initial] = 1
        sfx(18)

      -- cancel name confirmation
      elseif btnp(4) then
        name_confirm = false
        sfx(17)

      -- first press -> confirm modal
      -- second press -> return to title
      elseif btnp(5) then
        if name_confirm then
          addhs(score, initials[1], initials[2], initials[3])
          savehs()
          go_cd = go_transition
          sfx(15)
        else
          name_confirm = true
          sfx(16)
        end
      end
    else
      if (btnp(5)) then
        go_cd = go_transition
        sfx(15)
      end
    end
  else
    go_cd -= 1
    menu_blink_speed = 5
    fade = (go_transition - go_cd) / go_transition

    if go_cd <= 0 then
      go_cd = -1
      scene = "start"
      parts = {}
      start_parts()
      hs_x = 128
      hs_dx = 0
    end
  end
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
  elseif scene == "leveloverwait" then
    draw_game()
  elseif scene == "levelend" then
    draw_levelend()
  elseif scene == "winscreenwait" then
    draw_game()
  elseif scene == "winscreen" then
    draw_winscreen()
  end

  -- fade screen
  pal()
  if (fade != 0) fadepal(fade)

  -- show fps
  --print("fps: "..stat(7), 100, 120, 7)
  -- debug text
  if (debug != "") print(debug, 100, 120, 6)
end

function draw_game()
  cls()
  map(0, 0, 0, 0, 16, 16)

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
  draw_parts()

  sash:draw()
end

function draw_start()
  local title = "picobricks"
  local subtitle = "alpha version" 
  local cta = "press ❎ to start"
  local hs_show = "⬅️ high scores"
  local hs_hide = "➡️ hide scores"
  cls()

  draw_parts()

  spr(69, 36 + logo_ox + (hs_x - 128), 12 + logo_oy, 7, 5)
  --print(title, 64 - (#title / 2) * 4, 16, 8)
  print(subtitle, 64 - (#subtitle / 2) * 4, 120, 1)
  print(cta, 64 - (#cta / 2) * 4, 100, blink_text(menu_blink_speed, {1, 12}))
  print(hs_show, (64 - (#hs_show / 2) * 4) + (hs_x - 128), 64, 8)
  print(hs_hide, (64 - (#hs_hide / 2) * 4) + (hs_x), 16, 6)

  drawhs(hs_x)
  
end

function draw_gameover()
  local go_text = "game over !"
  local score_text = "your score: "..score
  local cta = "press ❎ to try again"
  draw_game()
  rectfill(-8, 43, 128, 85, 8)
  print(go_text, 64 - (#go_text / 2) * 4, 48, 0)
  print(score_text, 64 - (#score_text / 2) * 4, 56, 2)
  print(cta, 64 - (#cta / 2) * 4, 72, blink_text(menu_blink_speed, {2, 0}))
end

function draw_levelend()
  local lo_text = "stage clear !"
  local cta = "press ❎ to continue"
  local score_text = "your score: "..score
  draw_game()
  rectfill(-8, 43, 128, 85, 12)
  print(lo_text, 64 - (#lo_text / 2) * 4, 48, 7)
  print(score_text, 64 - (#score_text / 2) * 4, 56, 1)
  print(cta, 64 - (#cta / 2) * 4, 72, blink_text(menu_blink_speed, {1, 6}))
end

function draw_winscreen()
  cls()
  map(0, 0, 0, 0, 16, 16)
  local win_text = "★ congratulations ★"
  local win_text2 = "you have beaten the game"
  local nohs_text = "but you don't deserve a place"
  local nohs_text2 = "in the hall of fame"
  local hs_text = "enter your initials"
  local hs_text2 = "for the hall of fame"
  local hint_text = "⬅️➡️⬆️⬇️ move"
  local hint_text2 = "❎ confirm  🅾️ cancel"
  local cta = "press ❎ to confirm"
  local score_text = "your score: "..score
  
  print(win_text, 22, 16, 14)
  print(win_text2, 64 - (#win_text2 / 2) * 4, 24, 6)

  if loghs then
    -- won and beat lowest high score
    print(score_text, 64 - (#score_text / 2) * 4, 40, 11)
    print(hs_text, 64 - (#hs_text / 2) * 4, 56, 6)
    print(hs_text2, 64 - (#hs_text2 / 2) * 4, 64, 6)

    local colors = {6 ,6 ,6}
    if name_confirm then
      local blink = blink_text(menu_blink_speed, {4, 9})
      colors = {blink ,blink ,blink}
    else
      colors[selected_initial] = blink_text(menu_blink_speed, {4, 9})
    end

    print(hschars[initials[1]], 58, 82, colors[1])
    print(hschars[initials[2]], 62, 82, colors[2])
    print(hschars[initials[3]], 66, 82, colors[3])

    if name_confirm then
      print(cta, 64 - (#cta / 2) * 4, 104, blink_text(menu_blink_speed, {4, 9}))
    else
      print(hint_text, 16, 104, 3)
      print(hint_text2, 16, 112, 3)
    end
  else
    -- won but score not high enough
    cta = "press ❎ to continue"
    print(score_text, 64 - (#score_text / 2) * 4, 48, 8)
    print(nohs_text, 64 - (#nohs_text / 2) * 4, 64, 6)
    print(nohs_text2, 64 - (#nohs_text2 / 2) * 4, 72, 6)
    print(cta, 64 - (#cta / 2) * 4, 104, blink_text(menu_blink_speed, {4, 9}))
  end
end

function draw_ui()
  rectfill(0, 0, 127, 8, 0)
  for i=1,lives do print("♥", 4 + 8*i - 8, 2, 8) end
  handle_score()
  draw_powup_timer()
end

function draw_powup_timer()
  if powerup != "" then
    palt(0, false)
    palt(15, true)
    spr(powerup_s, 4, 118)
    palt()
    print((powerup_t + 1) / 60, 16, 119, 7)
  end
end

function drawhs(x)
  for i = 1, 5 do
    local hst = "high scores"
    local hscol = 7
    if (hsb[i]) hscol = blink_text(menu_blink_speed, {2, 8})
    local name = hschars[hsc.c1[i]]..hschars[hsc.c2[i]]..hschars[hsc.c3[i]]
    rectfill(x + 32, 32, x + 98, 44, 8)
    print(hst, x + 66 - (#hst / 2) * 4, 36, 0)
    -- rank + name
    print(i.."    "..name, x + 32, 44 + (i * 8), hscol)
    -- score
    local score = " "..hs[i]
    print(score, x + 100 - (#score * 4), 44 + (i * 8), hscol)
  end
end

function draw_parts()
  for part in all(parts) do
    part:draw()
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
    w = 6,
    h = 6,
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
          spawn_pufft(nextx, nexty)
        end
        if nexty <= 8 + self.r then 
          nexty = mid(0, nexty, 127)
          self.vy = -self.vy
          sfx(0)
          spawn_pufft(nextx, nexty)
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

          spawn_pufft(nextx, nexty)
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
          if brick.v and self:bounce(nextx, nexty, brick) then
            -- check if ball hits brick
            -- find out which direction ball will deflect
            if not brick_hit then
              if (powerup == "meg" and brick.t == "i") or powerup != "meg" then
                -- save ball momentum on impact
                lasthit_x = self.vx
                lasthit_y = self.vy

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
              brick_hit = true

              hit_brick(brick, self, true)
            end
          end

          self.x = nextx
          self.y = nexty
        end

        -- trail particles
        --if (powerup == "meg") spawn_trail(nextx, nexty)
        spawn_trail(nextx, nexty, 1)
      end

      -- ball falls out of screen
      if self.y > 127 then
        spawn_death(self.x, self.y)
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
    end,

    draw = function(self)

      -- manage ball sprite
      if powerup == "meg" then
        palt(0, false)
        palt(15, true)
        self.s = 17
        self.w = 7
        self.h = 7
      else
        self.s = 16
        self.w = 6
        self.h = 6
      end

      spr(self.s, self.x - self.r, self.y - self.r)
      palt()

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
        self.w = 12
      else
        self.w = 24
      end
    end,

    -- draw paddle based on its size
    draw = function(self)
      sspr(0, 16, 5, 6, self.x, self.y)
      sspr(8, 16, 5, 6, self.x + self.w - 4, self.y)

      for i = 5, self.w - 5 do
        sspr(5, 16, 1, 6, self.x + i, self.y)
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
    dx = 0,
    dy = 1 + flr(rnd(64)),
    ox = 0,
    oy = -(128 + flr(rnd(32))),
    w = w,
    h = h,
    t = t,
    c = 0,
    sx = 0,
    sy = 0,
    pts = 0,
    flash = 0,
    v = true,

    update = function(self)
    end,

    draw = function(self)
      palt(0, false)
      self.flash -= 1

      -- bounce calculation
      local bx = self.x + self.ox
      local by = self.y + self.oy
      if self.v or self.flash > 0 then
        sspr(self.sx, self.sy, self.w, self.h, bx, by)
        if self.flash > 0 then
          self.flash -= 1
        end
      end
      palt()
    end,

    set_type = function(self)
      
      if self.flash > 0 then
        self.c = 7
        self.sx = 58
      elseif self.t == "b" then
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
    end,

    animate = function(self)
      if self.v or self.flash > 0 then
        -- check if brick is moving
        if self.dx != 0 or self.dy != 0 or
           self.ox != 0 or self.oy != 0 then
           -- apply speed
          self.ox += self.dx
          self.oy += self.dy

          -- change the speed
          -- brick wants to go to zero
          self.dx -= self.ox / 10
          self.dy -= self.oy / 10

          -- dampening
          if (abs(self.dx) > abs(self.ox)) self.dx /= 1.5
          if (abs(self.dy) > abs(self.oy)) self.dy /= 1.5

          -- snap position to zero if close
          if abs(self.ox) < 0.5 and abs(self.dx) < 0.25 then
            self.ox = 0
            self.dx = 0
          end

          if abs(self.oy) < 0.5 and abs(self.dy) < 0.25 then
            self.oy = 0
            self.dy = 0
          end
        end
      end
    end
  }

  return brick
end

function make_powup(t, x, y)
  local pow = {
    x = x,
    y = y,
    vy = 0.7,
    w = 8,
    h = 8,
    s = 0,
    c = {},
    t = t,

    update = function(self)
      self.y += self.vy

      -- delete pill when it exits screen
      if (self.y >= 128) del(powups, self)

      if collide(self, pad) then
        self:activate()
        spawn_colored_smoke(self.x, self.y, self.c)
        sfx(12)
        del(powups, self)
      end
    end,

    draw = function(self)
      -- pill sprite management
      if self.t == "spd" then
        self.s = 48
        self.c = {9, 4}
      elseif self.t == "1up" then
        self.s = 49
        self.c = {7, 13}
      elseif self.t == "sty" then
        self.s = 50
        self.c = {11, 3}
      elseif self.t == "exp" then
        self.s = 51
        self.c = {12, 1}
      elseif self.t == "rdc" then
        self.s = 52
        self.c = {5, 0}
      elseif self.t == "meg" then
        self.s = 53
        self.c = {8, 2}
      elseif self.t == "mlt" then
        self.s = 54
        self.c = {10, 9}
      end
      palt(0, false)
      palt(15, true)
      spr(self.s, self.x, self.y)
      palt()
    end,


    -- set active powerup type, and duration
    activate = function(self)
      if self.t == "spd" then     -- speed down
        -- slow down ball
        show_sash('za warudo !', self.c[1], self.c[2])
        self:reset(self.t, 300)
      elseif self.t == "1up" then -- extra life
        show_sash('extra life', self.c[1], self.c[2])
        lives += 1
      elseif self.t == "sty" then -- sticky ball
        show_sash('sticky ballz', self.c[1], self.c[2])
        local has_stuck = false
        for ball in all(balls) do
          if (ball.stuck) has_stuck = true
        end

        if (not has_stuck) pad.sticky = true
      elseif self.t == "exp" then -- expand paddle
        show_sash('enlarge your paddle', self.c[1], self.c[2])
        self:reset(self.t, 600)
        -- expand paddle
      elseif self.t == "rdc" then -- shrink paddle
        show_sash('get rekt', self.c[1], self.c[2])
        self:reset(self.t, 600)
        -- reduce paddle
      elseif self.t == "meg" then -- megaball
        show_sash('mayhem time !', self.c[1], self.c[2])
        self:reset(self.t, 180)
        -- megaball
      elseif self.t == "mlt" then -- multiball
        -- multiball
        show_sash('kage ballshin no jutsu', self.c[1], self.c[2])
        pad: release_ball()
        multiball()
      end
    end,

    reset = function(self, type, timer)
      powerup = type
      powerup_t = timer
      powerup_s = self.s
    end
  }

  return pow
end

-- particles types
-- 0 -> pixel
-- 1 -> gravity pixel
-- 2 -> smoke puffs
-- 3 -> rotating sprite
-- 4 -> colored sprite
function make_part(x, y, dx, dy, t, mage, colors, size)
  local part = {
    x = x,
    y = y,
    dx = dx,
    dy = dy,
    t = t,
    colors = colors,
    c = colors[1],
    age = 0,
    mage = mage,
    rot = 0,
    rot_timer = 0,
    sz = size,
    osz = size,

    update = function(self)
      self.age += 1

      -- particle gets old and die
      if self.age >= self.mage or
         self.x < -20 or self.x > 148 or
         self.y < -20 or self.y > 148 then
        del(parts, self)
      end

      -- change color
      if #self.colors == 1 then
        self.c = self.colors[1]
      else
        local ci = 1 + flr((self.age / self.mage) * #colors)
        self.c = self.colors[ci]
      end

      -- gravity
      if (self.t == 1 or self.t == 3) self.dy += 0.075

      --rotation
      if self.t == 3 then
        self.rot_timer += 1

        if self.rot_timer > 60 then
          self.rot += 1

          if (self.rot > 4) self.rot = 0
        end
      end

      -- shrink
      if self.t == 2 then
        local ci = 1 - (self.age / self.mage)
        self.sz = ci * self.osz
      end

      -- friction
      if self.t == 2 then
        self.dx = self.dx / 1.2
        self.dy = self.dy / 1.2
      end

      -- velocity
      self.x += self.dx
      self.y += self.dy
    end,

    draw = function(self)
      --pixel particle
      if self.t == 0 or self.t == 1 then
        pset(self.x, self.y, self.c)
      elseif self.t == 2 then
        circfill(self.x, self.y, self.sz, self.c)
      elseif self.t == 3 or self.t == 4 then
        local fx, fy

        if self.rot == 2 then
          fx = false
          fy = true
        elseif self.rot == 3 then
          fx = true
          fy = true
        elseif self.rot == 4 then
          fx = true
          fy = false
        else
          fx = false
          fy = false
        end

        if (self.t == 4) pal(7, 1)

        spr(self.c, self.x, self.y, 1, 1, fx, fy)
        pal()
      end
    end
  }
  add(parts, part)
end

-->8
------ juicyness ------

function show_sash(_t, _c, _tc)
  sash = {
    w = 0,
    dw = 4,
    t = _t,
    tx = -#_t * 4,
    tdx = 64 - (#_t * 2), 
    c = _c,
    tc = _tc,
    frames = 0,
    v = true,
    delay_w = 0,
    delay_t = 5,

    update = function(self)
      if self.v then
        self.frames += 1

        -- animate width
        if self.delay_w > 0 then
          spawn_sash_smoke(64 - self.w, 64 + self.w, {_c, _c, 5}, 60)
          self.delay_w -= 1
        else
          self.w += (self.dw - self.w) / 4
        end

        if (abs(self.dw - self.w) < 0.3) self.w = self.dw

        -- make sash go away
        if self.frames == 60 then
          self.dw = 0
          self.tdx = 140
          self.delay_w = 15
          self.delay_t = 0
        end
        if(self.frames > 90) self.v = false

        --animate text
        if self.delay_t > 0 then
          self.delay_t -= 1
        else
          self.tx += (self.tdx - self.tx) / 8
        end

        if (abs(self.tdx - self.tx) < 0.3) self.tx = self.tdx
      end
    end,

    draw = function(self)
      if self.v then
        rectfill(0, 64 - self.w, 128, 64 + self.w, self.c)
        print(self.t, self.tx, 62, self.tc)
      end
    end
  }
end

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

function start_parts(y, t)
  for i = 0, 300 do
    spawn_bg_parts(false, i)
  end
end

function spawn_bg_parts(top, t)
  if t % 30 == 0 then
    if part_row == 0 then
      part_row = 1
    else
      part_row = 0
    end

    for i = 0, 8 do
      if top then
        y = -8
      else
        y = -8 + 0.4 * t
      end

      if (i + part_row) % 2 == 0 then
        make_part(i * 16, y, 0, 0.4, 0, 512, {1}, 0)
      else
        make_part((i * 16) - 2, y - 2, 0, 0.4, 4, 512, {64 + flr(rnd(5))}, 0)
      end
    end
  end


  if t % 15 == 0 then
    if top then
      y = -8
    else
      y = -8 + 0.8 * t
    end
    for i = 0, 8 do
      make_part(8 + i * 16, y, 0, 0.8, 0, 512, {1}, 0)
    end
  end
end

function spawn_trail(x, y, rate)
  for ball in all(balls) do
    if rnd() < rate then
      local ang = rnd()
      local ox = sin(ang) * 2 * 0.3
      local oy = cos(ang) * 2 * 0.3
      
      if powerup == "meg" then
        ox = sin(ang) * 2
        oy = cos(ang) * 2
        make_part(x + ox, y + oy, 0, 0, 2, 30 + rnd(10), {8, 5, 0}, 1 + rnd(1))
      else
        make_part(x + ox, y + oy, 0, 0, 0, 10 + rnd(10), {10, 9, 8}, 0)
      end
    end
  end
end

function spawn_pufft(x, y)
  for i = 0, 5 do
    local ang = rnd()
    local dx = sin(ang) * 1.5
    local dy = cos(ang) * 1.5
    make_part(x, y, dx ,dy, 2, 15 + rnd(15), {7, 6, 5}, 1 + rnd(2))
  end
end

function spawn_colored_smoke(x, y, c)
  for i = 0, 20 do
    local ang = rnd()
    local dx = sin(ang) * 2
    local dy = cos(ang) * 2 
    make_part(x, y, dx ,dy, 2, 30 + rnd(15), c, 1 + rnd(4))
  end
end

function spawn_death(x, y)
  for i = 0, 30 do
    local ang = rnd()
    local dy = cos(ang) * (2 + rnd(4))
    local dx = sin(ang) * (2 + rnd(4))
    make_part(x, y, dx ,dy, 2, 80 + rnd(15), {10, 9, 8, 0}, 2 + rnd(4))
  end
end

function spawn_explosion(x, y)
  for i = 0, 20 do
    local ang = rnd()
    local dy = cos(ang) * rnd(4)
    local dx = sin(ang) * rnd(4)
    make_part(x, y, dx ,dy, 2, 80 + rnd(15), {0, 0, 5, 5, 6}, 3 + rnd(6))
  end

  for i = 0, 30 do
    local ang = rnd()
    local dy = cos(ang) * (1 + rnd(4))
    local dx = sin(ang) * (1 + rnd(4))
    make_part(x, y, dx ,dy, 2, 15 + rnd(15), {7, 10, 9, 8, 5}, 2 + rnd(4))
  end
end

function spawn_sash_smoke(ty, by, colors, time)
  local ang = rnd()
  local dy = cos(ang) * rnd(1)
  local dx = sin(ang) * rnd(1)
  make_part(flr(rnd(128)), ty, dx ,dy, 2, time + rnd(15), colors, 4 + rnd(6))
  make_part(flr(rnd(128)), by, dx ,dy, 2, time + rnd(15), colors, 4 + rnd(6))
end

function shatter_brick(b, vx, vy)
  if shake < 0.5 then
    shake += 0.07
  end
  sfx(14)

  b.dx = vx
  b.dy = vy
  for _x = 0, b.w do
    for _y = 0, b.h do
      if rnd() < 0.5 then
        local ang = rnd()
        local dx = sin(ang) * rnd(2) + vx
        local dy = cos(ang) * rnd(2) + vy
        make_part(b.x + _x, b.y + _y, dx ,dy, 1, 60, {7, 6, 5}, 0)
      end
    end
  end

  local chunks = 3 + flr(rnd(3))
  if chunks > 0 then
    for i = 1, chunks do
      local ang = rnd()
      local dx = sin(ang) * rnd(2) + vx
      local dy = cos(ang) * rnd(2) + vy
      local spr = 64 + flr(rnd(5))
      make_part(b.x, b.y, dx, dy, 3, 60, {spr}, 0)
    end
  end
end

-->8
------ high score ------

-- reset high scores
function reseths()
  -- create default data
  hs = {1000, 5000, 7500, 10000, 2500}
  hsc.c1 = {13, 15, 23, 12, 6}
  hsc.c2 = {1, 13, 20, 15, 1}
  hsc.c3 = {24, 7, 6, 12, 11}
  hsb = {true, false, false, false, false}
  sorths()
  savehs()
end

function resethsb()
  for hs in all(hsb) do
    hs = false
  end

  hsb[1] = true
end

function loadhs()
  local slot = 0

  if dget(0) == 1 then
    -- load data
    slot += 1
    for i = 1, 5 do
      hs[i] = dget(slot)
      hsc.c1[i] = dget(slot + 1)
      hsc.c2[i] = dget(slot + 2)
      hsc.c3[i] = dget(slot + 3)

      slot += 4
    end
    sorths()
  else
    -- file is empty
    reseths()
  end
end

function savehs()
  local slot
  -- proof that list is not empty
  dset(0, 1)

  -- save data
  slot = 1
  for i = 1, 5 do
    dset(slot, hs[i])
    dset(slot + 1, hsc.c1[i])
    dset(slot + 2, hsc.c2[i])
    dset(slot + 3, hsc.c3[i])
    slot += 4
  end
end

function sorths()
  for i = 1, #hs do
    local j = i
    while j > 1 and hs[j - 1] < hs[j] do
      hs[j], hs[j - 1] = hs[j - 1], hs[j]
      hsc.c1[j], hsc.c1[j - 1] = hsc.c1[j - 1], hsc.c1[j]
      hsc.c2[j], hsc.c2[j - 1] = hsc.c2[j - 1], hsc.c2[j]
      hsc.c3[j], hsc.c3[j - 1] = hsc.c3[j - 1], hsc.c3[j]
      hsb[j], hsb[j - 1] = hsb[j - 1], hsb[j]
      j -= 1
    end
  end
end

function addhs(sc, c1, c2, c3)
  add(hs, sc)
  add(hsc.c1, c1)
  add(hsc.c2, c2)
  add(hsc.c3, c3)

  for i = 1, #hsb do
    hsb[i] = false
  end

  add(hsb, true)
  sorths()
end

__gfx__
00000000277777777717777777775aa55aa55a777666677777777777777777777777000000000000000000000000000000000000000000000000000000000011
000000002eeeeeeee71cccccccc7990099009966dddddd665d66dd66d77777777777000000000000000000000000000000000000000000000000000000001100
007007002eeeeeeee71cccccccc7900990099066dd11dd66566dd66dd77777777777000000000000000000000000000000000000000000000000000000010000
000770002eeeeeeee71cccccccc7009900990066dddddd6656dd66dd677777777777000000000000000000000000000000000000000000000000000000001100
00077000222222222711111111170440044004ddd5555ddd55555555577777777777000000000000000000000000000000000000000000000000000000010000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011100000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000001
0aaa0000ff888fff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaa7a000f80008ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a9aaa0008000708f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a999a0008050008f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aaa00008055508f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000f80008ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ff888fff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ddd0ddd0ddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d666d666d666d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d676d777d676d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d666d666d666d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d666d666d666d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ddd0ddd0ddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ff6677ffff6677ffff6677ffff6677ffff6677ffff6677ffff6677ff000000000000000000000000000000000000000000000000000000000000000000000000
f660077ff660077ff660077ff660077ff660077ff660077ff660077f000000000000000000000000000000000000000000000000000000000000000000000000
6609907766077077660bb077660cc0776605507766088077660aa077000000000000000000000000000000000000000000000000000000000000000000000000
6049790760d77707603b7b07601c7c076005750760287807609a7a07000000000000000000000000000000000000000000000000000000000000000000000000
5044990650dd77065033bb065011cc0650005506502288065099aa06000000000000000000000000000000000000000000000000000000000000000000000000
55044066550dd0665503306655011066550000665502206655099066000000000000000000000000000000000000000000000000000000000000000000000000
f550066ff550066ff550066ff550066ff550066ff550066ff550066f000000000000000000000000000000000000000000000000000000000000000000000000
ff5566ffff5566ffff5566ffff5566ffff5566ffff5566ffff5566ff000000000000000000000000000000000000000000000000000000000000000000000000
77700000070000000777000007700000777000000000000000000000000000000000000000000000000000000aaaa00000000000000000000000000000000000
7700000077700000777700007770000007700000000000000000000000070000000000000000000000000000aaaaaa0000000000000000000000000000000000
700000007700000000000000777700000070000000000000000000000000700000000000000000007007000aa7aaa9a000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000077000000000000000000000000aa7aaa9a000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000007700000000000000000000000aaaaa99a000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000007670000000000000000000000aaaa999a000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000007770000000000000000000700a9999a0000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000077770000000000000000007700aaaa00000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000777000007000000000007770000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000076700000707007007077777777000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000007770000000000000077777770000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000767007000000770077777700000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000700077700077000770077777000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000007670077700000777770000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000700777007770000777700000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000076700770700777000700000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000770700007670000007770007700000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000770000700767077007700707700000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000007700000000000077077007000000000700000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000700707770000777700007770000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000077000000000007770000777770007770070077000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000777777000000777777777770000000000000000000000000000000000000000000
00000000000000000000000000000000000000001111100111110011111000111001110111001110011101111111111100000000000000000000000000000000
00000000000000000000000000000000000000001777710177771017777101777101771771017771017717711777777100000000000000000000000000000000
00000000000000000000000000000000000000001ddddd11ddddd11dddd11ddddd11dd1dd11ddddd11dd1dd11dddddd100000000000000000000000000000000
00000000000000000000000000000000000000001dd1dd11dd1dd11dd1101dd1dd11dd1dd11dd1dd11dd1dd1111dd11100000000000000000000000000000000
00000000000000000000000000000000000000001666610166666116661016666611666610166166116616610016610000000000000000000000000000000000
00000000000000000000000000000000000000001666661166661016661016666611666610166166116616610016610000000000000000000000000000000000
00000000000000000000000000000000000000001771771177177117711017717711771771177177117717710017710000000000000000000000000000000000
00000000000000000000000000000000000000001777771177177117777117717711771771172222222272220222710000000000000000000000000000000000
00000000000000000000000000000000000000001777710177177117777117717711771771012888288828882888210000000000000000000000000000000000
00000000000000000000000000000000000000001111100111011011111011101111110111002828228228222828210000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000028882282282228228200000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000202022022222028222282282228282000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000028222888288828882000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000002020220222222222222222022202220000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
010200002a34030340303303032030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
010200002c34032340323303232030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
010200002e34034340343303432030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
010200003034036340363303632030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
010200003234038340383303832030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
01020000343403a3403a3303a32030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
01020000363403c3403c3303c32030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
01020000383403e3403e3303e32030300303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
010200003b5530c5020c5000c5000c5000c5000c5000c5000c5000c5020c5020c5000c50110501105000c5000e5000c5000e5020e5000e5010c5010c5000c5000c500005000b5000b5010c5010c5020c5020c502
0108000024344283352635429355283542b3550030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
0108000028055285402f0552f54027055275402f0552f54028035285202f0352f52027025275102f0252f51000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400003d6302d630206301c6301562013615106240f6150e6140d6150d614006000060000600006000060000600006000060000600006000060000600006000060000600000000000000000000000000000000
0106000026550290502b5502d0503055026534290352b5342d0353053426515290142b5152d014305150000500000000000000000000000000000000000000000000000000000000000000000000000000000000
01020000185501a550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800000305000000030520305203052000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200002455026550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000003610056100a6100a6100c6100f6101161013610166101661018610186101b6101b6101b6201d6201d6201d6201d6201d6201d6201d6201d6201d6201d6101b6101b61016610166100f6100a61003610
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
