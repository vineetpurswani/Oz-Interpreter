%% ---------------------------------------------------------------------------------
%% Authors:
%% Vineet Purswani			12813
%% Ayushman Sisodiya		12188
%% Deepak Kumar 			12228

%% Functions and Procedures:
%% 	MakeEnvironment - make new environment record with the given variable list and current environment
%% 	AddArgsToClosure - Merge Closure environment with argument list variables
%% 	CalcClosure - Evaluate free variables of the given statements
%% 	MatchAndBind - Used in pattern matching to match and bind the mentioned variables
%% 	CreateAndUnify - Create new environment and store variables for the pattern match variables
%% 	GetRecordKeys - Get record keys from AST record list
%% 	GetRecordValues - Get record values from AST record list
%% 	Unique - False if feature list has all unique values and true otherwise
%% 	RecordSort - sorts records in lexicographic manner
%% ---------------------------------------------------------------

declare

fun {AddArgsToClosure ArgListFormal ArgListActual Closure E}
	% {Browse ArgListFormal#ArgListActual}
	% {Browse Closure}
	case ArgListFormal 
	of nil then Closure
	[] ident(H)|T then 
		case ArgListActual
		of nil then raise error() end
		[] ident(H1)|T1 then
			{AddArgsToClosure T T1 {Adjoin Closure environment(H:E.H1)} E}
		[] H1|T1 then
			local Temp in
				Temp = {AddKeyToSAS}
				{BindValueToKeyInSAS Temp H1}
				{AddArgsToClosure T T1 {Adjoin Closure environment(H:Temp)} E}
			end			
		end
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

proc {MatchAndBind XSASvalue P1 E Match Enew}
	% not the same number of features, then matching fail
	if {Length XSASvalue.2.2.1} \= {Length P1.2.2.1} then Match = false
	% not the same record name, then also matching fail 
	elseif XSASvalue.2.1 \= P1.2.1 then Match = false
	else
		local SortedXSASvalue SortedP1 in
			% Sort both the record by features
			SortedXSASvalue = {RecordSort XSASvalue.2.2.1}
			SortedP1 = {RecordSort P1.2.2.1}
			% all features must be unique. Returns true if they are not
			if {Unique {GetRecordKeys SortedXSASvalue}} then Match = false 
			elseif {Unique {GetRecordKeys SortedP1}} then Match = false
			% All corresponding features must be equal
			elseif {GetRecordKeys SortedXSASvalue} \= {GetRecordKeys SortedP1} then Match = false
			% Now bind all using unify and if passes then Match complete
			else
				{CreateAndUnify SortedXSASvalue SortedP1 E Enew}
				Match = true
			end
		end
	end
end

proc {CreateAndUnify SortedXSASvalue SortedP1 E Enew}
	local Etemp in
		case SortedP1 of nil then Enew = E
		[] [literal(_) ident(H)]|T then 
			case SortedXSASvalue of nil then raise somethingwrong() end
			[] [literal(_) H1]|T1 then
				Etemp = {Adjoin E environment(H:{AddKeyToSAS})}
				{Unify ident(H) H1 Etemp}
				{CreateAndUnify T1 T Etemp Enew}
			else raise error() end
			end
		else raise error() end
		end 
	end
end

% Make a list of all the features given the record list
fun {GetRecordKeys Record}
	case Record 
	of nil then nil
	[] H|T then H.1 | {GetRecordKeys T}
	end
end

fun {GetRecordValues Record}
	case Record 
	of nil then nil
	[] H|T then H.2.1 | {GetRecordValues T}
	end
end

% {Browse {GetRecordKeys [[literal(quuz) literal(42)] [literal(quux) literal(314)]]}}
% Check if features are unique
fun {Unique FeatureList}
	case FeatureList of nil then false
	[] H|T then if {Member H T} then true else {Unique T} end
	end
end
% {Browse {Unique {GetRecordKeys [[literal(quuz) literal(42)] [literal(quuz) literal(314)]]}}}

% Sort Records which are List of List
fun {RecordSort Record}
	{Sort Record 
		fun {$ R1 R2}
			case R1 of literal(F1)|T then
				case R2 of literal(F2)|T1 then
					if {IsNumber F1} == {IsNumber F2} then F1 < F2
					else {IsNumber F1}
					end
				else raise error() end
				end
			else raise error() end
			end
		end
	}
end