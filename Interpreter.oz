%% ---------------------------------------------------------------------------------
%% Authors:
%% Vineet Purswani			12813
%% Ayushman Sisodiya		12188
%% Deepak Kumar 			12228

%% Global Variables:
%% SemanticStack 	- Stack data structure to store semantic statements
%% Program 			- AST string of the program

%% Functions and procedures:
%% Push 		- push a semantic statement on the semantic stack
%% Pull 		- pull a semantic statement from the top of the semantic stack
%% Interpreter 	- recursive interpreting procedure that runs over the program given.
%% ---------------------------------------------------------------------------------

\insert 'Unify.oz'

declare SemanticStack Environment Program
SemanticStack = {NewCell nil} 
Environment = environment()
Program = [localvar ident(foo)
		  [localvar ident(bar)
		   [[bind ident(foo) [record literal(person) [literal(name) ident(bar)]]]
		    [bind ident(bar) [record literal(person) [literal(name) ident(foo)]]]
		    [bind ident(foo) ident(bar)]]]]

proc {Push Stmt Env}
	case Stmt of nil then skip
	else SemanticStack := semanticStatement(Stmt Env) | @SemanticStack end
end

fun {Pull}
	case @SemanticStack of nil then nil
	else 
		local Top = @SemanticStack.1 in
			SemanticStack := @SemanticStack.2
			Top
		end
	end
end

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
		{Adjoin environment(X:E.X) {MakeEnvironment Xs E}}
	else environment() end
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
	else environment(nil)
	end
end

proc {Interpreter}
	{Browse @SemanticStack}
	{Browse {Dictionary.entries SAS}}
	case @SemanticStack of nil then skip
	else 
		case {Pull} of semanticStatement([nop] E) then 
			skip
		[] semanticStatement([localvar ident(X) S] E) then
			{Push S {Adjoin E environment(X:{AddKeyToSAS})}}
		[] semanticStatement([bind ident(X) ident(Y)] E) then
			{Unify ident(X) ident(Y) E}
		[] semanticStatement([bind X1 Y1] E) then
		% Handle case for [bind literal(1) literal(2)]
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

				case V of [subr ArgList Stmt] 
				% calculate closure. But for now I am taking the superset i.e. E
				then local Closure in
					Closure = E % calculate your closure here
					% Closure = {CalcClosure Stmt 
					% 			{AdjoinList E {Map ArgList 
					% 				fun {$ A} case A of ident(X) then X#0 else raise error() end end end
					% 			}}}
					{Unify ident(X) procedure(ArgList Stmt Closure) E}
					end
				else {Unify ident(X) V E}
				end
			end
		[] semanticStatement(apply|ident(X)|ArgListActual E) then
			local XSASvalue in
				XSASvalue = {RetrieveFromSAS E.X}
				case XSASvalue of procedure(ArgListFormal Stmt Closure) then
					% {Browse ArgListFormal#Stmt#Closure}
					% {Browse ArgListActual}
					if {Length ArgListFormal} \= {Length ArgListActual} then raise argumentsdonotmatch() end
					else
						local NewClosure in
							NewClosure = {AddArgsToClosure ArgListFormal ArgListActual Closure E}
							{Push Stmt NewClosure}
						end
					end
				else raise xnotaprocedure() end
				end
			end
		% Straight forward If Else 	
		[] semanticStatement([conditional ident(X) S1 S2] E) then
			local XSASvalue in
				XSASvalue = {RetrieveFromSAS E.X} 
				% DOUBT - equivalence(E.X) - sometimes it is not necessary that equivalence returns the same store variable. 
				% Eg. X=Y. In this case {RetrieveFromSAS E.X} will return equivalence(y)
				if XSASvalue == equivalence(E.X) then raise unbound(X) end
				% DOUBT - true or t?
				elseif XSASvalue == literal(t) then {Push S1 E}
				elseif XSASvalue == literal(f) then {Push S2 E}
				else raise wrongtype(X) end
				end
			end
		% Pattern matching 
		[] semanticStatement([match ident(X) P1 S1 S2] E) then
			local XSASvalue Match Enew in
				XSASvalue = {RetrieveFromSAS E.X}
				% check unbound. If yes than raise error
				if XSASvalue == equivalence(E.X) then raise unbound(X) end
				% If it is not even a record then raise error
				elseif XSASvalue.1 \= record then raise notrecord(X) end
				% If the pattern is not a record then S2 will be executed with E environment
				elseif P1.1 \= record then {Push S2 E}
				% If all above cases fail then try match patterns
				else 
					% Function to match and bound the P1. Match contains whether the match was successfull or not. If it was Enew contains the new environment
					{MatchAndBind XSASvalue P1 E Match Enew}
					{Browse Enew}
					if Match == true then {Push S1 Enew} else {Push S2 E} end
				end
			end
		[] semanticStatement(S1|S2 E) then 
			{Push S2 E}
	        {Push S1 E}
		else skip end
		{Interpreter}
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
		% [] [literal(_) V]|T1 then
		% 	skip
			% handle values wala case
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
	[] H|T then H.2 | {GetRecordValues T}
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

% Compare function for sorting records. If the two features are of same type then it is '<'
% If not the number is given the preferance
% fun {CompareFunc R1 R2}
% 	case R1 of literal(F1)|T then
% 		case R2 of literal(F2)|T1 then
% 			if {IsNumber F1} == {IsNumber F2} then F1 < F2
% 			else {IsNumber F1}
% 			end
% 		else raise error() end
% 		end
% 	else raise error() end
% 	end
% end


% Example for procedure

% {Push [localvar ident(result) [localvar ident(foo) [[bind ident(foo) [subr [ident(x1)] [bind ident(x1) literal(1)]]] [apply ident(foo) ident(result)]]]] Environment}
{Push [localvar ident(foo)
 [localvar ident(bar)
  [[bind ident(foo)
    [record literal(person)
     [literal(name) ident(foo)]]]
   [bind ident(bar) [record literal(person) [literal(name) ident(bar)]]]
   [bind ident(foo) ident(bar)]]]] environment()}

% Example for sort
% {Browse {RecordSort [[literal(quuz) literal(42)]
%                        [literal(quux) literal(314)]]}}
% {Push 
% [localvar ident(foo)
%   [localvar ident(bar)
%    [[bind ident(foo) [record literal(person) [literal(name) ident(bar)]]]
%     ]]] Environment}

% {Push 
% [localvar ident(foo)
%   [localvar ident(bar) [bind ident(foo) literal(t)]]] Environment}
% {Push 
%  [localvar ident(foo)
%   [localvar ident(result)
%    [[bind ident(foo) literal(t)]
%     [conditional ident(foo)
%      [bind ident(result) literal(t)]
%      [bind ident(result) literal(f)]]
%     %% Check
%     [bind ident(result) literal(t)]]
%     ]] Environment}

 %    {Push 
 % [[localvar ident(foo)
 %  [localvar ident(result)
 %   [[bind ident(foo) literal(f)]
 %    [conditional ident(foo)
 %     [bind ident(result) literal(t)]
 %     [bind ident(result) literal(f)]]
 %    %% Check
 %    [bind ident(result) literal(f)]]]]] Environment}


% for pattern match passes
% {Push  [localvar ident(foo)
%   [localvar ident(result)
%    [[bind ident(foo) [record literal(bar)
%                        [[literal(baz) literal(42)]
%                        [literal(quux) literal(314)]]]]
%     [match ident(foo) [record literal(bar)
%                            [[literal(baz) ident(fortytwo)]
%                            [literal(quux) ident(pitimes100)]]]
%      [bind ident(result) ident(fortytwo)] %% if matched
%      [bind ident(result) literal(314)]] %% if not matched
%     %% This will raise an exception if result is not 42
%     [bind ident(result) literal(42)]
%     ]]] Environment}


% for pattern match fails
% {Push  [localvar ident(foo)
%   [localvar ident(result)
%    [[bind ident(foo) [record literal(bar)
%                        [literal(baz) literal(42)]
%                        [literal(quux) literal(314)]]]
%     [match ident(foo) [record literal(bar)
%                            [literal(quux) ident(pitimes100)]]
%      [bind ident(result) ident(fortytwo)] %% if matched
%      [bind ident(result) literal(314)]] %% if not matched
%     %% This will raise an exception if result is not 42
%     [bind ident(result) literal(42)]
%     ]]] Environment}


{Interpreter}
% {Browse {Dictionary.entries SAS}}
% end
