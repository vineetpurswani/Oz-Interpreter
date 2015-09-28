functor
import 
	Browser(browse:Browse)

define 
fun {MakeEnvironment ArgList E}
	case ArgList of X|Xs then
		{Adjoin environment(X:E.X) {MakeEnvironment Xs E}}
	else environment() end
end

fun {GetRecordValues Record}
	case Record 
	of nil then nil
	[] H|T then H.2 | {GetRecordValues T}
	end
end

fun {CalcClosure S E}
	case S of [localvar ident(X) S1] then
		{Record.subtract {CalcClosure S1 {Adjoin environment(X:0) E}} X}
	[] [bind ident(X) ident(Y)] then
		environment(X:E.X Y:E.Y)
	[] [bind ident(X) V] then
		environment(X:E.X)
	[] [bind V ident(X)] then
		environment(X:E.X)
	[] [apply ident(X) ArgListActual] then
		{Adjoin environment(X:E.X) {MakeEnvironment ArgListActual E}}
	[] [conditional ident(X) S1 S2] then
		{Adjoin {Adjoin environment(X:E.X) {CalcClosure S1 E}} {CalcClosure S2 E}}
	[] [match ident(X) P1 S1 S2] then
		local BindVars = {GetRecordValues P1} in
			{Adjoin 
				{Adjoin environment(X:E.X) 
					{Record.subtractList {CalcClosure S1 
						{AdjoinList E {Map BindVars fun {$ A} A#0 end}}} 
						BindVars
					}
				} 
				{CalcClosure S2 E}
			}
		end
	[] S1|S2 then
		{Adjoin {CalcClosure S1 E} {CalcClosure S2 E}}
	else environment()
	end
	% TODO: (RemoveKeys - Record.subtractList) and (RemoveKey - Record.subtract)
end

{Browse {CalcClosure Program environment(foo:0 bar:1 quux:2)}}
% {Browse {AdjoinList a(b:1 c:2) {Map [d c] fun {$ A} A#0 end}}}
end