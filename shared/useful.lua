function Sign(number)
  return number > 0 and 1 or (number == 0 and 0 or -1)
end

function SetContains(set, key)
  return set[key] ~= nil
end

function EaseOutExpo(x)
  if x == 1 then
    return 1
  else
    return 2 ^ (-10 * x)
  end
end
