\insert 'Unify.oz'
% \insert 'SingleAssignmentStore.oz'

% functor
% import
% 	Browser(browse:Browse)

declare SemanticStack Store Environment

SemanticStack = {NewCell nil} 
Store = {NewDictionary}
% SASCounter = {NewCell 0}
Environment = environment()

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

% fun {NextSASCounter}
% 	local C = @SASCounter in
% 		SASCounter := @SASCounter+1
% 		C
% 	end
% end

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
		[] semanticStatement([bind ident(X) V] E) then
			% {BindValueToKeyInSAS E.X V}
			% case V of literal(_) then {Unify ident(X) V E}
			% skip
			case V of [proc ArgList Stmt] 
			then {Closure ArgList Stmt E}
			else {Unify ident(X) V E}

		% Straight forward If Else 	
		[] semanticStatement([conditional ident(X) S1 S2] E) then
			local XSASvalue in
				XSASvalue = {RetrieveFromSAS E.X} 
				if XSASvalue == equivalence(E.X) then raise unbound(X) end
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
			if {Unique {RemoveFeatureValues SortedXSASvalue}} then Match = false 
			elseif {Unique {RemoveFeatureValues SortedP1}} then Match = false
			% All corresponding features must be equal
			elseif {RemoveFeatureValues SortedXSASvalue} \= {RemoveFeatureValues SortedP1} then Match = false
			% Now bind all using unify and if passes then Match complete
			else
				{CreateAndUnify SortedXSASvalue SortedP1 E Enew}
				% {Browse Enew#fuck}
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
fun {RemoveFeatureValues Record}
	case Record 
	of nil then nil
	[] H|T then H.1 | {RemoveFeatureValues T}
	end
end
% {Browse {RemoveFeatureValues [[literal(quuz) literal(42)] [literal(quux) literal(314)]]}}
% Check if features are unique
fun {Unique FeatureList}
		case FeatureList of nil then false
		[] H|T then if {Member H T} then true else {Unique T} end
		end
end
% {Browse {Unique {RemoveFeatureValues [[literal(quuz) literal(42)] [literal(quuz) literal(314)]]}}}

% Sort Records which are List of List
fun {RecordSort Record}
	{Sort Record CompareFunc}
end

% Compare function for sorting records. If the two features are of same type then it is '<'
% If not the number is given the preferance
fun {CompareFunc R1 R2}
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

%     {Push 
%  [localvar ident(foo)
%   [localvar ident(result)
%    [[bind ident(foo) literal(f)]
%     [conditional ident(foo)
%      [bind ident(result) literal(t)]
%      [bind ident(result) literal(f)]]
%     %% Check
%     [bind ident(result) literal(f)]]]]Environment}


% for pattern match passes
{Push  [localvar ident(foo)
  [localvar ident(result)
   [[bind ident(foo) [record literal(bar)
                       [[literal(baz) literal(42)]
                       [literal(quux) literal(314)]]]]
    [match ident(foo) [record literal(bar)
                           [[literal(baz) ident(fortytwo)]
                           [literal(quux) ident(pitimes100)]]]
     [bind ident(result) ident(fortytwo)] %% if matched
     [bind ident(result) literal(314)]] %% if not matched
    %% This will raise an exception if result is not 42
    [bind ident(result) literal(42)]
    ]]] Environment}


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

