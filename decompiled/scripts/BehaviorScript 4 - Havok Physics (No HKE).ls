property pInitialized, pHavok, pTimeStep, pSubSteps, pPaused, pScale, pTolerance, pSprite
global gHavok, gPaused, gTimeFactor, gFPSFactor

on beginSprite me
  pHavok = me.getHavokCastMember(pHavok)
  me.initializePhysics()
  gTimeFactor = 1.0
  gFPSFactor = 1.0
end

on endSprite me
  if pInitialized then
    pHavok.shutDown()
    pInitialized = 0
  end if
end

on exitFrame me
  if gFPSFactor > 2.0 then
    gFPSFactor = 2.0
  end if
  if gFPSFactor < 0.5 then
    gFPSFactor = 0.5
  end if
  if gTimeFactor > 0 then
    pHavok.step(pTimeStep * gTimeFactor * gFPSFactor, pSubSteps)
  end if
end

on initializePhysics me
  gPaused = 0
  pSprite = sprite(me.spriteNum)
  pHavok = member(pHavok)
  if pInitialized then
    pHavok.shutDown()
  end if
  pInitialized = 1
  pHavok.Initialize(pSprite.member, pTolerance, pScale)
  gHavok = pHavok
  put "Initialized Physics"
end

on togglePausePhysics me
  pPaused = not pPaused
end

on isOKToAttach aScript, aSpriteType, aSpriteNum
  case aSpriteType of
    #graphic:
      case sprite(aSpriteNum).member.type of
        #shockwave3d:
          return 1
        #text:
          if sprite(aSpriteNum).member.displayMode = #mode3d then
            return 1
          else
            return 0
          end if
      end case
    #script:
      return 0
  end case
end

on getPropertyDescriptionList aScript
  if the floatPrecision < 4 then
    set the floatPrecision to 4
  end if
  if the currentSpriteNum > 0 then
    tGPDList = [:]
    tList = []
    tList = aScript.getHavokCastMembers(tList)
    tGPDList[#pHavok] = [#comment: "Which Havok Cast Member", #format: #string, #range: tList, #default: tList[1]]
    tGPDList[#pTolerance] = [#comment: "Tolerance", #format: #float, #default: 4]
    tGPDList[#pTimeStep] = [#comment: "Time Step", #format: #float, #default: 0.025]
    tGPDList[#pSubSteps] = [#comment: "Substeps", #format: #integer, #default: 5]
    tGPDList[#pScale] = [#comment: "World Scale", #format: #float, #default: 0.0254]
    return tGPDList
  end if
end

on getBehaviorTooltip aScript
  tString1 = "Updates 3D models based on a physical simulation" & RETURN & RETURN
  tString2 = "-" && "Type" && ":" && "Independent Action" & RETURN
  tString3 = "-" && "Dependencies" && ":" && "None" & RETURN
  return tString1 & tString2 & tString3
end

on getBehaviorDescription aScript
  tString1 = "HAVOK PHYSICS" & RETURN & RETURN & "Enables the Havok engine for the sprite. " & "Any created rigid bodies from Shockwave 3D models are then updated based on a physics simulation." & EMPTY & RETURN & RETURN & "This independent behavior does not require a trigger." & RETURN & RETURN & "ACTIONS AND THEIR REQUIRED TRIGGERS:" & RETURN & "- None" & RETURN & RETURN & "PARAMETERS:" & RETURN & "- Havok Cast Member" & RETURN & RETURN & "- Tolerance" & RETURN & RETURN & "- Timestep" & RETURN & RETURN & "- Substeps" & RETURN & RETURN & "- World Scale" & RETURN & RETURN & "PERMITTED SPRITE TYPES:" & RETURN & "- Shockwave 3D"
  return tString1
end

on getHavokCastMembers me, aList
  repeat with j = 1 to the number of castMembers of castLib 1
    if member(j).type = #havok then
      aList.add(j & ":" & member(j).name)
    end if
  end repeat
  aList.add("None")
  return aList
end

on getHavokCastMember me, memberName
  nameStr = chars(memberName, offset(":", memberName) + 1, memberName.length)
  nameInt = chars(memberName, 1, offset(":", memberName) - 1)
  nameInt = integer(nameInt)
  return member(nameInt)
end
