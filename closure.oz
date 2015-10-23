functor
import 
	Browser(browse:Browse)

define 
fun {GetRecordValues Record}
	case Record 
	of nil then nil
	[] H|T then H.2.1 | {GetRecordValues T}
	end
end

fun {MakeEnvironment ArgList E}
	case ArgList of X|Xs then
		if X == nothing then {MakeEnvironment Xs E}
		else {Adjoin environment(X:E.X) {MakeEnvironment Xs E}}
		end
	else environment() end
end

fun {CalcClosure S E}
	% {Browse S}
	% {Browse E}
	case S of [localvar ident(X) S1] then
		{Record.subtract {CalcClosure S1 {Adjoin environment(X:0) E}} X}
	[] [bind ident(X) ident(Y)] then
		environment(X:E.X Y:E.Y)
	[] [bind X1 Y1] then
		local X V in
			case X1 of ident(X2) then 
				X = X2
				V = Y1
			else 
				case Y1 of ident(X2) then
					X = X2
					V = X1
				else raise unknownStatement() end
				end
			end
			if V.1 == record then 
				{Adjoin environment(X:E.X) {MakeEnvironment 
					{Map {GetRecordValues V.2.2} 
					fun {$ A} case A of ident(X) then X else nothing end end } E} } 
			else environment(X:E.X) end
		end
	[] [apply ident(X) ArgListActual] then
		{Adjoin environment(X:E.X) {MakeEnvironment ArgListActual E}}
	[] [conditional ident(X) S1 S2] then
		{Adjoin {Adjoin environment(X:E.X) {CalcClosure S1 E}} {CalcClosure S2 E}}
	[] [match ident(X) P1 S1 S2] then
		local BindVars = {GetRecordValues P1.2.2} in
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
	else environment(nil)
	end
end


Program = 
	[bind [record literal(person)
			     [literal(age) ident(foo)]] ident(baz)]

{Browse {CalcClosure Program environment(foo:0 baz:1)}}
% {Browse {AdjoinList a(b:1 c:2) {Map [d c] fun {$ A} A#0 end}}}
end