-- A break must leave only the innermost of three loops.
while true do
  local outer = input()
  if outer then
    while true do
      local middle = input()
      if middle then
        while true do
          local inner = input()
          if inner then
            work(inner)
          else
            break
          end
        end
      else
        break
      end
    end
  else
    break
  end
end
