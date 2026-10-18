property w3d, pCam, pBoarder, pAnimFrames, pDummyNull, upkey, downkey, leftkey, rightkey, grabkey, trickkey
global gUser

on beginSprite me
  repeat with i = 29 to 34
    if member(i).type = #shockwave3d then
      member(i).resetWorld()
    end if
  end repeat
  w3d = sprite(2).member
  w3d.directionalPreset = #bottomLeft
  setupCharacter()
  setupCamera()
  changeCharacter()
  sprite(1).play()
end

on setupCharacter
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
  pBoarder = []
  chick = w3d.cloneModelFromCastmember("Chick", "Chick", member(mem.chick))
  dude = w3d.model("Dude")
  dude.translate(0, 10, 0)
  chick.translate(0, 10, 0)
  dude.bonesPlayer.removeLast()
  dude.bonesPlayer.play(dudeMotion.name)
  dude.bonesPlayer.playRate = 0
  chick.bonesPlayer.removeLast()
  chick.bonesPlayer.play(dudeMotion.name)
  chick.bonesPlayer.playRate = 0
  board = w3d.cloneModelFromCastmember("Board", "Board", member(mem.board))
  board.keyframePlayer.playRate = 0
  board.child[1].keyframePlayer.removeLast()
  board.child[1].keyframePlayer.play(ftWheelsMotion.name)
  board.child[1].keyframePlayer.playRate = 0
  board.child[2].keyframePlayer.removeLast()
  board.child[2].keyframePlayer.play(bkWheelsMotion.name)
  board.child[2].keyframePlayer.playRate = 0
  t1 = w3d.model("Wheels01").getWorldTransform()
  t2 = w3d.model("Wheels01BK").getWorldTransform()
  repeat with i = 2 to 4
    w1 = w3d.cloneModelFromCastmember("FWheels" & i, "Wheels0" & i, member(mem.bits))
    w2 = w3d.cloneModelFromCastmember("BWheels" & i, "Wheels0" & i & "BK", member(mem.bits))
    w1.transform = t1
    w2.transform = t2
    w1.addModifier(#keyframePlayer, #preserveWorld)
    w2.addModifier(#keyframePlayer, #preserveWorld)
    board.addChild(w1)
    board.addChild(w2)
    w1.keyframePlayer.removeLast()
    w1.keyframePlayer.play(ftWheelsMotion.name)
    w1.keyframePlayer.playRate = 0
    w2.keyframePlayer.removeLast()
    w2.keyframePlayer.play(bkWheelsMotion.name)
    w2.keyframePlayer.playRate = 0
  end repeat
  boarder = [#dude: dude, #chick: chick, #board: board, #anim: #ride, #trickNum: 0, #trickPhase: #none, #bpRate: 1.0, #ftWheelsMotion: ftWheelsMotion.name, #bkWheelsMotion: bkWheelsMotion.name, #ftWheels: (board * 2) - 1, #bkWheels: board * 2]
  pBoarder.add(boarder)
  changeWheels(1)
  pDummyNull = w3d.newModel("dummyNull")
end

on changeWheels wheels
  pBoarder[1].ftWheels = (wheels * 2) - 1
  pBoarder[1].bkWheels = wheels * 2
  repeat with i = 1 to 4
    c1 = (i * 2) - 1
    c2 = i * 2
    if i = wheels then
      pBoarder[1].board.child[c1].visibility = #front
      pBoarder[1].board.child[c2].visibility = #front
      next repeat
    end if
    pBoarder[1].board.child[c1].visibility = #none
    pBoarder[1].board.child[c2].visibility = #none
  end repeat
  put "changeWheels : " & wheels
end

on helpCamera
  pCam.cam.overlay[2].blend = 0
  pCam.mode = #spin
end

on updateBoarder
  if gUser.lock = 1 then
    pCam.cam.overlay[2].blend = 100
  else
    pCam.cam.overlay[2].blend = 0
  end if
  if (gUser.changeFactor = 0) or ((gUser.changeFactor > 1) and (gUser.changeFactor < 6)) then
    mem = [60 + gUser.body, 74 + gUser.face, 60 + gUser.body, 70 + gUser.face, 50 + gUser.boardGraf]
    tex = []
    tex.add(pBoarder[1].dude.shaderList[1].texture.name)
    tex.add(pBoarder[1].dude.shaderList[2].texture.name)
    tex.add(pBoarder[1].chick.shaderList[1].texture.name)
    tex.add(pBoarder[1].chick.shaderList[2].texture.name)
    tex.add(pBoarder[1].board.shaderList[2].texture.name)
    repeat with k = 1 to 5
      w3d.deleteTexture(tex[k])
      w3d.newTexture(tex[k], #fromCastMember, member(mem[k]))
    end repeat
  end if
  if (gUser.changeFactor = 4) or (gUser.changeFactor = 0) then
    changeWheels(gUser.board)
  end if
  if (gUser.changeFactor = 0) or (gUser.changeFactor = 1) then
    if gUser.sex = 0 then
      pBoarder[1].chick.visibility = #front
      pBoarder[1].dude.visibility = #none
    else
      pBoarder[1].chick.visibility = #none
      pBoarder[1].dude.visibility = #front
    end if
  end if
  if gUser.changeFactor > 5 then
    showTrick()
  end if
  if gUser.changeFactor > 0 then
    cam = [#spin, #cu, #spin, #wheels, #board, #spin, #spin, #spin, #spin]
    pCam.mode = cam[gUser.changeFactor]
  else
    pCam.mode = #spin
  end if
end

on enterFrame
  playerControl()
  setAnim(1)
  updateOverlays()
  updateCamera()
end

on updateOverlays
  return 
  o1 = pCam.cam.overlay[pCam.whiteOL].blend
  if o1 > 2 then
    o1 = o1 * 0.90000000000000002
  else
    o1 = 0
  end if
  pCam.cam.overlay[pCam.whiteOL].blend = o1
end

on playerControl
  checkkeys()
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
        end if
      end if
    end if
  end if
end

on showTrick
  pBoarder[1].trickNum = gUser.showTrick
  pBoarder[1].trickPhase = #start
  pBoarder[1].anim = #trick
end

on setAnim i
  t = pBoarder[i].dude.bonesPlayer.currentTime
  pr = 1.0
  trickNum = pBoarder[i].trickNum
  if pBoarder[i].anim = #ride then
    t = pAnimFrames.default
    pr = 0
  else
    if pBoarder[i].anim = #trick then
      if pBoarder[i].trickPhase = #start then
        t = pAnimFrames.tricks[trickNum][1]
        pBoarder[i].trickPhase = #play
      else
        if pBoarder[i].trickPhase = #play then
          if t >= pAnimFrames.tricks[trickNum][2] then
            pBoarder[i].trickNum = 0
            pBoarder[i].trickPhase = #none
            pBoarder[i].anim = #ride
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
            end if
          else
            if pBoarder[i].trickPhase = #hold then
              pr = 0
            else
              if pBoarder[i].trickPhase = #release then
                t = pAnimFrames.grabs[trickNum][3]
                pBoarder[i].trickPhase = #out
              else
                if pBoarder[i].trickPhase = #out then
                  if t >= pAnimFrames.grabs[trickNum][4] then
                    pBoarder[i].trickNum = 0
                    pBoarder[i].trickPhase = #none
                    pBoarder[i].anim = #ride
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
  pBoarder[i].chick.bonesPlayer.playRate = pr
  pBoarder[i].board.keyframePlayer.playRate = pr
  pBoarder[i].dude.bonesPlayer.currentTime = t
  pBoarder[i].chick.bonesPlayer.currentTime = t
  pBoarder[i].board.keyframePlayer.currentTime = t
  repeat with k = 1 to 8
    pBoarder[i].board.child[k].keyframePlayer.playRate = pr
    pBoarder[i].board.child[k].keyframePlayer.currentTime = t
  end repeat
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
end

on setupCamera
  pCam = [#cam: w3d.camera[1], #dummy: w3d.newModel("dummyCam"), #buffer: 100, #bufferDefault: 50, #spin: 0, #target: w3d.newModel("cameraTarget"), #targetObject: pBoarder[1].dude, #followObject: pBoarder[1].dude, #mode: #spin, #modeStart: 0, #modeTime: 0]
  pCam.cam.fieldOfView = 70
  pCam.cam.hither = 60
  pCam.cam.yon = 2500000
  col = w3d.newTexture("roundBG", #fromCastMember, member("ChooserBG"))
  pCam.cam.addBackdrop(col, point(0, 0), 0)
  pCam.cam.backdrop[1].scale = 1.29000000000000004
  col = w3d.newTexture("roundOverlay", #fromCastMember, member("ChooserOverlay"))
  pCam.cam.addOverlay(col, point(0, 0), 0)
  pCam.cam.overlay[1].scale = 1.28000000000000003
  pCam.cam.overlay[1].blend = 100
  col = w3d.newTexture("lockOverlay", #fromCastMember, member("ChooserHoleLocked"))
  pCam.cam.addOverlay(col, point(0, 0), 0)
  pCam.cam.overlay[2].scale = 1.28000000000000003
  pCam.cam.overlay[2].blend = 0
end

on updateCamera
  t = the milliSeconds - pCam.modeStart
  pCam.dummy.transform = pCam.followObject.getWorldTransform()
  pCam.target.transform = pCam.targetObject.getWorldTransform()
  if pCam.mode = #locked then
    pCam.dummy.translate(150, 200, -750)
    pCam.target.translate(0, 300, 0)
  else
    if pCam.mode = #spin then
      pCam.dummy.translate(0, 200, 700)
      pCam.target.translate(0, 300, 0)
      pCam.dummy.rotate(pCam.target.worldPosition, vector(0, 1, 0), pCam.spin, #world)
      pCam.spin = pCam.spin + 2
    else
      if pCam.mode = #cu then
        pCam.dummy.translate(-100, 500, -200)
        pCam.target.translate(-40, 580, 0)
      else
        if pCam.mode = #board then
          pCam.dummy.translate(-250, -350, -200)
          pCam.target.translate(0, 200, 0)
        else
          if pCam.mode = #wheels then
            pCam.dummy.translate(-450, -50, -250)
            pCam.target.translate(0, 50, 0)
          end if
        end if
      end if
    end if
  end if
  pCam.cam.transform.interpolateTo(pCam.dummy.transform, pCam.buffer)
  pCam.cam.pointAt(pCam.target.worldPosition, vector(0, 1, 0))
  if pCam.buffer < pCam.bufferDefault then
    pCam.buffer = pCam.buffer + 1
  else
    if pCam.buffer > pCam.bufferDefault then
      pCam.buffer = pCam.buffer - 1
    end if
  end if
end
