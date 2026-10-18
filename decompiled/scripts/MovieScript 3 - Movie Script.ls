global gGame, gUser, gWindow, gTimeFactor, gPausedMusicState, gGameState, _VERSION, _DEBUG

on prepareMovie
  _movie.exitLock = 1
  gGameState = #menu
  set the keyDownScript to "keyHit"
  gWindow = 0
  _VERSION = "FULL"
  _DEBUG = 0
end

on gotoMenu
  _movie.go("menu")
end

on startGame
  difficulty = integer(sprite(1).difficulty)
  speedMax = [10000, 10000, 10000, 10500, 10500, 10500, 11000, 11000, 11000]
  if difficulty = 1 then
    speedDiff = [0.94999999999999996, 1.10000000000000009, 1.14999999999999991, 1.19999999999999996, 1.19999999999999996, 1.25, 1.30000000000000004, 1.30000000000000004, 1.30000000000000004]
    speedMin = [0.40000000000000002, 0.40000000000000002, 0.5, 0.59999999999999998, 0.59999999999999998, 0.59999999999999998, 0.69999999999999996, 0.69999999999999996, 0.69999999999999996]
    distBeforeWaiting = [8000, 9000, 10000, 12000, 15000, 20000, 25000, 25000, 30000]
  else
    if difficulty = 2 then
      speedDiff = [1.0, 1.14999999999999991, 1.19999999999999996, 1.25, 1.25, 1.27000000000000002, 1.30000000000000004, 1.30000000000000004, 1.35000000000000009]
      speedMin = [0.5, 0.5, 0.59999999999999998, 0.80000000000000004, 0.69999999999999996, 0.75, 0.80000000000000004, 0.80000000000000004, 0.80000000000000004]
      distBeforeWaiting = [12000, 14000, 17000, 22000, 20000, 25000, 30000, 30000, 40000]
    else
      speedDiff = [1.0, 1.19999999999999996, 1.19999999999999996, 1.30000000000000004, 1.35000000000000009, 1.39999999999999991, 1.39999999999999991, 1.39999999999999991, 1.39999999999999991]
      speedMin = [0.59999999999999998, 0.59999999999999998, 0.59999999999999998, 0.90000000000000002, 0.80000000000000004, 0.84999999999999998, 0.90000000000000002, 0.90000000000000002, 0.90000000000000002]
      distBeforeWaiting = [14000, 17000, 20000, 25000, 27000, 30000, 40000, 40000, 40000]
    end if
  end if
  pickupRange = [0.5, 0.59999999999999998, 0.69999999999999996, 0.80000000000000004, 0.90000000000000002, 1, 1, 1, 1]
  weaponHold = [1, 2, 3, 4, 4, 4, 5, 5, 5]
  timeAllowed = [3, 3, 3, 3, 3, 3, 3, 3, 3]
  freestyleScore = [2500, 3000, 3500, 4000, 4250, 4500, 4500, 4500, 4750]
  slalomScore = [23, 23, 23, 28, 28, 28, 28, 28, 28]
  takedowns = [5, 6, 7, 8, 8, 8, 9, 9, 9]
  b1 = [3, 4, 4, 1, 1, 5]
  b2 = [4, 5, 5, 1, 1, 6]
  b3 = [5, 6, 6, 1, 1, 7]
  b4 = [6, 6, 6, 1, 1, 8]
  b5 = [6, 7, 7, 1, 1, 8]
  b6 = [6, 7, 7, 1, 1, 8]
  b7 = [6, 7, 8, 1, 1, 8]
  b8 = [6, 7, 8, 1, 1, 8]
  b9 = [6, 7, 8, 1, 1, 8]
  boarders = [b1, b2, b3, b4, b5, b6, b7, b8, b9]
  challengeName = [#race, #race, #race, #slalom, #freestyle, #battle]
  course = integer(sprite(1).track)
  enviro = integer(sprite(1).enviro)
  challenge = integer(sprite(1).challenge)
  boarderTotal = boarders[course][challenge]
  kudos = integer(sprite(1).kudos)
  music_on = integer(sprite(1).music_on)
  sfx_on = integer(sprite(1).sfx_on)
  cheat_boost = integer(sprite(1).maxboost)
  cheat_photo = integer(sprite(1).photo)
  flash_state = sprite(1).state
  if flash_state <> "game" then
    gGame = [#boarderTotal: boarderTotal, #mode: #intro, #course: course, #enviro: enviro, #challenge: challengeName[challenge], #speedMax: speedMax[course], #speedMin: speedMin[course], #speedDiff: speedDiff[course], #slowDistance: distBeforeWaiting[course], #pickupRange: pickupRange[course], #weaponHold: weaponHold[course], #freestyleScore: freestyleScore[course], #slalomScore: slalomScore[course], #takedowns: takedowns[course], #score: 0, #trickScore: 0, #kudos: kudos, #finish: 0, #success: 0, #prevTime: 0, #raceTime: 0, #paused: 0, #music_on: music_on, #sfx_on: sfx_on, #timeAllowed: timeAllowed[course] * 60 * 1000, #cheat_boost: cheat_boost, #cheat_photo: cheat_photo]
  else
    gGame.speedDiff = speedDiff[course]
    gGame.speedMin = speedMin[course]
    gGame.slowDistance = distBeforeWaiting[course]
    gGame.slalomScore = slalomScore[course]
    gGame.freestyleScore = freestyleScore[course]
    gGame.takedowns = takedowns[course]
  end if
  if difficulty > 1 then
    inc = difficulty - 1
    gGame.slalomScore = gGame.slalomScore + (inc * 2)
    gGame.freestyleScore = gGame.freestyleScore + (inc * 250)
    gGame.takedowns = gGame.takedowns + (inc * 2)
  end if
  if (challenge = 2) or (challenge = 3) then
    m = 1.0 + ((challenge - 1) * 0.05)
    gGame.speedDiff = gGame.speedDiff * m
    gGame.speedMin = gGame.speedMin * m
    gGame.slowDistance = gGame.slowDistance * m
  end if
  if challenge = 6 then
    gGame.speedDiff = speedDiff[1]
    gGame.speedMin = speedMin[1]
    gGame.slowDistance = distBeforeWaiting[1]
  end if
  if flash_state <> "game" then
    gPausedMusicState = 0
    _movie.go("game")
  end if
end

on changeCharacter
  sex = 2 - integer(sprite(1).getCharacter(1))
  face = integer(sprite(1).getCharacter(2))
  body = integer(sprite(1).getCharacter(3))
  board = integer(sprite(1).getCharacter(4))
  boardGraf = integer(sprite(1).getCharacter(5))
  trickUP = integer(sprite(1).getCharacter(6))
  trickDOWN = integer(sprite(1).getCharacter(7))
  trickLEFT = integer(sprite(1).getCharacter(8))
  trickRIGHT = integer(sprite(1).getCharacter(9))
  changeFactor = integer(sprite(1).changeFactor)
  showTrick = integer(sprite(1).showTrick)
  lock = integer(sprite(1).lock)
  gUser = [#sex: sex, #body: body, #face: face, #board: board, #boardGraf: boardGraf, #trickUP: trickUP, #trickDOWN: trickDOWN, #trickLEFT: trickLEFT, #trickRIGHT: trickRIGHT, #showTrick: showTrick, #changeFactor: changeFactor, #lock: lock]
  _movie.sendSprite(2, #updateBoarder)
end

on startHelp
  _movie.sendSprite(2, #helpCamera)
end

on pauseGame
  gGame.paused = not gGame.paused
  if gGame.paused then
    gTimeFactor = 0
    temp = gPausedMusicState
    pauseMusic()
    stopSloMo()
    gPausedMusicState = temp
    put "pausedMusicState = " & gPausedMusicState
    sound(3).volume = 0
    sprite(1).paused = 1
    set3DWindow(1100, 1120, 0, 640)
  else
    gTimeFactor = 1.0
    if gPausedMusicState = 1 then
      continueMusic()
    else
      if gPausedMusicState = 2 then
        startSloMo()
      end if
    end if
    set3DWindow(0, 1024, 0, 640)
  end if
end

on setOptions
  gGame.music_on = integer(sprite(1).music_on)
  if gGame.music_on = 1 then
  else
  end if
  gGame.sfx_on = integer(sprite(1).sfx_on)
end

on leaveGame
  repeat with i = 1 to 8
    sound(i).stop()
  end repeat
  sprite(1).goToFrame("menu")
  _movie.go("over")
  gGameState = #menu
end

on playSound fxMember, fxChannel, fxVol
  if (gGame.sfx_on = 0) or gGame.paused then
    return 
  end if
  sound(fxChannel).volume = fxVol
  sound(fxChannel).play(member(fxMember))
end

on startMusic
  gPausedMusicState = 1
  mem = member("music" & gGame.enviro)
  mend = mem.duration
  if sound(1).status <> 0 then
    sound(1).stop()
  end if
  sound(1).volume = 0
  if gGame.music_on = 1 then
    sound(1).volume = 200
  end if
  sound(1).play([#member: mem, #loopCount: 500])
  mem = member("video" & gGame.enviro)
  mend = mem.duration
  if sound(2).status <> 0 then
    sound(2).stop()
  end if
  sound(2).volume = 0
  sound(2).play([#member: mem, #loopCount: 5000])
end

on pauseMusic
  gPausedMusicState = 0
  sound(1).volume = 0
end

on continueMusic
  if gGame.music_on = 1 then
    gPausedMusicState = 1
    sound(1).volume = 200
    sound(2).volume = 0
  end if
end

on startSloMo
  if gGame.music_on = 1 then
    gPausedMusicState = 2
    sound(2).volume = 200
    sound(1).volume = 0
  end if
end

on stopSloMo
  sound(2).volume = 0
end

on showBoarderWindow
  gWindow = not gWindow
  if gWindow then
    set3DWindow(426, 997, 0, 448)
  else
    set3DWindow(1100, 1120, 0, 448)
  end if
end

on set3DWindow l, r, t, b
  if l < sprite(2).right then
    sprite(2).left = l
    updateStage()
    sprite(2).right = r
    updateStage()
  else
    sprite(2).right = r
    updateStage()
    sprite(2).left = l
    updateStage()
  end if
  sprite(2).top = t
  updateStage()
  sprite(2).bottom = b
  updateStage()
end

on sizeWindow
  screenSize = integer(sprite(1).screenSize)
  if screenSize > 0 then
    sz = "resize" & string(screenSize)
    externalEvent(sz)
  end if
end

on GetUrl
  if _VERSION = "WEB" then
    nURL = sprite(1).url
    gotoNetPage(nURL, "_new")
  else
    nURL = "getURL(" & sprite(1).url & ")"
    externalEvent(nURL)
  end if
end

on quitGame
  externalEvent("quit")
end

on keyHit
  kc = _key.keyCode
  if kc = 53 then
    quitGame()
  end if
  if (gGameState = #game) and (kc = 36) then
    repeat with i = 1 to 8
      sound(i).stop()
    end repeat
    sprite(1).goToFrame("game")
    _movie.go("restart")
    gGameState = #menu
    return 
  end if
  if gGameState = #game then
    _movie.sendSprite(2, #keyHit)
  end if
end
