-- Leaving the inner loop must still execute the outer loop's trailing work.
while running() do
  local mode = input()
  if mode == 1 then
    while true do
      local value = input()
      if value > 0 then
        if accept(value) then
          return value
        end
      else
        break
      end
    end
  elseif mode == 2 then
    help()
  else
    break
  end
  finish(mode)
end
