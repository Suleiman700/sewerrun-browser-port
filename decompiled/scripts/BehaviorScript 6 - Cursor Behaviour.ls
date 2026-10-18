on enterFrame
  c = sprite(1).getFlashProperty(EMPTY, #cursor)
  if c = 2 then
    _player.cursor(280)
  else
    _player.cursor(0)
  end if
end
