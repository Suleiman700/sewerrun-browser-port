property pDragging

on mouseDown me
  fs = integer(sprite(1).fullscreen)
  if (fs = 0) and (the mouseV < 40) then
    externalEvent("startdrag")
    pDragging = 1
  end if
end

on mouseUp me
  pDragging = 0
end

on beginSprite me
  pDragging = 0
end

on mouseWithin me
  if pDragging then
    externalEvent("movewindow")
  end if
end
