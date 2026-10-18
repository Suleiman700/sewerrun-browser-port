property w3d, hk, pCDDownList, pCDForwardList, pOppInfoNum, pCam, pMouse, pIntro, pBoarder, pDummyNull, pSky, pShield, pFlow, pPowerUp, pSurface, pAnimFrames, pCourse, pTrick, pRacePos, pCheckpoint, pPhoto, pVideo, pWeapon, pIcon, pSlalom, pBoost, pBomb, pRoller, pExplosion, pBombTrail, pFPS, upvector, upkey, downkey, leftkey, rightkey, grabkey, trickkey, pCamFollow, pPhase, pAutoPhase, pRace, pTopSpeed
global gGame, gUser, gOpponent, gPaused, gTimeFactor, gFPSFactor, gGameState, _DEBUG

on beginSprite me
  repeat with i = 30 to 45
    if member(i).type = #shockwave3d then
      member(i).resetWorld()
    end if
  end repeat
  sprite(2).memberNum = member(34 + gGame.course)
  w3d = sprite(2).member
  w3d.directionalPreset = #bottomLeft
  hk = sprite(me.spriteNum).pHavok
  hk.Initialize(w3d, 10, 0.10000000000000001)
  hk.gravity = vector(0, -8000, 0)
  setupDebug()
  setupGame()
  setupCourse(me)
  setupCharacter(me)
  setupWeapons(me)
  setupSurfaces()
  setupCamera()
  startGame()
  gGameState = #game
end

on setupDebug
  pAutoPhase = 1
  pRace = 1
  pCamFollow = 1
  pPhase = #freeride
end

on startGame
  pIntro.time = the milliSeconds
  mem = member("skate")
  mend = mem.duration
  if sound(3).status <> 0 then
    sound(3).stop()
  end if
  sound(3).volume = 0
  sound(3).play([#member: mem, #loopCount: 5000])
end

on setupGame
  pMouse = [#x: _mouse.mouseH, #y: _mouse.mouseV]
  pFPS = [#rate: 30, #count: 0, #time: the milliSeconds, #factor: 1.0]
  pIntro = [#mode: #hold, #time: the milliSeconds, #release: gGame.boarderTotal]
  pTrick = [#prevTime: 0, #grabTime: 0, #num: [], #time: [], #type: []]
  pRacePos = []
  pTime = 0
  upvector = vector(0, 1, 0.001)
  pos = []
  axis = []
  txt = member("checkpoints" & gGame.course).text
  repeat with i = 1 to txt.line.count
    pos.add(value(txt.line[i]))
    axis.add(value(txt.line[i + 1]))
    i = i + 1
  end repeat
  pCheckpoint = [#pos: pos, #axis: axis]
  pos = []
  active = []
  txt = member("photos" & gGame.course).text
  repeat with i = 1 to txt.line.count
    pos.add(value(txt.line[i]))
    active.add(1)
  end repeat
  pPhoto = [#pos: pos, #active: active, #icon: [], #time: 0]
  pos = []
  active = []
  txt = member("slalom" & gGame.course).text
  repeat with i = 1 to txt.line.count
    pos.add(value(txt.line[i]))
    active.add(1)
  end repeat
  pSlalom = [#pos: pos, #active: active, #icon: [], #time: 0]
  pos = []
  active = []
  txt = member("weapons" & gGame.course).text
  repeat with i = 1 to txt.line.count
    pos.add(value(txt.line[i]))
    active.add(1)
  end repeat
  if gGame.challenge = #battle then
    txt = member("weaponsx" & gGame.course).text
    repeat with i = 1 to txt.line.count
      pos.add(value(txt.line[i]))
      active.add(1)
    end repeat
  end if
  pWeapon = [#pos: pos, #active: active, #type: [], #icon: [], #range: [10000, 30000], #mortarPower: 80]
end

on setupCourse me
  skyboxes = ["Sky01", "Sky01", "Sky01", "Sky02", "Sky02", "Sky02", "Sky03", "Sky03", "Sky03"]
  skyBox = w3d.model(skyboxes[gGame.course])
  pSky = [#box: skyBox, #origZ: skyBox.worldPosition.z, #origY: skyBox.worldPosition.z]
  courses = ["Track01Sky01", "Track02Sky01", "Track03Sky01", "Track01Sky02", "Track02Sky02", "Track03Sky02", "Track01Sky03", "Track02Sky03", "Track03Sky03"]
  pCourse = courses[gGame.course]
  pHKs = [pCourse, "Kicker", "Outlet", "Shield"]
  pVideo = [#pos: [], #active: [], #icon: [], #cam: [], #time: 0]
  pBoost = [#pos: [], #active: [], #icon: [], #time: 0]
  pShield = []
  delModels = []
  repeat with i = 1 to w3d.model.count
    m = w3d.model[i]
    hkObject = 0
    repeat with j = 1 to pHKs.count
      mNme = chars(m.name, 1, pHKs[j].length)
      if pHKs[j] = mNme then
        hkObject = 1
        hkNum = j
        exit repeat
      end if
    end repeat
    if hkObject then
      if chars(m.name, 1, 6) = "Shield" then
        p = chars(string(m.parent), 1, 1)
        if p = "m" then
          w3d.group("World").addChild(m, #preserveWorld)
        end if
        m.visibility = #none
      end if
      m.addModifier(#meshDeform)
      rb = hk.makeFixedRigidBody(m.name, 0)
      rb.friction = 0.20000000000000001
      if hkNum <> 1 then
        m.addModifier(#lod)
        m.lod.bias = 10
      end if
      if chars(m.name, 1, 6) = "Shield" then
        pShield.add(rb.name)
      end if
    end if
    if chars(m.name, 1, 10) = "Icon_Video" then
      if (gGame.challenge = #race) or (gGame.challenge = #freestyle) then
        pVideo.icon.add(m)
        pVideo.pos.add(m.worldPosition)
        pVideo.active.add(1)
        num = value(chars(m.name, 12, 13))
        pVideo.cam.add(w3d.model("Cam_Video:" & num))
      else
        m.visibility = #none
      end if
    end if
    if chars(m.name, 1, 10) = "Icon_Boost" then
      pBoost.icon.add(m)
      pBoost.pos.add(m.worldPosition)
      pBoost.active.add(1)
    end if
    if (m.name <> pCourse) and (m.name <> skyBox.name) then
      m.addModifier(#lod)
      m.lod.bias = 5
    end if
  end repeat
  repeat with i = 1 to delModels.count
    w3d.deleteModel(delModels[i])
  end repeat
  downobjs = [w3d.model(pCourse)]
  pCDDownList = [#maxNumberOfModels: 1, #levelOfDetail: #detailed, #modelList: downobjs, #maxDistance: 500]
  if (gGame.challenge = #race) or (gGame.challenge = #freestyle) then
    repeat with i = 1 to pPhoto.pos.count
      m = w3d.cloneModelFromCastmember("PhotoIcon" & i, "Icon_Photo", member("bits"))
      if i = 1 then
        tex = m.shaderList[1].texture
      else
        m.shaderList[1].texture = tex
      end if
      m.transform.position = pPhoto.pos[i]
      pPhoto.icon.add(m)
    end repeat
  end if
  if gGame.challenge = #slalom then
    repeat with i = 1 to pSlalom.pos.count
      m = w3d.cloneModelFromCastmember("SlalomIcon" & i, "Icon_Arrow", member("bits"))
      if i = 1 then
        tex = m.shaderList[1].texture
      else
        m.shaderList[1].texture = tex
      end if
      m.transform.position = pSlalom.pos[i]
      m.translate(0, 200, 0)
      pSlalom.icon.add(m)
    end repeat
  end if
  if (gGame.challenge = #race) or (gGame.challenge = #battle) then
    types = [#mortar, #roller, #blaster]
    icons = ["Icon_Mortar", "Icon_Roller", "Icon_Blaster"]
    tex = []
    ico = []
    icoUsed = [0, 0, 0]
    repeat with i = 1 to icons.count
      m = w3d.cloneModelFromCastmember("WeaponIconA" & i, icons[i], member("bits"))
      ico.add(m)
      tex.add(m.shaderList[1].texture)
    end repeat
    repeat with i = 1 to pWeapon.pos.count
      r = random(3)
      if icoUsed[r] then
        m = w3d.cloneModelFromCastmember("WeaponIcon" & i, icons[r], member("bits"))
        m.shaderList[1].texture = tex[r]
      else
        m = ico[r]
        icoUsed[r] = 1
      end if
      m.transform = transform()
      m.transform.position = pWeapon.pos[i]
      m.translate(0, 200, 0)
      pWeapon.icon.add(m)
      pWeapon.type.add(types[r])
    end repeat
    m = w3d.cloneModelFromCastmember("Icon_RollerD", "Icon_RollerD", member("bits"))
    m.transform = transform()
    pIcon = [#rollerD: m]
  end if
end

on setupCharacter me
  gOpponent = [#sex: [], #body: [], #face: [], #board: []]
  playerMem = [gUser.body, gUser.boardGraf]
  oppMem = [random(8), random(8)]
  maxMem = [8, 8]
  faceMem = [random(4), random(4)]
  dudes = 0
  chicks = 0
  boarderList = EMPTY
  repeat with i = 2 to gGame.boarderTotal
    if dudes = 4 then
      sex = 0
    else
      if chicks = 4 then
        sex = 1
      else
        sex = random(2) - 1
      end if
    end if
    if sex = 0 then
      chicks = chicks + 1
    else
      dudes = dudes + 1
    end if
    faceMem[sex + 1] = faceMem[sex + 1] + 1
    if (sex = gUser.sex) and (faceMem[sex + 1] = gUser.face) then
      faceMem[sex + 1] = faceMem[sex + 1] + 1
    end if
    if faceMem[sex + 1] > 4 then
      faceMem[sex + 1] = 1
    end if
    if (sex = gUser.sex) and (faceMem[sex + 1] = gUser.face) then
      faceMem[sex + 1] = faceMem[sex + 1] + 1
    end if
    repeat with k = 1 to 2
      oppMem[k] = oppMem[k] + 1
      if oppMem[k] = playerMem[k] then
        oppMem[k] = oppMem[k] + 1
      end if
      if oppMem[k] > maxMem[k] then
        oppMem[k] = oppMem[k] - maxMem[k]
      end if
      if oppMem[k] = playerMem[k] then
        oppMem[k] = oppMem[k] + 1
      end if
    end repeat
    gOpponent.sex.add(sex)
    gOpponent.body.add(oppMem[1])
    gOpponent.board.add(oppMem[2])
    gOpponent.face.add(faceMem[sex + 1])
    boarderList = boarderList & string((sex * 4) + faceMem[sex + 1])
  end repeat
  sprite(1).boarderList = boarderList
  mem = [#board: 30, #anim: 31, #dude: 33, #chick: 32, #bits: 34]
  dudeMotion = w3d.cloneMotionFromCastmember("DudeBonesAnim", "Dude", member(mem.anim))
  boardMotion = w3d.cloneMotionFromCastmember("BoardKeyAnim", "Boardkey", member(mem.board))
  ftWheelsMotion = w3d.cloneMotionFromCastmember("ftWheelsKeyAnim", "Wheels01key", member(mem.board))
  bkWheelsMotion = w3d.cloneMotionFromCastmember("bkWheelsKeyAnim", "Wheels01BKkey", member(mem.board))
  grabs = []
  grabs.add([83, 88, 98, 103])
  grabs.add([113, 118, 127, 132])
  grabs.add([142, 147, 157, 162])
  grabs.add([172, 177, 187, 192])
  tricks = []
  tricks.add([202, 232])
  tricks.add([242, 272])
  tricks.add([282, 312])
  tricks.add([322, 352])
  tricks.add([362, 397])
  tricks.add([407, 447])
  tricks.add([572, 612])
  tricks.add([622, 662])
  tricks.add([457, 502])
  tricks.add([512, 562])
  tricks.add([672, 722])
  tricks.add([732, 792])
  pAnimFrames = [#leanRight: 0, #default: 10, #leanLeft: 20, #landStart: 30, #landEnd: 44, #crashStart: 54, #crashEnd: 73, #grabs: grabs, #tricks: tricks]
  animRate = 1.0 / 25.0 * 1000.0
  repeat with i = 1 to pAnimFrames.count
    pAnimFrames[i] = pAnimFrames[i] * animRate
  end repeat
  outletUsed = []
  pBoarder = []
  repeat with i = 1 to gGame.boarderTotal
    Ok = 0
    repeat while not Ok
      outlet = random(8)
      Ok = 1
      repeat with u in outletUsed
        if u = outlet then
          Ok = 0
        end if
      end repeat
      if Ok then
        outletUsed.add(outlet)
      end if
    end repeat
    proxy = w3d.cloneModelFromCastmember("boardProxy" & i, "boardProxy", member("bits"))
    proxy.transform = w3d.model("OutletStart:" & outlet).getWorldTransform()
    if ((i = 1) and (gUser.sex = 0)) or ((i > 1) and (gOpponent.sex = 0)) then
      dude = w3d.cloneModelFromCastmember("Chick" & i, "Chick", member(mem.chick))
    else
      dude = w3d.cloneModelFromCastmember("Dude" & i, "Dude", member(mem.dude))
    end if
    dude.bonesPlayer.removeLast()
    dude.bonesPlayer.play(dudeMotion.name)
    dude.bonesPlayer.playRate = 0
    dude.visibility = #none
    if i > 1 then
      dude.addModifier(#lod)
      dude.lod.bias = 5
    end if
    board = w3d.cloneModelFromCastmember("Board" & i, "Board", member(mem.board))
    board.visibility = #none
    if (i = 1) and (gUser.board > 1) then
      t1 = w3d.model("Wheels01").getWorldTransform()
      t2 = w3d.model("Wheels01BK").getWorldTransform()
      w3d.deleteModel("Wheels01")
      w3d.deleteModel("Wheels01BK")
      w1 = w3d.cloneModelFromCastmember("FWheels", "Wheels0" & gUser.board, member(mem.bits))
      w2 = w3d.cloneModelFromCastmember("BWheels", "Wheels0" & gUser.board & "BK", member(mem.bits))
      w1.transform = t1
      w2.transform = t2
      w1.addModifier(#keyframePlayer, #preserveWorld)
      w2.addModifier(#keyframePlayer, #preserveWorld)
      board.addChild(w1)
      board.addChild(w2)
    end if
    board.child[1].visibility = #none
    board.child[2].visibility = #none
    board.keyframePlayer.playRate = 0
    board.child[1].keyframePlayer.removeLast()
    board.child[1].keyframePlayer.play(ftWheelsMotion.name)
    board.child[1].keyframePlayer.playRate = 0
    board.child[2].keyframePlayer.removeLast()
    board.child[2].keyframePlayer.play(bkWheelsMotion.name)
    board.child[2].keyframePlayer.playRate = 0
    player = w3d.newModel("playerNull" & i)
    player.addChild(board, #preserveWorld)
    speedMax = gGame.speedMax
    turnMin = 18000
    turnFactor = 6.5
    if i > 1 then
      speedMax = integer(speedMax * gGame.speedDiff)
    else
      if gUser.board > 1 then
        b = gUser.board - 1
        speedMax = speedMax * (1 + (b * 0.04))
        turnMin = turnMin + (b * 2000)
        turnFactor = 6.5 + (b * 0.5)
      end if
    end if
    speedMaxMin = integer(speedMax * gGame.speedMin)
    boarder = [#proxy: proxy, #rb: 0, #dude: dude, #board: board, #dudeRB: #none, #posNull: w3d.newModel("boarderNull" & i), #dirNull: w3d.newModel("directionNull" & i), #player: player, #pos: vector(0, 0, 0), #speed: 0, #norm: vector(0, 1, 0), #height: 0, #inter: 50, #lean: 0, #leanInc: 0, #leanMax: pAnimFrames.leanLeft - pAnimFrames.default, #speed: 0, #speedMax: speedMax, #speedMaxDefault: speedMax, #speedMaxMin: speedMaxMin, #turn: 0, #turnMin: turnMin, #turnFactor: turnFactor, #carve: 0, #accel: speedMax, #boost: speedMax * 3, #boostLevel: 0, #boosting: 0, #brakes: 0, #weight: 200, #racePos: 1, #lead: 0, #phase: #freeride, #phaseStart: the milliSeconds, #phaseTime: 6000, #phaseSine: 0, #phaseSineLength: 0.29999999999999999, #z_axis: vector(0, 0, 1), #x_axis: vector(1, 0, 0), #validPos: vector(0, 0, 0), #surface: #ontrack, #offside: "L", #crash: 0, #crashTime: 0, #crashPos: vector(0, 0, 0), #underControl: 0, #stuck: 0, #stuckTime: 0, #lost: 0, #lostTime: 0, #anim: #ride, #trickNum: 0, #trickPhase: #none, #inAir: 0, #icon: 0, #weapon: #none, #weaponNum: 0, #weaponTime: 0, #bpRate: 1.0, #raceTime: 0, #finish: 0, #finishTime: 0, #alive: 1]
    boarder.proxy.visibility = #none
    boarder.proxy.addModifier(#meshDeform)
    boarder.rb = hk.makeMovableRigidBody(boarder.proxy.name, boarder.weight, 1, #sphere)
    boarder.rb.restitution = 0.0
    boarder.rb.friction = 0.20000000000000001
    boarder.rb.linearVelocity = vector(0, 0, 0)
    boarder.rb.angularVelocity = vector(0, 0, 0)
    boarder.rb.active = 0
    if i = 1 then
      repeat with j = 1 to pShield.count
        hk.disableCollision(boarder.rb.name, pShield[j])
      end repeat
    end if
    boarder.posNull.pointAtOrientation = [vector(0, 0, -1), vector(0, 1, 0)]
    boarder.dirNull.transform = boarder.proxy.getWorldTransform()
    boarder.dirNull.translate(0, 0, -100)
    if (i = 1) and (gGame.cheat_boost = 1) then
      boarder.boostLevel = 100
    end if
    pBoarder.add(boarder)
  end repeat
  w3d.deleteModel("Dudeposs")
  pDummyNull = w3d.newModel("dummyNull")
  pOppInfoNum = 1
end

on setupWeapons me
  pBomb = []
  repeat with i = 1 to gGame.boarderTotal
    bomb = w3d.cloneModelFromCastmember("bomb" & i, "Bomb", member("bits"))
    bomb.scale(0.5, 0.5, 0.5)
    bomb.visibility = #none
    bomb.addModifier(#meshDeform)
    bombRB = hk.makeMovableRigidBody(bomb.name, 200, 1, #sphere)
    bombRB.restitution = 0.0
    bombRB.friction = 0.20000000000000001
    bombRB.active = 0
    hk.registerInterest(bombRB.name, #all, 5, 0, #bombLand, me)
    pBomb.add([#obj: bomb, #rb: bombRB, #type: #none, #owner: 0, #trailModel: [], #trailRes: []])
  end repeat
  pRoller = []
  repeat with i = 1 to gGame.boarderTotal
    bomb = w3d.cloneModelFromCastmember("roller" & i, "Bomb", member("bits"))
    bomb.visibility = #none
    bomb.addModifier(#meshDeform)
    bombRB = hk.makeMovableRigidBody(bomb.name, 200, 1, #sphere)
    bombRB.restitution = 0.0
    bombRB.friction = 0.80000000000000004
    bombRB.active = 0
    repeat with j = 1 to gGame.boarderTotal
      hk.registerInterest(bombRB.name, pBoarder[j].proxy.name, 5, 0, #rollerHit, me)
    end repeat
    pRoller.add([#obj: bomb, #rb: bombRB, #type: #none, #time: 0, #owner: 0])
  end repeat
  b1 = w3d.cloneModelFromCastmember("explosion1", "Blast", member("bits"))
  b2 = w3d.cloneModelFromCastmember("explosion2", "Blast2", member("bits"))
  b3 = w3d.cloneModelFromCastmember("explosion3", "Blast3", member("bits"))
  b4 = w3d.cloneModelFromCastmember("explosion4", "Blast4", member("bits"))
  b5 = w3d.cloneModelFromCastmember("explosion5", "Blast5", member("bits"))
  b1.visibility = #none
  b2.visibility = #none
  b3.visibility = #none
  b4.visibility = #none
  b5.visibility = #none
  b4.translate(0, 100, 0)
  b5.translate(0, 100, 0)
  pExplosion = [#active: 0, #player: 0, #time: 0, #type: #none, #core: b3, #boomMain: b1, #boomEdge: b2, #blasterCore: b5, #blasterEdge: b4]
end

on setupSurfaces
  trackSurf = ["Main"]
  rimSurf = ["TopSides"]
  sidesSurf = ["Sides"]
  offSurf = ["HillSide", "HillSideL", "HillSideR"]
  finishSurf = ["Sewage"]
  pSurface = [#track: trackSurf, #rim: rimSurf, #sides: sidesSurf, #off: offSurf, #finish: finishSurf]
  repeat with i = 1 to gGame.boarderTotal
    if i = 1 then
      mem = [60 + gUser.body, 70 + (gUser.sex * 4) + gUser.face, 50 + gUser.boardGraf]
    else
      mem = [60 + gOpponent.body[i - 1], 70 + (gOpponent.sex[i - 1] * 4) + gOpponent.face[i - 1], 50 + gOpponent.board[i - 1]]
    end if
    tex = []
    tex.add(pBoarder[i].dude.shaderList[1].texture.name)
    tex.add(pBoarder[i].dude.shaderList[2].texture.name)
    tex.add(pBoarder[i].board.shaderList[2].texture.name)
    repeat with k = 1 to 3
      w3d.deleteTexture(tex[k])
      w3d.newTexture(tex[k], #fromCastMember, member(mem[k]))
    end repeat
  end repeat
  keep = ["board", "wheel", "maleface", "femface", "dude", "chick", "blast", "flash"]
  del = []
  repeat with i = 1 to w3d.texture.count
    m = w3d.texture[i].name
    Ok = 0
    repeat with k in keep
      if offset(k, m) > 0 then
        Ok = 1
      end if
    end repeat
    if not Ok and (offset("clone", m) > 0) then
      del.add(m)
    end if
  end repeat
  repeat with t in del
    w3d.deleteTexture(t)
  end repeat
  tex = w3d.newTexture("bombTrailTex", #fromCastMember, member("trail"))
  pBombTrail = [#tex: tex, #count: 0]
  tex = ["Flash", "bombTrailTex"]
  repeat with t in tex
    w3d.texture(t).renderFormat = #rgba8888
  end repeat
end

on getInfo i
  pOppInfoNum = pOppInfoNum + 1
  if pOppInfoNum > gGame.boarderTotal then
    pOppInfoNum = 2
  end if
  pBoarder[i].brakes = 0
  pBoarder[i].speed = pBoarder[i].rb.linearVelocity.magnitude
  pBoarder[i].accel = pBoarder[i].speedMax - pBoarder[i].speed
  if pBoarder[i].speed < 5000 then
    d = 1.0 + ((5000.0 - pBoarder[i].speed) / 500.0)
    pBoarder[i].accel = pBoarder[i].accel * d
  end if
  pBoarder[i].turn = pBoarder[i].turnMin + (pBoarder[i].speed * pBoarder[i].turnFactor)
  if (i > 1) and (gGame.mode = #race) and (pBoarder[i].speed < 1000) and not pBoarder[i].stuck then
    pBoarder[i].stuck = 1
    pBoarder[i].stuckTime = the milliSeconds
  else
    if pBoarder[i].stuck then
      t = the milliSeconds - pBoarder[i].stuckTime
      if t > 3000 then
        pBoarder[i].crashPos = pBoarder[i].proxy.worldPosition
        pBoarder[i].stuck = 0
        resetToCheckpoint(i)
      end if
    else
      if (i > 1) and (pBoarder[i].speed >= 1000) and pBoarder[i].stuck then
        pBoarder[i].stuck = 0
      end if
    end if
  end if
  if not pBoarder[i].boosting and (pBoarder[i].speed > (pBoarder[i].speedMax * 2)) then
    pBoarder[i].rb.linearVelocity = vector(0, 0, 0)
    pBoarder[i].rb.angularVelocity = vector(0, 0, 0)
    pBoarder[i].rb.interpolatingMoveTo(pBoarder[i].validPos, [vector(0, 1, 0), 0])
    pBoarder[i].speed = 0
    pBoarder[i].crashPos = pBoarder[i].proxy.worldPosition
    resetToCheckpoint(i)
    put "---------------boarder freak out : " & i
  end if
  if (pBoarder[i].speed > 0) and (pBoarder[i].speed < (pBoarder[i].speedMax * 2)) then
    z_axis = pBoarder[i].rb.linearVelocity
    z_axis.normalize()
    pDummyNull.transform = transform()
    okToPoint = canPointAt(pDummyNull.transform.zAxis, pDummyNull.worldPosition, z_axis * 1000)
    if okToPoint and (abs(z_axis.y) < 0.999) then
      pDummyNull.pointAt(z_axis * 1000, upvector)
      x_axis = pDummyNull.transform.xAxis
    else
      x_axis = vector(1, 0, 0)
    end if
  else
    z_axis = vector(0, 0, 1)
    x_axis = vector(1, 0, 0)
  end if
  pBoarder[i].z_axis = z_axis
  pBoarder[i].x_axis = x_axis
  yOffset = 50
  tnPre = pBoarder[i].posNull.getWorldTransform()
  pBoarder[i].posNull.translate(0, yOffset, 0)
  tn = pBoarder[i].posNull.getWorldTransform()
  pBoarder[i].posNull.transform = tnPre
  belowGround = 3
  offtrack = 0
  down_axis = -pBoarder[i].posNull.transform.yAxis
  repeat while belowGround > 0
    c = w3d.modelsUnderRay(tn.position, down_axis, pCDDownList)
    if c.count <> 0 then
      belowGround = 0
      pBoarder[i].surface = getSurface(i, c[1].model.shaderList[c[1].meshID].name)
      if (pBoarder[i].surface = #finish) and not pBoarder[i].crash then
        startFinish(i)
        if (i > 1) and (pBoarder[i].trickPhase = #none) then
          pBoarder[i].trickNum = random(4)
          pBoarder[i].trickPhase = #start
          pBoarder[i].anim = #trick
        end if
      end if
      if pBoarder[i].surface <> #offtrack then
        if pBoarder[i].lost then
          pBoarder[i].lost = 0
        end if
        pBoarder[i].validPos = tn.position
      else
        if (i > 1) and (gGame.mode = #race) then
          if not pBoarder[i].lost then
            pBoarder[i].lostTime = the milliSeconds
            pBoarder[i].lost = 1
          end if
        end if
      end if
      pBoarder[i].height = c[1].distance - yOffset
      if (pBoarder[i].height > 500) and pBoarder[i].underControl then
        pBoarder[i].inAir = 1
        if (i > 1) and (pBoarder[i].height > 1500) and not pBoarder[i].crash and (pBoarder[i].surface = #ontrack) and (pBoarder[i].trickPhase = #none) and (pBoarder[i].speed > (pBoarder[i].speedMax * 0.80000000000000004)) then
          pBoarder[i].trickNum = random(4)
          pBoarder[i].trickPhase = #start
          pBoarder[i].anim = #trick
        end if
      end if
      heightThreshold = 300
      if (pBoarder[i].surface = #rim) or (pBoarder[i].surface = #offtrack) then
        heightThreshold = 40
      end if
      if pBoarder[i].height < heightThreshold then
        if (gGame.mode = #race) and (pBoarder[i].surface = #offtrack) then
          pBoarder[i].brakes = 0.94999999999999996
        end if
        pBoarder[i].norm = c[1].isectNormal
        if pBoarder[i].inAir then
          endJump(i)
        end if
      end if
      next repeat
    end if
    belowGround = belowGround - 1
    tn.position.y = tn.position.y + 100
    yOffset = yOffset + 100
  end repeat
  pBoarder[i].carve = 0
  if pBoarder[i].lost then
    td = the milliSeconds - pBoarder[i].lostTime
    if td < 3000 then
      turn = 1.5
      if pBoarder[i].offside = "R" then
        turn = -1.5
      end if
      pBoarder[i].carve = x_axis * pBoarder[i].turn * turn
    else
      pBoarder[i].crashPos = pBoarder[i].proxy.worldPosition
      resetToCheckpoint(i)
    end if
  end if
  if (i > 1) and (pBoarder[i].phase = #ontrack) and (pBoarder[i].height < 100) and (pBoarder[i].surface = #ontrack) then
    castLeft = 1
    c = w3d.modelsUnderRay(tn.position, x_axis, pCDDownList)
    if c.count <> 0 then
      dist = c[1].distance
      if dist < 2000 then
        castLeft = 0
        pBoarder[i].carve = -x_axis * pBoarder[i].turn * 2.0
      end if
    end if
    if castLeft then
      c = w3d.modelsUnderRay(tn.position, -x_axis, pCDDownList)
      if c.count <> 0 then
        dist = c[1].distance
        if dist < 2000 then
          pBoarder[i].carve = x_axis * pBoarder[i].turn * 2.0
        end if
      end if
    end if
  end if
  if (i > 1) and (pBoarder[i].phase = #carve) and (pBoarder[i].height < 100) and (pBoarder[i].surface = #ontrack) then
    pBoarder[i].carve = x_axis * pBoarder[i].turn
    pBoarder[i].leanInc = -pBoarder[i].leanMax - pBoarder[i].lean
    if sin(pBoarder[i].phaseSine) < 0 then
      pBoarder[i].carve = -pBoarder[i].carve
      pBoarder[i].leanInc = pBoarder[i].leanMax - pBoarder[i].lean
    end if
    pBoarder[i].phaseSine = pBoarder[i].phaseSine + pBoarder[i].phaseSineLength
  else
    if i > 1 then
      pBoarder[i].leanInc = -pBoarder[i].lean
    end if
  end if
  if (i > 1) and not pBoarder[i].finish then
    pBoarder[i].lead = pBoarder[1].dude.worldPosition.z - pBoarder[i].dude.worldPosition.z
    maxlead = gGame.slowDistance
    brakes = 1.60000000000000009
    if pBoarder[i].lead > maxlead then
      if pRace then
        pBoarder[i].speedMax = pBoarder[i].speedMaxDefault - ((pBoarder[i].lead - maxlead) * brakes)
      end if
    else
      pBoarder[i].speedMax = pBoarder[i].speedMaxDefault
    end if
    if pBoarder[i].speedMax < pBoarder[i].speedMaxMin then
      pBoarder[i].speedMax = pBoarder[i].speedMaxMin
    end if
  end if
  if pBoarder[i].finishTime = 0 then
    temp = []
    repeat with j = 1 to gGame.boarderTotal
      temp.add(pBoarder[j].lead)
    end repeat
    temp.sort()
    pBoarder[i].racePos = gGame.boarderTotal + 1 - temp.getOne(pBoarder[i].lead)
  end if
end

on getSurface j, nme
  sf = chars(nme, 1, nme.length - 6)
  repeat with surf in pSurface.finish
    if sf = surf then
      return #finish
    end if
  end repeat
  repeat with surf in pSurface.track
    if sf = surf then
      return #ontrack
    end if
  end repeat
  repeat with surf in pSurface.off
    if sf = surf then
      pBoarder[j].offside = chars(sf, sf.length, sf.length)
      return #offtrack
    end if
  end repeat
  repeat with surf in pSurface.rim
    if sf = surf then
      return #rim
    end if
  end repeat
  repeat with surf in pSurface.sides
    if sf = surf then
      return #sides
    end if
  end repeat
  return #unknown
end

on getFPS
  pFPS.count = pFPS.count + 1
  td = the milliSeconds - pFPS.time
  if td >= 1000.0 then
    pFPS.rate = integer(pFPS.count * (td / 1000.0))
    if pFPS.rate = 0 then
      pFPS.rate = 1
    end if
    pFPS.factor = float(the frameTempo) / float(pFPS.rate)
    pFPS.time = the milliSeconds
    pFPS.count = 0
    gFPSFactor = pFPS.factor
  end if
end

on enterFrame
  getFPS()
  if gTimeFactor > 0 then
    repeat with i = 1 to gGame.boarderTotal
      if not pBoarder[i].finish and pBoarder[i].alive then
        getInfo(i)
        if i = 1 then
          playerControl()
        end if
        setBoarder(i)
        checkWeapon(i)
        if i > 1 then
          useWeapon(i)
        end if
      end if
    end repeat
    checkPhoto()
    checkVideo()
    checkSlalom()
    checkBoost()
    if gGame.mode = #intro then
      intro()
    end if
    moveSky()
  end if
  checkRollers()
  mortarTrail()
  repeat with i = 1 to gGame.boarderTotal
    setAnim(i)
  end repeat
  if pExplosion.active then
    explosion()
  end if
  updateCamera()
  updateInterface()
  updateOverlays()
  setTimer()
end

on intro
  td = the milliSeconds - pIntro.time
  if (pIntro.mode = #hold) and (td > 2000) then
    pIntro.time = the milliSeconds
    pIntro.mode = #release
  else
    if (pIntro.mode = #release) and (td > 150) then
      pBoarder[pIntro.release].rb.active = 1
      hit = pBoarder[pIntro.release].proxy.transform.zAxis * -2000000
      pBoarder[pIntro.release].rb.applyImpulse(hit)
      pBoarder[pIntro.release].dude.visibility = #front
      pBoarder[pIntro.release].board.visibility = #front
      pBoarder[pIntro.release].board.child[1].visibility = #front
      pBoarder[pIntro.release].board.child[2].visibility = #front
      pIntro.release = pIntro.release - 1
      if pIntro.release = 0 then
        pIntro.mode = #finish
      end if
      pIntro.time = the milliSeconds
    else
      if (pIntro.mode = #finish) and (td > 1000) then
        repeat with i = 1 to gGame.boarderTotal
          pBoarder[i].underControl = 1
        end repeat
        changeCamera(#follow, 0, pBoarder[1].player, pBoarder[1].player)
        gGame.mode = #race
        startMusic(1)
      end if
    end if
  end if
  repeat with i = 1 to gGame.boarderTotal
    if pBoarder[i].rb.active then
      pBoarder[i].player.transform = transform()
      pBoarder[i].player.transform.position = pBoarder[i].proxy.worldPosition
      pBoarder[i].dude.transform = pBoarder[i].player.getWorldTransform()
    end if
  end repeat
end

on moveSky
  pSky.box.transform.position.z = pSky.origZ + pCam.cam.transform.position.z
  pSky.box.transform.position.y = pSky.origY + pCam.cam.transform.position.y
end

on playerControl
  pBoarder[1].boosting = 0
  if not pBoarder[1].underControl then
    return 
  end if
  checkkeys()
  if pBoarder[1].inAir then
    if sound(3).volume > 0 then
      sound(3).volume = 0
    end if
    if pBoarder[1].trickPhase = #hold then
      if leftkey or rightkey or upkey or downkey then
        pBoarder[1].trickPhase = #release
      end if
    else
      if pBoarder[1].trickPhase = #none then
        if trickkey then
          trickNum = 0
          if leftkey then
            trickNum = gUser.trickLEFT
          else
            if upkey then
              trickNum = gUser.trickUP
            else
              if rightkey then
                trickNum = gUser.trickRIGHT
              else
                if downkey then
                  trickNum = gUser.trickDOWN
                end if
              end if
            end if
          end if
          if trickNum > 0 then
            pBoarder[1].trickNum = trickNum
            pBoarder[1].trickPhase = #start
            pBoarder[1].anim = #trick
          end if
        else
          if grabkey then
            trickNum = 0
            if leftkey then
              trickNum = 1
            else
              if rightkey then
                trickNum = 2
              else
                if upkey then
                  trickNum = 3
                else
                  if downkey then
                    trickNum = 4
                  end if
                end if
              end if
            end if
            if trickNum > 0 then
              pBoarder[1].trickNum = trickNum
              pBoarder[1].trickPhase = #start
              pBoarder[1].anim = #grab
            end if
          else
            if leftkey then
              pBoarder[1].leanInc = pBoarder[1].leanMax - pBoarder[1].lean
              hit = pBoarder[1].x_axis * -pBoarder[1].turn * 0.5
              pBoarder[1].rb.applyImpulse(hit)
            else
              if rightkey then
                pBoarder[1].leanInc = -pBoarder[1].leanMax - pBoarder[1].lean
                hit = pBoarder[1].x_axis * pBoarder[1].turn * 0.5
                pBoarder[1].rb.applyImpulse(hit)
              else
                pBoarder[1].leanInc = -pBoarder[1].lean
              end if
            end if
          end if
        end if
      end if
    end if
  else
    vol = 60 * (pBoarder[1].speed / pBoarder[1].speedMax)
    if (gGame.sfx_on = 1) and not gGame.paused then
      sound(3).volume = integer(vol)
    else
      if sound(3).volume > 0 then
        sound(3).volume = 0
      end if
    end if
    if leftkey then
      pBoarder[1].leanInc = pBoarder[1].leanMax - pBoarder[1].lean
      hit = pBoarder[1].x_axis * -pBoarder[1].turn
      pBoarder[1].rb.applyImpulse(hit)
    else
      if rightkey then
        pBoarder[1].leanInc = -pBoarder[1].leanMax - pBoarder[1].lean
        hit = pBoarder[1].x_axis * pBoarder[1].turn
        pBoarder[1].rb.applyImpulse(hit)
      else
        pBoarder[1].leanInc = -pBoarder[1].lean
      end if
    end if
    if upkey then
      boost = pBoarder[1].accel
      if gGame.cheat_boost = 0 then
        pBoarder[1].boostLevel = pBoarder[1].boostLevel - (pFPS.factor * 1.0)
      end if
      if pBoarder[1].boostLevel > 0 then
        pBoarder[1].speedMax = pBoarder[1].speedMaxDefault * 2.0
        pBoarder[1].boosting = 1
        boost = boost + pBoarder[1].boost
      else
        pBoarder[1].boostLevel = 0
      end if
      if boost > 0 then
        hit = pBoarder[1].z_axis * boost
        pBoarder[1].rb.applyImpulse(hit)
      end if
    end if
    if downkey then
      pBoarder[1].rb.angularVelocity = pBoarder[1].rb.angularVelocity * 0.90000000000000002
      pBoarder[1].rb.linearVelocity = pBoarder[1].rb.linearVelocity * 0.97999999999999998
    end if
  end if
  if not pBoarder[1].boosting then
    if pBoarder[1].speedMax > pBoarder[1].speedMaxDefault then
      pBoarder[1].speedMax = pBoarder[1].speedMax * 0.98499999999999999
    else
      if pBoarder[1].inAir and (pBoarder[1].speedMax < pBoarder[1].speedMaxDefault) then
        pBoarder[1].speedMax = pBoarder[1].speedMax + (pFPS.factor * 10.0)
      else
        if not pBoarder[1].inAir and (pBoarder[1].speedMax > (pBoarder[1].speedMaxDefault * 0.90000000000000002)) then
          pBoarder[1].speedMax = pBoarder[1].speedMax - (pFPS.factor * 2.0)
        end if
      end if
    end if
    if not pBoarder[1].inAir then
      pBoarder[1].boostLevel = pBoarder[1].boostLevel - (pFPS.factor * 0.012)
    end if
    if pBoarder[1].boostLevel < 0 then
      pBoarder[1].boostLevel = 0
    end if
    if sound(5).isBusy() then
      sound(5).volume = sound(5).volume - 10
      if sound(5).volume < 10 then
        sound(5).stop()
      end if
    end if
  else
    if not sound(5).isBusy() then
      playSound("boost", 5, 100)
    end if
  end if
end

on setBoarder i
  if not pBoarder[i].crash then
    if pBoarder[i].finishTime > 0 then
      t = the milliSeconds - pBoarder[i].finishTime
      if t > 400 then
        endFinish(i)
      end if
    end if
    if i > 1 then
      changePhase(i)
    end if
    if (i > 1) and (pBoarder[i].carve <> 0) then
      if pBoarder[i].carve.magnitude < 200000 then
        pBoarder[i].rb.applyImpulse(pBoarder[i].carve)
      end if
    end if
    if abs(pBoarder[i].leanInc) > 1 then
      pBoarder[i].lean = pBoarder[i].lean + (pBoarder[i].leanInc * 0.20000000000000001)
    end if
    if abs(pBoarder[i].lean) < 2 then
      pBoarder[i].lean = 0
    end if
    if pBoarder[i].lean > pBoarder[i].leanMax then
      pBoarder[i].lean = pBoarder[i].leanMax
    end if
    if pBoarder[i].lean < -pBoarder[i].leanMax then
      pBoarder[i].lean = -pBoarder[i].leanMax
    end if
    if pBoarder[i].speed > pBoarder[i].speedMax then
      perc = float(pBoarder[i].speedMax / pBoarder[i].speed)
      pBoarder[i].rb.angularVelocity = pBoarder[i].rb.angularVelocity * perc
      pBoarder[i].rb.linearVelocity = pBoarder[i].rb.linearVelocity * perc
    end if
    if (i = 1) and (pBoarder[i].brakes > 0) then
      pBoarder[i].rb.angularVelocity = pBoarder[i].rb.angularVelocity * pBoarder[i].brakes
      pBoarder[i].rb.linearVelocity = pBoarder[i].rb.linearVelocity * pBoarder[i].brakes
    end if
  end if
  if pBoarder[i].speed > 50 then
    pBoarder[i].posNull.pointAtOrientation = [vector(0, 0, -1), vector(0, 1, 0)]
    pBoarder[i].posNull.transform = pBoarder[i].dirNull.getWorldTransform()
    okToPoint = canPointAt(pBoarder[i].posNull.transform.zAxis, pBoarder[i].posNull.worldPosition, pBoarder[i].proxy.worldPosition)
    if okToPoint then
      pBoarder[i].posNull.pointAt(pBoarder[i].proxy.worldPosition, upvector)
    end if
    pBoarder[i].posNull.transform.position = pBoarder[i].proxy.worldPosition
    pBoarder[i].posNull.translate(0, -120, 0)
  end if
  alignToGround(i)
  pBoarder[i].player.transform.interpolateTo(pBoarder[i].posNull.transform, 30)
  if not pBoarder[i].crash then
    pBoarder[i].dude.transform = pBoarder[i].player.getWorldTransform()
  else
    td = the milliSeconds - pBoarder[i].crashTime
    if td > 3000 then
      endCrash(i)
    end if
  end if
  pBoarder[i].dirNull.transform = pBoarder[i].proxy.getWorldTransform()
end

on startFinish i
  if pBoarder[i].finishTime > 0 then
    return 
  end if
  if i = 1 then
    changeCamera(#finish, 3, pBoarder[1].player, pBoarder[1].player)
  end if
  pBoarder[i].finishTime = the milliSeconds
end

on endFinish i
  pBoarder[i].alive = 0
  pBoarder[i].finish = 1
  pBoarder[i].raceTime = gGame.raceTime
  pBoarder[i].bpRate = 0
  pBoarder[i].speedMax = 0
end

on endGame
  if gGame.finish then
    if gGame.challenge = #race then
      temp = []
      repeat with j = 1 to gGame.boarderTotal
        temp.add(pBoarder[j].racePos)
      end repeat
      pRacePos = []
      repeat with j = 1 to gGame.boarderTotal
        pRacePos.add(temp.getPos(j))
      end repeat
      if pRacePos[1] = 1 then
        gGame.success = 1
      end if
      sprite(1).racePos1 = pRacePos[1]
      sprite(1).racePos2 = pRacePos[2]
      sprite(1).racePos3 = pRacePos[3]
    else
      if gGame.challenge = #slalom then
        if gGame.score >= gGame.slalomScore then
          gGame.success = 1
        end if
      else
        if gGame.challenge = #freestyle then
          if gGame.score >= gGame.freestyleScore then
            gGame.success = 1
          end if
        end if
      end if
    end if
    repeat with i = 1 to 8
      sound(i).stop()
    end repeat
    gGameState = #menu
    sprite(1).success = gGame.success
    sprite(1).goToFrame("results")
    _movie.go("over")
  else
    gGame.finish = 1
    pCam.fadeStart = the milliSeconds
    pCam.fadeTime = 2
  end if
end

on endJump i
  if pBoarder[i].trickPhase = #none then
    if i = 1 then
      boostLevel = 0
      trick = []
      grab = []
      doneTrick = 0
      doneGrab = 0
      doneEither = 0.80000000000000004
      repeat with t = 1 to pTrick.num.count
        doneEither = doneEither + 0.20000000000000001
        num = pTrick.num[t]
        if pTrick.type[t] = #trick then
          doneTrick = doneTrick + 0.5
          repeat with k in trick
            if num = k then
              doneTrick = doneTrick - 0.5
            end if
          end repeat
          boost = pTrick.time[t] / 120 * (doneEither + doneTrick)
          trick.add(num)
        else
          doneGrab = doneGrab + 0.5
          repeat with k in grab
            if num = k then
              doneGrab = doneGrab - 0.5
            end if
          end repeat
          boost = (pTrick.time[t] / 300) + (3 * (doneEither + doneGrab))
          grab.add(num)
        end if
        boostLevel = boostLevel + boost
      end repeat
      gGame.trickScore = integer(boostLevel * 10)
      if gGame.challenge = #freestyle then
        gGame.score = gGame.score + gGame.trickScore
      end if
      pBoarder[i].boostLevel = pBoarder[i].boostLevel + boostLevel
    end if
    if i = 1 then
      playSound("land", 8, 60)
    end if
    pBoarder[i].anim = #landStart
  else
    if (i = 1) and (pBoarder[1].finishTime = 0) then
      gGame.trickScore = 0
      hit = pBoarder[i].z_axis
      hit = hit * pBoarder[i].speed * 200
      pCam.mode = #landCrash
      startCrash(1, hit)
    end if
  end if
  pBoarder[i].inAir = 0
  pBoarder[i].trickPhase = #none
  if i > 1 then
    pBoarder[i].anim = #landStart
  end if
  if i = 1 then
    if pCam.mode = #video then
      endVideo()
    end if
    pTrick.num = []
    pTrick.time = []
    pTrick.type = []
  end if
end

on addTakedown i
  if i = 1 then
    gGame.finish = 1
    pCam.fadeStart = the milliSeconds
    pCam.fadeTime = 3.5
  else
    gGame.score = gGame.score + 1
    if gGame.score >= gGame.takedowns then
      gGame.finish = 1
      gGame.success = 1
      pCam.fadeStart = the milliSeconds
      pCam.fadeTime = 3.5
    end if
  end if
end

on startCrash i, v
  if not pBoarder[i].alive then
    return 
  end if
  pBoarder[i].crashPos = pBoarder[i].proxy.worldPosition
  if pBoarder[i].dudeRB = #none then
    pBoarder[i].dude.addModifier(#meshDeform)
    pBoarder[i].dudeRB = hk.makeMovableRigidBody(pBoarder[i].dude.name, 200, 1, #box)
    pBoarder[i].dudeRB.restitution = 0.0
    pBoarder[i].dudeRB.friction = 0.20000000000000001
  end if
  ry = pBoarder[i].dude.transform.rotation.y
  pBoarder[i].dudeRB.interpolatingMoveTo(pBoarder[i].dude.worldPosition, [vector(0, 1, 0), ry])
  pBoarder[i].dudeRB.angularVelocity = vector(random(3), 0, 3 + random(7))
  pBoarder[i].dudeRB.linearVelocity = vector(0, 0, 0)
  pBoarder[i].rb.angularVelocity = vector(random(3), 0, 3 + random(7))
  pBoarder[i].rb.linearVelocity = vector(0, 0, 0)
  pBoarder[i].rb.applyImpulse(v)
  pBoarder[i].dudeRB.applyImpulse(v)
  pBoarder[i].crash = 1
  pBoarder[i].crashTime = the milliSeconds
  pBoarder[i].underControl = 0
  pBoarder[i].anim = #crashStart
  if pBoarder[i].weapon <> #none then
    pBoarder[i].icon.removeFromWorld()
    pBoarder[i].weapon = #none
  end if
  if i = 1 then
    if gGame.cheat_boost = 0 then
      pBoarder[i].boostLevel = 0
    end if
  else
    if not pBoarder[1].crash then
      pBoarder[1].boostLevel = pBoarder[1].boostLevel + 10
    end if
  end if
  if i = 1 then
    if pCam.mode = #landCrash then
      gTimeFactor = 0.40000000000000002
      pCam.extra.transform = pCam.cam.getWorldTransform()
      changeCamera(#landCrash, 0, pCam.extra, pBoarder[i].dude)
    else
      gTimeFactor = 0.20000000000000001
      changeCamera(#crash, 0, pBoarder[i].dude, pBoarder[i].dude)
    end if
    pCam.cam.overlay[pCam.boostOL].blend = 100
    pauseMusic()
    stopSloMo()
    playSound("crash", 8, 255)
  end if
end

on endCrash i
  hk.deleteRigidBody(pBoarder[i].dude.name)
  pBoarder[i].dudeRB = #none
  pBoarder[i].crash = 0
  if gGame.challenge = #battlex then
    pBoarder[i].alive = 0
    pBoarder[i].rb.active = 0
    pBoarder[i].dude.visibility = #none
    pBoarder[i].board.visibility = #none
    pBoarder[i].board.child[1].visibility = #none
    pBoarder[i].board.child[2].visibility = #none
    return 
  else
    resetToCheckpoint(i)
  end if
  if i = 1 then
    changeCamera(#follow, 0, pBoarder[1].player, pBoarder[1].player)
  end if
end

on changePhase i
  if not pAutoPhase then
    return 
  end if
  if (pBoarder[i].lead > 0) and (gGame.course < 7) then
    setPhase(i)
  else
    if pBoarder[i].phase <> #ontrack then
      pBoarder[i].phase = #ontrack
      pBoarder[i].phaseStart = the milliSeconds
      pBoarder[i].phaseTime = 0
    end if
  end if
end

on setPhase i
  td = the milliSeconds - pBoarder[i].phaseStart
  ran = random(100)
  if td > pBoarder[i].phaseTime then
    if ran < 10 then
      pBoarder[i].phase = #ontrack
    else
      if ran < 60 then
        pBoarder[i].phase = #freeride
      else
        pBoarder[i].phase = #carve
        pBoarder[i].phaseSineLength = 0.10000000000000001 + float(random(5) / 10.0)
      end if
    end if
    pBoarder[i].phaseStart = the milliSeconds
    pBoarder[i].phaseTime = 1000 + random(3000)
  end if
end

on alignToGround i
  if (pBoarder[i].speed = 0) or (pBoarder[i].posNull.transform.zAxis = vector(0, 0, 0)) then
    return 
  end if
  if (pBoarder[i].height < 300) and (pBoarder[i].inter < 50) then
    pBoarder[i].inter = pBoarder[i].inter + 1
  else
    if (pBoarder[i].height > 300) and (pBoarder[i].inter > 5) then
      pBoarder[i].inter = pBoarder[i].inter - 1
    end if
  end if
  startT = pBoarder[i].posNull.getWorldTransform()
  pDummyNull.transform = pBoarder[i].posNull.getWorldTransform()
  tfront = pDummyNull.transform.zAxis
  tPos = pDummyNull.worldPosition + (100.0 * pBoarder[i].norm)
  pDummyNull.pointAtOrientation = [vector(0, 1, 0), vector(0, 0, 1)]
  okToPoint = canPointAt(pDummyNull.transform.zAxis, pDummyNull.worldPosition, tPos)
  if okToPoint then
    pDummyNull.pointAt(tPos, tfront)
  end if
  pBoarder[i].posNull.transform.interpolateTo(pDummyNull.transform, pBoarder[i].inter)
end

on canPointAt z_axis, P1, P2
  v = P2 - P1
  dist = abs(v.x) + abs(v.y) + abs(v.z)
  if dist < 0.001 then
    return 0
  end if
  v.normalize()
  d = v - z_axis
  dist = abs(d.x) + abs(d.y) + abs(d.z)
  if dist < 0.001 then
    return 0
  end if
  return 1
end

on setAnim i
  t = pBoarder[i].dude.bonesPlayer.currentTime
  pr = gTimeFactor
  trickNum = pBoarder[i].trickNum
  if pBoarder[i].anim = #ride then
    t = pAnimFrames.default + pBoarder[i].lean
    pr = 0
  else
    if pBoarder[i].anim = #landStart then
      t = pAnimFrames.landStart
      pBoarder[i].anim = #land
    else
      if pBoarder[i].anim = #land then
        if t >= pAnimFrames.landEnd then
          pBoarder[i].anim = #ride
          pBoarder[i].lean = 0
        end if
      else
        if pBoarder[i].anim = #crashStart then
          t = pAnimFrames.crashStart
          pBoarder[i].anim = #crash
        else
          if pBoarder[i].anim = #crash then
            if t >= pAnimFrames.crashEnd then
              t = pAnimFrames.crashStart
            end if
          else
            if pBoarder[i].anim = #trick then
              if pBoarder[i].trickPhase = #start then
                t = pAnimFrames.tricks[trickNum][1]
                pBoarder[i].trickPhase = #play
              else
                if pBoarder[i].trickPhase = #play then
                  if t >= pAnimFrames.tricks[trickNum][2] then
                    if i = 1 then
                      tt = pAnimFrames.tricks[trickNum][2] - pAnimFrames.tricks[trickNum][1]
                      pTrick.time.add(tt)
                      pTrick.type.add(#trick)
                      pTrick.num.add(pBoarder[i].trickNum)
                    end if
                    pBoarder[i].trickNum = 0
                    if i = 1 then
                      pBoarder[i].trickPhase = #none
                    end if
                    pBoarder[i].anim = #ride
                    pBoarder[i].lean = 0
                  end if
                end if
              end if
            else
              if pBoarder[i].anim = #grab then
                if pBoarder[i].trickPhase = #start then
                  t = pAnimFrames.grabs[trickNum][1]
                  pBoarder[i].trickPhase = #in
                else
                  if pBoarder[i].trickPhase = #in then
                    if t >= pAnimFrames.grabs[trickNum][2] then
                      pBoarder[i].trickPhase = #hold
                      pr = 0
                      if i = 1 then
                        pTrick.grabTime = 0
                        pTrick.prevTime = the milliSeconds
                      end if
                    end if
                  else
                    if pBoarder[i].trickPhase = #hold then
                      if i = 1 then
                        pTrick.grabTime = pTrick.grabTime + ((the milliSeconds - pTrick.prevTime) * gTimeFactor)
                        pTrick.prevTime = the milliSeconds
                      end if
                      pr = 0
                    else
                      if pBoarder[i].trickPhase = #release then
                        t = pAnimFrames.grabs[trickNum][3]
                        pBoarder[i].trickPhase = #out
                      else
                        if pBoarder[i].trickPhase = #out then
                          if t >= pAnimFrames.grabs[trickNum][4] then
                            if i = 1 then
                              pTrick.time.add(pTrick.grabTime)
                              pTrick.type.add(#grab)
                              pTrick.num.add(pBoarder[i].trickNum)
                            end if
                            pBoarder[i].trickNum = 0
                            pBoarder[i].trickPhase = #none
                            pBoarder[i].anim = #ride
                            pBoarder[i].lean = 0
                          end if
                        end if
                      end if
                    end if
                  end if
                end if
              end if
            end if
          end if
        end if
      end if
    end if
  end if
  pr = pr * pBoarder[i].bpRate
  pBoarder[i].dude.bonesPlayer.playRate = pr
  pBoarder[i].board.keyframePlayer.playRate = pr
  pBoarder[i].board.child[1].keyframePlayer.playRate = pr
  pBoarder[i].board.child[2].keyframePlayer.playRate = pr
  pBoarder[i].dude.bonesPlayer.currentTime = t
  pBoarder[i].board.keyframePlayer.currentTime = t
  pBoarder[i].board.child[1].keyframePlayer.currentTime = t
  pBoarder[i].board.child[2].keyframePlayer.currentTime = t
end

on resetToCheckpoint j
  if (j = 1) and (gGame.challenge = #freestyle) then
    gGame.score = gGame.score - 300
    if gGame.score < 0 then
      gGame.score = 0
    end if
  end if
  nearest = 1
  nearestDist = -1
  userPos = pBoarder[1].player.worldPosition
  boarderPos = pBoarder[j].crashPos
  if gGame.challenge = #battle then
    boarderPos = userPos
  end if
  repeat with i = 1 to pCheckpoint.pos.count
    v = boarderPos - pCheckpoint.pos[i]
    dist = (v.x * v.x) + (v.y * v.y) + (v.z * v.z)
    if (nearestDist < 0) or ((dist < nearestDist) and (v.y < 0)) then
      nearest = i
      nearestDist = dist
    end if
  end repeat
  ry = -pCheckpoint.axis[nearest].y
  pos = pCheckpoint.pos[nearest]
  resetCount = 8
  repeat while resetCount > 0
    reset = pBoarder[j].rb.attemptMoveTo(pos, [vector(0, 1, 0), ry])
    if reset = 1 then
      exit repeat
    end if
    pos.y = pos.y + 500
    pos.z = pos.z + 500
    resetCount = resetCount - 1
  end repeat
  pBoarder[j].rb.angularVelocity = vector(0, 0, 0)
  pBoarder[j].rb.linearVelocity = -pCheckpoint.axis[nearest] * 4000
  pBoarder[j].underControl = 1
  pBoarder[j].crash = 0
  pBoarder[j].lost = 0
  pBoarder[j].trickNum = 0
  pBoarder[j].trickPhase = #none
  pBoarder[j].anim = #ride
  pBoarder[j].lean = 0
  if j = 1 then
    gTimeFactor = 1.0
    continueMusic()
  end if
end

on checkPhoto
  if pCam.mode <> #follow then
    return 
  end if
  if (gGame.challenge <> #race) and (gGame.challenge <> #freestyle) then
    return 
  end if
  repeat with i = 1 to pPhoto.pos.count
    pPhoto.icon[i].rotate(0, 5, 0)
    if pPhoto.active[i] then
      pos = pBoarder[1].player.worldPosition
      pos.y = pos.y + 375
      v = pos - pPhoto.pos[i]
      dist = ((v.x * v.x) + (v.y * v.y) + (v.z * v.z)) / 1000.0
      if dist < 300 then
        startPhoto()
        pPhoto.icon[i].removeFromWorld()
        pPhoto.active[i] = 0
        return 
      end if
    end if
  end repeat
end

on checkVideo
  if pCam.mode <> #follow then
    return 
  end if
  if (gGame.challenge <> #race) and (gGame.challenge <> #freestyle) then
    return 
  end if
  repeat with i = 1 to pVideo.pos.count
    pVideo.icon[i].rotate(0, 5, 0)
    if pVideo.active[i] then
      pos = pBoarder[1].player.worldPosition
      pos.y = pos.y + 375
      v = pos - pVideo.pos[i]
      dist = ((v.x * v.x) + (v.y * v.y) + (v.z * v.z)) / 1000.0
      if dist < 300 then
        startVideo(pVideo.cam[i])
        pVideo.icon[i].removeFromWorld()
        pVideo.active[i] = 0
        return 
      end if
    end if
  end repeat
end

on checkSlalom
  if gGame.challenge <> #slalom then
    return 
  end if
  repeat with i = 1 to pSlalom.pos.count
    pSlalom.icon[i].rotate(0, 5, 0)
    if pSlalom.active[i] then
      pos = pBoarder[1].player.worldPosition
      pos.y = pos.y + 350
      v = pos - pSlalom.pos[i]
      dist = ((v.x * v.x) + (v.y * v.y) + (v.z * v.z)) / 1000.0
      if dist < 500 then
        gGame.score = gGame.score + 1
        pSlalom.icon[i].removeFromWorld()
        pSlalom.active[i] = 0
        playSound("collect", 8, 255)
        return 
      end if
    end if
  end repeat
end

on checkBoost
  repeat with i = 1 to pBoost.pos.count
    if pBoost.active[i] then
      pBoost.icon[i].rotate(0, 5, 0)
      pos = pBoarder[1].player.worldPosition
      pos.y = pos.y + 375
      v = pos - pBoost.pos[i]
      dist = ((v.x * v.x) + (v.y * v.y) + (v.z * v.z)) / 1000.0
      if dist < 400 then
        pBoarder[1].boostLevel = 99
        pBoost.icon[i].removeFromWorld()
        pBoost.active[i] = 0
        playSound("collect", 8, 255)
        return 
      end if
    end if
  end repeat
end

on checkWeapon b
  if (gGame.challenge <> #race) and (gGame.challenge <> #battle) then
    return 
  end if
  if b = 1 then
    repeat with i = 1 to pWeapon.pos.count
      if pWeapon.active[i] then
        pWeapon.icon[i].rotate(0, 5, 0)
      end if
    end repeat
  end if
  if pBoarder[b].weapon <> #none then
    return 
  end if
  prox = 1000
  if b > 1 then
    prox = prox * gGame.pickupRange
  end if
  repeat with i = 1 to pWeapon.pos.count
    if pWeapon.active[i] then
      pos = pBoarder[b].player.worldPosition
      pos.y = pos.y + 375
      v = pos - pWeapon.pos[i]
      dist = ((v.x * v.x) + (v.y * v.y) + (v.z * v.z)) / 1000.0
      if dist < prox then
        pickupWeapon(b, pWeapon.type[i], pWeapon.icon[i])
        pWeapon.active[i] = 0
        if b = 1 then
          playSound("collect", 8, 255)
        end if
        return 
      end if
    end if
  end repeat
end

on startPhoto
  gTimeFactor = 0
  pPhoto.time = the milliSeconds
  changeCamera(#photo, 0, pBoarder[1].player, pBoarder[1].player)
  kudos = 25
  if pBoarder[1].anim = #trick then
    t = pBoarder[1].dude.bonesPlayer.currentTime
    trickNum = pBoarder[1].trickNum
    tricklength = pAnimFrames.tricks[trickNum][2] - pAnimFrames.tricks[trickNum][1]
    midframe = pAnimFrames.tricks[trickNum][1] + (tricklength * 0.5)
    dt = abs(t - midframe) / (tricklength * 0.5)
    kudos = kudos + 50 - integer(dt * 50)
  else
    if pBoarder[1].anim = #grab then
      kudos = kudos + 5
      if pBoarder[1].trickPhase = #hold then
        kudos = kudos + 20
      end if
    end if
  end if
  gGame.kudos = gGame.kudos + kudos
  sprite(1).info = "kudos"
  sprite(1).kudos_score = kudos
  sprite(1).kudos = gGame.kudos
  playSound("photo", 8, 255)
  pauseMusic()
end

on endPhoto
  gTimeFactor = 1.0
  changeCamera(#follow, 0, pBoarder[1].player, pBoarder[1].player)
  continueMusic()
end

on startVideo cam
  gTimeFactor = 0.40000000000000002
  pVideo.time = the milliSeconds
  changeCamera(#video, 0, cam, pBoarder[1].board)
  pauseMusic()
  startSloMo()
end

on endVideo
  gTimeFactor = 1.0
  changeCamera(#follow, 0, pBoarder[1].player, pBoarder[1].player)
  kudos = 50 + integer(gGame.trickScore / 5.0)
  gGame.kudos = gGame.kudos + kudos
  sprite(1).info = "kudos"
  sprite(1).kudos_score = kudos
  sprite(1).kudos = gGame.kudos
  stopSloMo()
  continueMusic()
end

on pickupWeapon boarder, weapon, iconModel
  iconModel.transform = transform()
  pBoarder[boarder].player.addChild(iconModel, #preserveParent)
  iconModel.translate(0, 750, 0)
  iconModel.scale(0.5, 0.5, 0.5)
  pBoarder[boarder].icon = iconModel
  pBoarder[boarder].weapon = weapon
  pBoarder[boarder].weaponTime = the milliSeconds
end

on useWeapon j
  weapon = pBoarder[j].weapon
  if weapon = #none then
    return 
  end if
  if j > 1 then
    t = the milliSeconds - pBoarder[j].weaponTime
    if t > (gGame.weaponHold * 1000) then
      pBoarder[j].icon.removeFromWorld()
      pBoarder[j].weapon = #none
      return 
    end if
    if weapon = #blaster then
      bRange = 1500
      d = pBoarder[j].player.worldPosition.distanceTo(pBoarder[1].player.worldPosition)
      if d > bRange then
        return 
      end if
    else
      if (pBoarder[j].lead < pWeapon.range[1]) or (pBoarder[j].lead > pWeapon.range[2]) then
        return 
      end if
      repeat with i = 1 to pBomb.count
        if pBomb[i].type <> #none then
          return 
        end if
      end repeat
      repeat with i = 1 to pRoller.count
        if pRoller[i].type <> #none then
          return 
        end if
      end repeat
    end if
  end if
  if weapon = #blaster then
    hit = 0
    bHit = 0
    repeat with i = 1 to gGame.boarderTotal
      if (i <> j) and pBoarder[i].alive then
        d = pBoarder[j].player.worldPosition.distanceTo(pBoarder[i].player.worldPosition)
        if d < 2000 then
          if bHit = 0 then
            bHit = i
          end if
          v = pBoarder[i].player.worldPosition - pBoarder[j].player.worldPosition
          v.normalize()
          hit = v * (2000 - d) * 2000
          hit.y = 500 * d
          if gGame.challenge = #battle then
            addTakedown(i)
          end if
          startCrash(i, hit)
        end if
      end if
    end repeat
    if (bHit > 0) and ((j = 1) or (bHit = 1)) then
      gTimeFactor = 0.20000000000000001
      changeCamera(#blaster, 3, pBoarder[j].player, pBoarder[j].player)
    end if
    startExplosion(pBoarder[j].player.worldPosition, #blaster, j)
    pBoarder[j].icon.removeFromWorld()
    pBoarder[j].weapon = #none
    playSound("fire_blaster", 6, 255)
  else
    if weapon = #mortar then
      repeat with i = 1 to pBomb.count
        if pBomb[i].type = #none then
          b = i
          exit repeat
        end if
      end repeat
      pBomb[b].obj.visibility = #front
      pBomb[b].rb.active = 1
      ry = pBoarder[j].dude.transform.rotation.y
      pBomb[b].rb.interpolatingMoveTo(pBoarder[j].icon.worldPosition, [vector(0, 1, 0), ry])
      pBomb[b].rb.angularVelocity = vector(0, 0, 0)
      pBomb[b].rb.linearVelocity = vector(0, 0, 0)
      v = -pBoarder[j].player.transform.zAxis
      if j = 1 then
        v.y = v.y + 0.5
        hit = v * (1600000 + (pBoarder[j].speed * 160))
      else
        hit = vector(0, pBoarder[j].lead * pWeapon.mortarPower, 0)
      end if
      pBomb[b].rb.applyImpulse(hit)
      pBomb[b].type = weapon
      pBomb[b].owner = j
      pBoarder[j].icon.removeFromWorld()
      pBoarder[j].weapon = #none
      playSound("fire_mortar", 6, 255)
    else
      if weapon = #roller then
        repeat with i = 1 to pRoller.count
          if pRoller[i].type = #none then
            b = i
            exit repeat
          end if
        end repeat
        pRoller[b].obj.visibility = #front
        pRoller[b].rb.active = 1
        ry = pBoarder[j].dude.transform.rotation.y
        pRoller[b].rb.interpolatingMoveTo(pBoarder[j].icon.worldPosition, [vector(0, 1, 0), ry])
        pRoller[b].rb.angularVelocity = vector(0, 0, 0)
        pRoller[b].rb.linearVelocity = vector(0, 0, 0)
        v = -pBoarder[j].player.transform.zAxis
        if j = 1 then
          hit = v * (2000000 + (pBoarder[j].speed * 400))
        else
          hit = -v * 1500000
        end if
        pRoller[b].rb.applyImpulse(hit)
        pRoller[b].type = weapon
        pRoller[b].owner = j
        pRoller[b].time = the milliSeconds
        pBoarder[j].weaponNum = b
        pBoarder[j].icon.removeFromWorld()
        if j = 1 then
          pickupWeapon(j, #rollerD, pIcon.rollerD)
        end if
        playSound("fire_roller", 6, 255)
      else
        if weapon = #rollerD then
          num = pBoarder[j].weaponNum
          rollerExplode(num, 0)
          pBoarder[j].weaponNum = 0
          pBoarder[j].icon.removeFromWorld()
          pBoarder[j].weapon = #none
        end if
      end if
    end if
  end if
end

on checkRollers
  if (gGame.challenge <> #race) and (gGame.challenge <> #battle) then
    return 
  end if
  repeat with i = 1 to pRoller.count
    if pRoller[i].type <> #none then
      speed = pRoller[i].rb.linearVelocity.magnitude
      speedMax = pBoarder[1].speedMax * 1.5
      if speed > speedMax then
        perc = float(speedMax / speed)
        pRoller[i].rb.angularVelocity = pRoller[i].rb.angularVelocity * perc
        pRoller[i].rb.linearVelocity = pRoller[i].rb.linearVelocity * perc
      end if
      td = the milliSeconds - pRoller[i].time
      if td > 5000 then
        rollerExplode(i, 0)
        if i = pBoarder[1].weaponNum then
          pBoarder[1].weaponNum = 0
          pBoarder[1].icon.removeFromWorld()
          pBoarder[1].weapon = #none
        end if
      end if
    end if
  end repeat
end

on mortarTrail
  if (gGame.challenge <> #race) and (gGame.challenge <> #battle) then
    return 
  end if
  if gTimeFactor < 1 then
    return 
  end if
  repeat with i = 1 to pBomb.count
    if pBomb[i].type = #mortar then
      pBombTrail.count = pBombTrail.count + 1
      trailRes = w3d.newModelResource("trailRes" & pBombTrail.count, #particle)
      trailRes.texture = pBombTrail.tex
      trailRes.emitter.direction = vector(0, 1, 0)
      trailRes.emitter.region = [vector(-100, -100, -1000), vector(100, 100, 1000)]
      trailRes.emitter.angle = 180
      trailRes.emitter.minSpeed = 0
      trailRes.emitter.maxSpeed = 1500
      trailRes.lifeTime = 600
      trailRes.gravity = vector(0, 500, 0)
      trailRes.emitter.distribution = #gaussian
      trailRes.emitter.numParticles = 3
      trailRes.emitter.mode = #burst
      trailRes.emitter.loop = 0
      trailRes.sizeRange.start = 350
      trailRes.sizeRange.end = 350
      trailRes.colorRange.start = rgb(255, 255, 255)
      trailRes.colorRange.end = rgb(255, 255, 255)
      trailRes.blendRange.start = 50.0
      trailRes.blendRange.end = 0.0
      trail = w3d.newModel("mortarTrail" & pBombTrail.count, trailRes)
      trail.transform = pBomb[i].obj.getWorldTransform()
      pBomb[i].trailModel.add(trail.name)
      pBomb[i].trailRes.add(trailRes.name)
    end if
  end repeat
end

on bombLand me, details
  num = value(chars(details[1], 5, 5))
  if pBomb[num].type = #mortar then
    bombExplode(num)
  end if
end

on rollerHit me, details
  num = value(chars(details[1], 7, 7))
  if pRoller[num].type = #roller then
    colObj = value(chars(details[2], 11, 11))
    if pRoller[num].owner = 1 then
      pBoarder[1].weaponNum = 0
      pBoarder[1].icon.removeFromWorld()
      pBoarder[1].weapon = #none
    end if
    rollerExplode(num, colObj)
  end if
end

on bombExplode b
  repeat with j = 1 to pBomb[b].trailModel.count
    w3d.deleteModel(pBomb[b].trailModel[j])
    w3d.deleteModelResource(pBomb[b].trailRes[j])
  end repeat
  pBomb[b].obj.visibility = #none
  pBomb[b].type = #none
  pBomb[b].rb.active = 0
  hit = 0
  repeat with i = 1 to gGame.boarderTotal
    bRange = 5000
    d = pBomb[b].obj.worldPosition.distanceTo(pBoarder[i].player.worldPosition)
    if (d < bRange) and (pBoarder[i].height < 1000) and pBoarder[i].alive then
      if hit = 0 then
        pCam.bombTarget = pBoarder[i].dude
      end if
      if ((i = 1) or (pBomb[b].owner = 1)) and (gGame.challenge = #battle) then
        addTakedown(i)
      end if
      v = pBoarder[i].player.worldPosition - pBomb[b].obj.worldPosition
      v.normalize()
      hit = v * (5000 - d) * 300
      hit.y = 300 * d
      startCrash(i, hit)
    end if
  end repeat
  if (hit <> 0) and ((pCam.bombTarget = pBoarder[1].dude) or (pBomb[b].owner = 1)) and (pCam.mode = #follow) then
    gTimeFactor = 0.20000000000000001
    changeCamera(#bomb, 3, pBomb[b].obj, pBomb[b].obj)
  end if
  pBomb[b].owner = 0
  startExplosion(pBomb[b].obj.worldPosition, #mortar, 0)
  playSound("boom", 7, 255)
end

on rollerExplode roller, player
  hit = 0
  if player = 0 then
    repeat with i = 1 to gGame.boarderTotal
      bRange = 2500
      d = pRoller[roller].obj.worldPosition.distanceTo(pBoarder[i].player.worldPosition)
      if (d < bRange) and pBoarder[i].alive then
        v = pBoarder[i].player.worldPosition - pRoller[roller].obj.worldPosition
        v.normalize()
        hit = v * (2500 - d) * 500
        hit.y = 400 * d
        if ((i = 1) or (pRoller[roller].owner = 1)) and (gGame.challenge = #battle) then
          addTakedown(i)
        end if
        startCrash(i, hit)
      end if
    end repeat
    pRoller[roller].obj.visibility = #none
    pRoller[roller].type = #none
    pRoller[roller].rb.active = 0
  else
    pRoller[roller].obj.visibility = #none
    pRoller[roller].type = #none
    pRoller[roller].rb.active = 0
    hit = vector(random(200000), 500000, random(20000))
    if ((player = 1) or (pRoller[roller].owner = 1)) and (gGame.challenge = #battle) then
      addTakedown(player)
    end if
    startCrash(player, hit)
  end if
  startExplosion(pRoller[roller].obj.worldPosition, #roller, 0)
  playSound("boom", 7, 100)
end

on startExplosion pos, explosionType, player
  pExplosion.active = 1
  pExplosion.type = explosionType
  pExplosion.time = the milliSeconds
  if explosionType <> #blaster then
    obj = [pExplosion.core, pExplosion.boomMain, pExplosion.boomEdge]
    sc = [19, 4, 4]
    repeat with i = 1 to obj.count
      obj[i].transform = transform()
      obj[i].transform.position = pos
      obj[i].transform.scale = vector(sc[i], sc[i], sc[i])
      obj[i].visibility = #front
    end repeat
  else
    pBoarder[player].player.addChild(pExplosion.blasterCore, #preserveParent)
    pBoarder[player].player.addChild(pExplosion.blasterEdge, #preserveParent)
    pExplosion.blasterCore.visibility = #front
    pExplosion.blasterEdge.visibility = #front
  end if
  explosion()
end

on explosion
  tg = the milliSeconds - pExplosion.time
  t = sin(float(tg / 1000.0) * (PI / 2.0)) * 1001
  sc = 4 + float(t / 50.0)
  bl = 100 - float(t / 10.0)
  if pExplosion.type = #mortar then
    sc = sc * 3.0
  end if
  if tg < 1000 then
    if pExplosion.type = #blaster then
      if tg < 500 then
        t = sin(float(tg / 500.0) * (PI / 2.0)) * 501
        sc = 0.5 + float(t / 50.0)
        bl = 100 - float(t / 5.0)
        pExplosion.blasterEdge.rotate(0, -10, 0)
        pExplosion.blasterCore.transform.scale = vector(15 - sc, 15 - sc, 15 - sc)
        pExplosion.blasterEdge.transform.scale = vector(sc, sc, sc)
        pExplosion.blasterCore.shaderList[1].blend = bl
        pExplosion.blasterEdge.shaderList[1].blend = bl
      else
        pExplosion.blasterCore.visibility = #none
        pExplosion.blasterEdge.visibility = #none
      end if
    else
      pExplosion.boomMain.rotate(0, 5, 0)
      pExplosion.boomEdge.rotate(0, -5, 0)
      pExplosion.boomMain.transform.scale = vector(sc, sc, sc)
      pExplosion.boomEdge.transform.scale = vector(sc, sc, sc)
      pExplosion.boomMain.shaderList[1].blend = bl
      pExplosion.boomEdge.shaderList[1].blend = bl * 0.5
      if tg < 250 then
        bl2 = 100 - float(t / 2.5)
        sc2 = 19 - float(t / 66.70000000000000284)
        pExplosion.core.pointAt(pCam.cam.worldPosition, vector(0, 1, 0))
        pExplosion.core.transform.scale = vector(sc2, sc + 15, sc2)
        pExplosion.core.shaderList[1].blend = bl2
      else
        pExplosion.core.visibility = #none
      end if
    end if
  else
    pExplosion.boomMain.visibility = #none
    pExplosion.boomEdge.visibility = #none
    pExplosion.core.visibility = #none
    pExplosion.blasterCore.visibility = #none
    pExplosion.blasterEdge.visibility = #none
    pExplosion.active = 0
  end if
end

on setTimer
  if (gGame.mode = #race) and not pBoarder[1].finish then
    t = integer((the milliSeconds - gGame.prevTime) * gTimeFactor)
    gGame.raceTime = gGame.raceTime + t
  end if
  gGame.prevTime = the milliSeconds
end

on updateInterface
  if pBoarder[1].boostLevel > 99 then
    pBoarder[1].boostLevel = 99
  end if
  sprite(1).boost = integer(pBoarder[1].boostLevel) + 1
  if gGame.challenge = #battle then
    infront = 0
    behind = 0
    repeat with i = 2 to gGame.boarderTotal
      if pBoarder[i].lead > 0 then
        infront = infront + 1
        next repeat
      end if
      behind = behind + 1
    end repeat
    sprite(1).infront = infront
    sprite(1).behind = behind
  else
    if (gGame.challenge = #slalom) or (gGame.challenge = #freestyle) then
      t = integer((gGame.timeAllowed - gGame.raceTime) / 10.0)
      if t < 0 then
        if not gGame.finish then
          gGame.finish = 1
          pCam.fadeStart = the milliSeconds
          pCam.fadeTime = 3.5
        end if
        t = 0
      end if
    else
      t = integer(gGame.raceTime / 10.0)
    end if
    ntSecs = integer(t / 100.0)
    ntMillis = integer(t - (ntSecs * 100))
    if ntMillis < 0 then
      ntSecs = ntSecs - 1
      ntMillis = ntMillis + 100
    end if
    ntMins = integer(ntSecs / 60.0)
    ntSecs = integer(ntSecs - (ntMins * 60.0))
    if ntSecs < 0 then
      ntMins = ntMins - 1
      ntSecs = ntSecs + 60
    end if
    if ntMillis < 10.0 then
      ntMillis = "0" & string(ntMillis)
    end if
    if ntMins < 10.0 then
      ntMins = "0" & string(ntMins)
    end if
    if ntSecs < 10.0 then
      ntSecs = "0" & string(ntSecs)
    end if
    nt = string(ntMins) & ":" & string(ntSecs) & ":" & string(ntMillis)
    sprite(1).time = nt
  end if
  if gGame.challenge = #race then
    sprite(1).score = pBoarder[1].racePos
  else
    sprite(1).score = gGame.score
  end if
  t = string(pFPS.rate) & " || "
  repeat with i = 1 to gGame.boarderTotal
    t = t & i & ":" & pBoarder[i].surface & " " & pBoarder[i].lost & " " & pBoarder[i].speed & " | "
  end repeat
  sprite(3).member.text = t
end

on mouseDown
end

on checkkeys
  leftkey = 0
  rightkey = 0
  downkey = 0
  upkey = 0
  grabkey = 0
  trickkey = 0
  if keyPressed(123) then
    leftkey = 1
  end if
  if keyPressed(124) then
    rightkey = 1
  end if
  if keyPressed(125) then
    downkey = 1
  end if
  if keyPressed(126) then
    upkey = 1
  end if
  if keyPressed("z") then
    grabkey = 1
  end if
  if keyPressed("x") then
    trickkey = 1
  end if
end

on keyHit
  k = _key.key
  kc = _key.keyCode
  if (k = " ") and (pBoarder[1].weapon <> #none) then
    useWeapon(1)
  end if
  if (k = "r") and not pBoarder[1].crash and pBoarder[1].alive and (gGame.mode = #race) then
    pBoarder[1].crashPos = pBoarder[1].proxy.worldPosition
    resetToCheckpoint(1)
  end if
  if (k = "o") and not gGame.paused then
    pauseGame()
  end if
  if (k = "c") and (gGame.cheat_photo = 1) and not gGame.paused and not pBoarder[1].crash and pBoarder[1].alive and (gGame.mode = #race) then
    startPhoto()
  end if
  if pCam.mode = #photo then
    t = the milliSeconds - pPhoto.time
    if t > 500 then
      endPhoto()
    end if
  end if
  if not _DEBUG then
    return 
  end if
  if k = "q" then
    pos = pBoarder[1].player.worldPosition
    pos.y = pos.y + 200
    put pos
    put pBoarder[1].player.transform.zAxis
  end if
  if k = "c" then
    put pBoarder[1].player.worldPosition
  end if
  if k = "d" then
    findNull()
  end if
  if k = "b" then
    pBoarder[1].boostLevel = pBoarder[1].boostLevel + 25
  end if
  if k = "k" then
    startCrash(1, vector(0, 1000000, 0))
  end if
  temp = pCamFollow
  if k = "1" then
    pCamFollow = 1
  end if
  if k = "2" then
    pCamFollow = 2
  end if
  if k = "3" then
    pCamFollow = 3
  end if
  if k = "4" then
    pCamFollow = 4
  end if
  if pCamFollow <> temp then
    changeCamera(#follow, 0, pBoarder[pCamFollow].player, pBoarder[pCamFollow].player)
  end if
  temp = pPhase
  if k = "8" then
    pPhase = #freeride
  end if
  if k = "9" then
    pPhase = #ontrack
  end if
  if k = "0" then
    pPhase = #carve
  end if
  if pPhase <> temp then
    repeat with i = 2 to gGame.boarderTotal
      pBoarder[i].phase = pPhase
    end repeat
  end if
end

on setupCamera
  pCam = [#cam: w3d.camera[1], #dummy: w3d.newModel("dummyCam"), #extra: w3d.newModel("extraCam"), #start: w3d.model("startCam").getWorldTransform(), #bombTarget: 0, #target: w3d.newModel("cameraTarget"), #buffer: 100, #bufferDefault: 20, #spin: 0, #targetObject: pBoarder[1].player, #followObject: pBoarder[1].player, #mode: #intro, #modeStart: 0, #modeTime: 0, #fadeStart: 0, #fadeTime: 0, #whiteOL: 4, #generalOL: 1, #boostOL: 2, #photoOL: 3]
  pCam.cam.fieldOfView = 70
  pCam.cam.hither = 60
  pCam.cam.yon = 2500000
  col = w3d.newTexture("camFilter01", #fromCastMember, member("CameraFilter01"))
  col.renderFormat = #rgba8888
  pCam.cam.addOverlay(col, point(0, 0), 0)
  pCam.cam.overlay[1].scale = 1.28000000000000003
  pCam.cam.overlay[1].blend = 100
  col = w3d.newTexture("camFilter02", #fromCastMember, member("CameraFilter02"))
  col.renderFormat = #rgba8888
  pCam.cam.addOverlay(col, point(0, 0), 0)
  pCam.cam.overlay[2].scale = 1.28000000000000003
  pCam.cam.overlay[2].blend = 0
  col = w3d.newTexture("camFilter03", #fromCastMember, member("CameraFilter03"))
  col.renderFormat = #rgba8888
  pCam.cam.addOverlay(col, point(0, 0), 0)
  pCam.cam.overlay[3].scale = 1.28000000000000003
  pCam.cam.overlay[3].blend = 0
  col = w3d.newTexture("whiteOverlay", #fromCastMember, member("white"))
  pCam.cam.addOverlay(col, point(0, 0), 0)
  pCam.cam.overlay[4].scale = 1.28000000000000003
  pCam.cam.overlay[4].blend = 100
end

on changeCamera mode, dur, followObject, targetObject
  pCam.targetObject = targetObject
  pCam.followObject = followObject
  pCam.mode = mode
  if pCam.mode = #video then
    pCam.cam.transform = pCam.followObject.getWorldTransform()
    pCam.cam.pointAt(pCam.target.worldPosition, vector(0, 1, 0))
  end if
  pCam.buffer = pCam.bufferDefault
  pCam.modeTime = dur * 1000
  pCam.modeStart = the milliSeconds
  pCam.spin = 0
  pCam.cam.overlay[pCam.whiteOL].blend = 100
end

on updateCamera
  t = the milliSeconds - pCam.modeStart
  pCam.dummy.transform = pCam.followObject.getWorldTransform()
  pCam.target.transform = pCam.targetObject.getWorldTransform()
  if pCam.mode = #intro then
    pCam.dummy.transform = pCam.start
  else
    if pCam.mode = #follow then
      if pBoarder[1].boosting then
        if pCam.spin < 50 then
          pCam.spin = pCam.spin + 2
        end if
      else
        if pCam.spin > 0 then
          pCam.spin = pCam.spin - 2
        end if
      end if
      pCam.cam.fieldOfView = 70 + pCam.spin
      pCam.dummy.translate(0, 400 - (pCam.spin * 4), 150)
      if pBoarder[1].speed < 3000 then
        d = integer((3000.0 - pBoarder[1].speed) / 5.0)
        pCam.dummy.translate(0, d * 0.5, d)
      end if
      pCam.target.translate(0, 600, 0)
    else
      if pCam.mode = #photo then
        pCam.dummy.translate(0, 400, 900)
        pCam.target.translate(0, 200, 0)
        pCam.dummy.rotate(pCam.target.worldPosition, vector(0, 1, -0.40000000000000002), pCam.spin, #world)
        pCam.spin = pCam.spin + 2
      else
        if pCam.mode = #video then
          zt = 2000.0
          if t < zt then
            dt = t / zt
            s = dt * (PI / 2)
            fov = 70 - (sin(s) * 60.0)
            s = (1 - dt) * (PI / 2)
            pCam.target.translate(0, sin(s * 4) * 400, -500 + (sin(s) * 1200))
          else
            dt = (t - zt) / 500.0
            s = dt * (PI / 2)
            fov = 15 - (cos(s) * 5)
            pCam.target.translate(0, sin(s) * 50, -500 + (sin(s) * 100))
          end if
          pCam.cam.fieldOfView = fov
          shake = fov * 5
          pCam.dummy.translate(random(shake), random(shake), 0)
          pCam.dummy.pointAt(pCam.target.worldPosition, vector(0, 1, 0))
        else
          if pCam.mode = #blaster then
            pCam.dummy.translate(0, 1000, -2500)
            if t > pCam.modeTime then
              gTimeFactor = 1.0
              changeCamera(#follow, 0, pBoarder[1].player, pBoarder[1].player)
            end if
          else
            if pCam.mode = #bomb then
              pCam.dummy.transform = transform()
              pCam.dummy.transform.position = pCam.followObject.worldPosition
              pCam.dummy.translate(0, 3000, -6000)
              if t > pCam.modeTime then
                gTimeFactor = 1.0
                changeCamera(#follow, 0, pBoarder[1].player, pBoarder[1].player)
              else
                f = sin(t / float(pCam.modeTime) * (PI / 2))
                pCam.cam.fieldOfView = 90 - (f * 70)
                pCam.target.transform.interpolateTo(pCam.bombTarget.transform, f * 100)
              end if
            else
              if pCam.mode = #landCrash then
                fov = 70 - (t / 50.0)
                if fov >= 10 then
                  pCam.cam.fieldOfView = fov
                end if
              else
                if pCam.mode = #crash then
                  pCam.cam.fieldOfView = 35
                  pCam.dummy.transform = transform()
                  pCam.dummy.transform.position = pBoarder[1].crashPos
                  pCam.dummy.translate(0, 200, -500)
                else
                  if pCam.mode = #finish then
                    if (t > pCam.modeTime) and not gGame.finish then
                      endGame()
                    end if
                    pCam.dummy.translate(0, 400, 1200)
                    pCam.target.translate(0, 200, 0)
                    pCam.dummy.rotate(pCam.target.worldPosition, vector(0, 1, -0.40000000000000002), pCam.spin, #world)
                    pCam.spin = pCam.spin + 2
                  end if
                end if
              end if
            end if
          end if
        end if
      end if
    end if
  end if
  if pCam.mode = #follow then
    if pBoarder[1].boosting then
      bufferTarget = 50
    else
      v = pCam.cam.worldPosition - pCam.target.worldPosition
      dist = ((v.x * v.x) + (v.y * v.y) + (v.z * v.z)) / 1000.0
      if dist > 10000 then
        bufferTarget = 70
      else
        if dist > 4000 then
          d = float((dist - 4000) / 4000.0)
          bufferTarget = pCam.bufferDefault + integer((70 - pCam.bufferDefault) * d)
        else
          bufferTarget = pCam.bufferDefault
        end if
      end if
    end if
    if pCam.buffer < bufferTarget then
      pCam.buffer = pCam.buffer + 1
    else
      if pCam.buffer > bufferTarget then
        pCam.buffer = pCam.buffer - 1
      end if
    end if
  else
    if pCam.buffer < pCam.bufferDefault then
      pCam.buffer = pCam.buffer + 1
    else
      if pCam.buffer > pCam.bufferDefault then
        pCam.buffer = pCam.buffer - 1
      end if
    end if
  end if
  pCam.cam.transform.interpolateTo(pCam.dummy.transform, pCam.buffer)
  if (pCam.mode <> #intro) and (pCam.mode <> #video) then
    pCam.cam.pointAt(pCam.target.worldPosition, vector(0, 1, 0))
  end if
end

on updateOverlays
  if gGame.finish then
    t = (the milliSeconds - pCam.fadeStart) / 1000.0
    if t < pCam.fadeTime then
      b = t / pCam.fadeTime * 100
      pCam.cam.overlay[pCam.whiteOL].blend = b
      vol = integer(100 - b)
      if gGame.music_on = 1 then
        sound(1).volume = vol
      end if
      if (gGame.sfx_on = 1) and (sound(3).volume > vol) then
        sound(3).volume = vol
      end if
    else
      pCam.cam.overlay[pCam.whiteOL].blend = 100
      endGame()
    end if
    return 
  else
    o1 = pCam.cam.overlay[pCam.whiteOL].blend
    if o1 > 2 then
      o1 = o1 * 0.90000000000000002
    else
      o1 = 0
    end if
    pCam.cam.overlay[pCam.whiteOL].blend = o1
  end if
  o1 = pCam.cam.overlay[pCam.boostOL].blend
  temp = o1
  if pBoarder[1].boosting and (o1 < 100) then
    o1 = o1 + 10
  else
    if not pBoarder[1].boosting and (o1 > 0) then
      o1 = o1 * 0.90000000000000002
    end if
  end if
  if o1 <> temp then
    if o1 > 100 then
      o1 = 100
    end if
    if o1 < 2 then
      o1 = 0
    end if
    pCam.cam.overlay[pCam.boostOL].blend = o1
  end if
  o1 = pCam.cam.overlay[pCam.photoOL].blend
  if (pCam.mode <> #intro) and (pCam.mode <> #follow) and (o1 < 100) then
    pCam.cam.overlay[pCam.photoOL].blend = 100
  else
    if ((pCam.mode = #intro) or (pCam.mode = #follow)) and (o1 > 0) then
      pCam.cam.overlay[pCam.photoOL].blend = 0
    end if
  end if
  o1 = pCam.cam.overlay[pCam.generalOL].blend
end

on endSprite me
  hk.shutDown()
  w3d.resetWorld()
end

on findNull
  nullType = "none"
  nearestDist = -1
  repeat with i = 1 to pWeapon.pos.count
    pos = pBoarder[1].player.worldPosition
    pos.y = pos.y + 375
    v = pos - pWeapon.pos[i]
    dist = ((v.x * v.x) + (v.y * v.y) + (v.z * v.z)) / 1000.0
    if (nearestDist < 0) or (dist < nearestDist) then
      nearestDist = dist
      nearestPos = pWeapon.pos[i]
      nullType = "weapons"
    end if
  end repeat
  repeat with i = 1 to pPhoto.pos.count
    pos = pBoarder[1].player.worldPosition
    pos.y = pos.y + 375
    v = pos - pPhoto.pos[i]
    dist = ((v.x * v.x) + (v.y * v.y) + (v.z * v.z)) / 1000.0
    if (nearestDist < 0) or (dist < nearestDist) then
      nearestDist = dist
      nearestPos = pPhoto.pos[i]
      nullType = "photos"
    end if
  end repeat
  if nullType <> "none" then
    put "-----------delete from " & nullType & gGame.course & " -- " & nearestPos
  end if
end
