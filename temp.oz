functor
import
    Browser(browse:Browse)
define
local Env Env2 in
fun {AddArgsToClosure ArgListFormal ArgListActual Closure E}
	case ArgListFormal 
	of nil then Closure
	[] ident(H)|T then 
		case ArgListActual
		of nil then raise error() end
		[] ident(H1)|T1 then
			{AddArgsToClosure T T1 {Adjoin Closure environment(H:E.H1)} E}
	end
end
end

end