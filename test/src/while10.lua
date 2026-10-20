-- Keep the distinct outer/inner retries and the jumps after early returns.
function choose(api)
  while true do
    local choice = api:menu()
    if choice == 1 then
      if api:available() == false then
        api:notice()
      else
        while true do
          local item, destination, cost, duration = api:select()
          if item > 0 then
            local message = api:format(destination, cost, duration)
            local confirm = api:confirm(message)
            if confirm == true then
              if api:afford(cost) == false then
                api:notice()
                return 0
              elseif api:blocked() == true then
                api:notice()
                return 0
              else
                return item
              end
            end
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
