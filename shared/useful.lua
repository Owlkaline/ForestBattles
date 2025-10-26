function EaseOutExpo(x)
  if x == 1 then
    return 1
  else
    return 2 ^ (-10 * x)
  end
end
