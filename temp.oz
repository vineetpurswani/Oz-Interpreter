functor
import
    Browser(browse:Browse)
define

local Environment in

Environment = environment()
Environment = {Adjoin Environment environment(1:1)}
{Browse Environment}
end

end