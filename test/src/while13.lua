-- Lua 5.0 threads the else branch through the inner loop's entry jump.
function choose(api)
  while true do
    local choice = api:menu()
    if choice == 1 then
      if api:available() then
        api:notice()
      else
        while true do
          if api:select() then
            return 1
          else
            break
          end
        end
      end
    elseif choice == 2 then
      api:help()
    else
      break
    end
  end
  return 0
end
