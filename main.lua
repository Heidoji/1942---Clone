-- charger les tiles du fond
-- cherger les images des ennemis
-- charger les sons
-- faire un niveau
-- gerer les tirz
-- gerer les bonus
-- afficher un ecran d'accueil
-- gerer le score
-- gerer energie player
-- gerer les ennemis

io.stdout:setvbuf('no')

love.graphics.setDefaultFilter('nearest')

if arg[#arg] == "-debug" then
  require("mobdebug").start()
end

math.randomseed(love.timer.getTime())

-- Constantes
VITESSE_PLAYER= 5
VITESSE_TIR_PLAYER = -10
DECALAGE_TIR = 15

BORDURE_EXTENSION = 75 
HAUTEUR_SCORE = 0

-- Chargement des Tiles
imgTuiles = {}
imgExplode = {}
imgLifes = {}
imgChiffres = {}
local n

for n=1, 14 do
  imgTuiles[n] = love.graphics.newImage("images/tile_"..n..".png")
end

for n=1, 5 do
  imgExplode[n] = love.graphics.newImage("images/explode_"..n..".png")
end

for n=0, 3 do
  imgLifes[n] = love.graphics.newImage("images/life_"..n..".png") 
end

for n=0, 9 do
  imgChiffres[n] = love.graphics.newImage("images/chiffre_"..n..".png") 
end

imgScore = love.graphics.newImage("images/score_layout.png")
score_l = imgScore:getWidth()

-- Chargement des Sons
sonTirPlayer = love.audio.newSource("sons/sonTirPlayer.wav", "static")
sonExplode = love.audio.newSource("sons/explode_touch.wav", "static")

-- Création des listes
liste_sprites = {}
liste_tirs = {}
liste_enemies = {}

-- Création Joueur
player = {}

-- Création caméra
camera = {}
camera.x = 0
camera.y = 1
camera.vy = 1

-- Chargement niveau
map = require("map")
niveau = map.layers[1].data

function math.angle(x1, y1, x2, y2) 
  return math.atan2(y2 - y1, x2 - x1) 
end

function collide(a1, a2, a1_l, a1_h)
  if (a1==a2) then 
    return false 
  end
  
  local dx = a1.x - a2.x
  local dy = a1.y - a2.y
  
  if a1_l == 0 or a1_h == 0 then
    if (math.abs(dx) < a1.image:getWidth() + a2.image:getWidth()) then
      if (math.abs(dy) < a1.image:getWidth() + a2.image:getWidth()) then
        return true
      end
    end
  else
    if (math.abs(dx) < a1_l + a2.image:getWidth()) then
      if (math.abs(dy) < a1_h + a2.image:getWidth()) then
        return true
      end
    end
  end
  
  return false
end

function CalculScore(score)
  local temp_score = {}
  local temp
  local n
  
  for n = 1, 6 do
    temp = score % 10
    table.insert(temp_score, math.floor(temp))
    score = score/10
  end
  
  return temp_score
  
end

function CreateSprite(pNomImage,pX, pY)
  sprite = {}
  
  table.insert(liste_sprites, sprite)
  
  sprite.x = pX
  sprite.y = pY

  sprite.image = love.graphics.newImage("images/"..pNomImage..".png")
  sprite.l = sprite.image:getWidth()
  sprite.h = sprite.image:getHeight()
  sprite.supprime = false
  sprite.frame = 1
  sprite.listeFrames = {}
  sprite.maxFrame = 1
  
  return sprite
end

function CreateExplosion(pX, pY)
  local newExplosion = CreateSprite("explode_1", pX, pY)
  newExplosion.listeFrames = imgExplode
  newExplosion.maxFrame = 5
end

function CreateTir(pType, pNomImage, pX, pY, pVitesse_x, pVitesse_y)
  local tir = CreateSprite(pNomImage, pX, pY)
  
  tir.type = pType
  tir.vx = pVitesse_x
  tir.vy = pVitesse_y
  
  tir.supprime = false
  
  table.insert(liste_tirs, tir)
  sonTirPlayer:play()
  
end

function CreateEnemy(pType, pX, pY)
  
  enemy = CreateSprite("enemy_"..pType, pX, pY)
  
  enemy.x = pX
  enemy.y = pY
  
  enemy.type = pType
  enemy.supprime = false
  enemy.endormi = true
  enemy.chronotir = 0
  
  if pType == 1 then
    enemy.vx = 0
    enemy.vy = 1
    enemy.energie = 1
    enemy.score = 10
    enemy.frequence_tir = 250
  elseif pType == 2 then
    enemy.vx = 0
    enemy.vy = 2
    enemy.energie = 2
    enemy.score = 30
    enemy.frequence_tir = 150
  elseif pType == 3 then
    enemy.vx = 0
    enemy.vy = 3
    enemy.energie = 3
    enemy.score = 100
    enemy.frequence_tir = 400
  end
  
  table.insert(liste_enemies, enemy)
  
end

function love.load()
  love.window.setMode(1024, 700)
  love.window.setTitle("1942 - Gamecodeur")
  
  largeur = love.graphics.getWidth()
  hauteur = love.graphics.getHeight()
  
  player = CreateSprite("player", largeur / 2, hauteur /2)
  player.y = hauteur - player.h - HAUTEUR_SCORE
  player.tir = 1
  player.life = 3
  player.score = 0
  
  local n, m
  
  for n=0, 9 do
    CreateEnemy(1, largeur / 2 - n * 40, - n * 40)
    --CreateEnemy(1, largeur / 2 + n * 40, - 400 - n * 40)
    --CreateEnemy(2, largeur / 2 + n * 40, - 500 - n * 20)
    --CreateEnemy(2, largeur / 2 - n * 40, - 900 - n * 20)
  end
  
  --CreateEnemy(3, largeur / 2, 0)
  
end

function love.update(dt)
  update_enemies()
  update_tirs()
  update_sprites()
  update_clavier()
end

function update_tirs()
  local n
  local nEnemies
  
  for n = #liste_tirs, 1, -1 do
    local tir = liste_tirs[n]
    tir.x = tir.x + tir.vx
    tir.y = tir.y + tir.vy
    
    if tir.type == "enemy" then
      if collide(player, tir, 32, 32) then
        print("Boom, touché")
        player.life = player.life - 1
        tir.supprime = true
        table.remove(liste_tirs, n)
      end
    end
    
    if tir.type == "player" then
      for nEnemies = #liste_enemies, 1, -1 do
        local enemy = liste_enemies[nEnemies]
        if collide(enemy, tir, 0, 0) then
          CreateExplosion(tir.x, tir.y)
          tir.supprime = true
          table.remove(liste_tirs, n)
          enemy.energie = enemy.energie - 1
          sonExplode:play()
          if enemy.energie <= 0 then
            local nExplosion
            
            for nExplosion = 1, 5 do
              CreateExplosion(enemy.x + math.random(-10, 10), enemy.y + math.random(-10, 10))
              enemy.supprime = true
            end
            
            player.score = player.score + enemy.score
            table.remove(liste_enemies, nEnemies)
          end
        end
      end
    end
          
    if (tir.y < - 5 or tir.y > hauteur + 10 - HAUTEUR_SCORE) and tir.supprime == false then
      tir.supprime = true
      table.remove(liste_tirs, n)
    end
  end
end

function update_enemies()
  local n
  
  for n = #liste_enemies, 1, -1 do
    local enemy = liste_enemies[n]
    local vx, vy
    local angle
    
    if enemy.y >= -10 then
      enemy.endormi = false
    end
        
    if enemy.endormi == false then
      angle = math.angle(enemy.x, enemy.y, player.x, player.y)
      vx = 10 * math.cos(angle)
      vy = 10 * math.sin(angle)
      
      if enemy.type == 3 then
        enemy.x = enemy.x + vx / 2 
        enemy.y = enemy.y + vy / 2 + camera.vy
      else
        enemy.x = enemy.x + enemy.vx
        enemy.y = enemy.y + enemy.vy + camera.vy
      end
      
      enemy.chronotir = enemy.chronotir - 1

      update_enemies_tir(enemy, vx, vy)
      
      if collide(player, enemy, 32, 32) then
        CreateExplosion(enemy.x, enemy.y)
        player.life = player.life - 1
        enemy.energie = enemy.energie - 1
        if enemy.energie <= 0 then
          local nExplosion
            
            for nExplosion = 1, 5 do
              CreateExplosion(enemy.x + math.random(-10, 10), enemy.y + math.random(-10, 10))
              enemy.supprime = true
            end
            
            enemy.supprime = true
          table.remove(liste_enemies, n)
        end
      end
    else
      enemy.y = enemy.y + camera.vy
    end
    
    if enemy.y > hauteur + 10 - HAUTEUR_SCORE then
      enemy.supprime = true
      table.remove(liste_enemies, n)
    end
  end
end

function update_enemies_tir(pEnemy, pVx, pVy)
  if pEnemy.chronotir <= 0 then
    pEnemy.chronotir = math.random(enemy.frequence_tir- 25, enemy.frequence_tir + 25)
    CreateTir("enemy", "tir_enemy", pEnemy.x, pEnemy.y, pVx, pVy)
  end
end

function update_sprites()
  local n
  
  for n = #liste_sprites, 1, -1 do
    local sprite = liste_sprites[n]
    if sprite.maxFrame > 1 then
      sprite.frame = sprite.frame + 0.2
      if math.floor(sprite.frame) > sprite.maxFrame then
        sprite.supprime = true
      else
        sprite.image = sprite.listeFrames[math.floor(sprite.frame)]
      end
    end
    
    if sprite.supprime == true then
      table.remove(liste_sprites, n)
    end
  end
end

function update_clavier()
  if love.keyboard.isDown("right") and player.x < largeur + BORDURE_EXTENSION - player.l / 2 then
    if player.x > largeur - BORDURE_EXTENSION - camera.x and camera.x > - BORDURE_EXTENSION * 2 then  -- Permet le deplacement seulement quand l'avion s'approche d'un bord et pour un debattement double a la constante BORDURE_EXTENSION
      camera.x = camera.x - 5
    end
    player.x = player.x + VITESSE_PLAYER
  end
  if love.keyboard.isDown("left") and player.x > - BORDURE_EXTENSION + player.l / 2 then
    if player.x < BORDURE_EXTENSION - camera.x  and camera.x < BORDURE_EXTENSION * 2 then
      camera.x = camera.x + 5
    end
    player.x = player.x - VITESSE_PLAYER
  end
  if love.keyboard.isDown("up") and player.y > player.h / 2 then
    player.y = player.y - VITESSE_PLAYER
  end
  if love.keyboard.isDown("down") and player.y < hauteur - player.h  / 2 - HAUTEUR_SCORE then
    player.y = player.y + VITESSE_PLAYER
  end
end

function love.draw()
  local nbLignes = map.layers[1].height
  local ligne, colonne
  local x, y
  
  y = hauteur + camera.y
  x = 0
  camera.y = camera.y + camera.vy
  
  for ligne = nbLignes, 1, -1 do
    for colonne=1, map.layers[1].width do
      --Dessine la tuile
      local tuile = niveau[((ligne - 1) * map.layers[1].width) + colonne ]
      if tuile > 0 then
        love.graphics.draw(imgTuiles[tuile], x, y)
      end
      x = x + 32
    end
    x = 0
    y = y - 32
  end
  
  local n
  local score = {}

  for n=1, #liste_sprites do
    local s = liste_sprites[n]
    love.graphics.draw(s.image, s.x + camera.x, s.y, 0, 1, 1, s.l / 2, s.h / 2)
  end
  
  love.graphics.print("Total Sprite : "..#liste_sprites.." Total Tir : "..#liste_tirs.." score : "..player.score, 0, 0)
  love.graphics.draw(imgLifes[player.life], 5, hauteur - 50)
  love.graphics.draw(imgScore, largeur - score_l - 5, hauteur - 50)
  
  score = CalculScore(player.score)
  
  for n=1, #score do
    print(score[n])
    love.graphics.draw(imgChiffres[score[n]], largeur - 14 - n * 11, hauteur - 41)
  end
  
end

function love.keypressed(key)
  if key == "space" then
    CreateTir("player", "tir_player", player.x, player.y - player.h / 2 - DECALAGE_TIR / 2, 0 , VITESSE_TIR_PLAYER)
    if player.tir >= 2 then
      CreateTir("player", "tir_player", player.x + DECALAGE_TIR, player.y - player.h / 2, 0, VITESSE_TIR_PLAYER)
      CreateTir("player", "tir_player", player.x - DECALAGE_TIR, player.y - player.h / 2, 0, VITESSE_TIR_PLAYER)
      if player.tir >= 3 then
        CreateTir("player", "tir_playerD", player.x + DECALAGE_TIR * 3, player.y - player.h / 2, - VITESSE_TIR_PLAYER, VITESSE_TIR_PLAYER)
        CreateTir("player", "tir_playerG", player.x - DECALAGE_TIR * 3, player.y - player.h / 2, VITESSE_TIR_PLAYER, VITESSE_TIR_PLAYER)
        if player.tir >=4 then
          CreateTir("player", "tir_player", player.x + DECALAGE_TIR * 2, player.y - player.h / 2 + DECALAGE_TIR / 2, 0, VITESSE_TIR_PLAYER)
          CreateTir("player", "tir_player", player.x - DECALAGE_TIR * 2, player.y - player.h / 2 + DECALAGE_TIR / 2, 0, VITESSE_TIR_PLAYER)
          if player.tir >=4 then
            CreateTir("player", "tir_playerD", player.x + DECALAGE_TIR * 4, player.y - player.h / 2, - VITESSE_TIR_PLAYER, VITESSE_TIR_PLAYER)
            CreateTir("player", "tir_playerG", player.x - DECALAGE_TIR * 4, player.y - player.h / 2, VITESSE_TIR_PLAYER, VITESSE_TIR_PLAYER)
          end
        end
      end
    end
  end
end
