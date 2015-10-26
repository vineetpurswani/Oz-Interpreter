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
\insert 'ProcessHelper.oz'
\insert 'MultiStack.oz'

declare Program 

% Program = [localvar ident(foo)
% 			 [localvar ident(bar)
% 			  [localvar ident(quux)
% 			   [[bind ident(bar) [subr [ident(baz)]
% 					      [bind [record literal(person)
% 						     [literal(age) ident(foo)]] ident(baz)]]]
% 			    [apply ident(bar) ident(quux)]
% 			    [bind [record literal(person) [literal(age) literal(40)]] ident(quux)]
% 			    [bind literal(40) ident(foo)]]]]]

Program = [localvar ident(foo)
		  [localvar ident(bar)
		    [
		    [spawn [bind ident(foo) literal(f)]]
		    [conditional ident(foo) [bind ident(bar) literal(2)] [bind ident(bar) literal(0)]]
		    % [spawn [bind ident(foo) ident(bar)]]
		    % [spawn [bind ident(foo) literal(1)]]
		    ]
		  ]]

proc {ThreadInterpreter SemanticStack}
	{Browse @SemanticStack}
	{Browse {Dictionary.entries SAS}}
	case @SemanticStack of nil then {GetPutEmptyStack} {Interpreter}
	else
		case {Pull SemanticStack} of semanticStatement([nop] E) then 
			skip
			%{ThreadInterpreter SemanticStack}
		[] semanticStatement([localvar ident(X) S] E) then
			{Push SemanticStack S {Adjoin E environment(X:{AddKeyToSAS})}}
			%{ThreadInterpreter SemanticStack}
		[] semanticStatement([bind ident(X) ident(Y)] E) then
			{Unify ident(X) ident(Y) E}
			%{ThreadInterpreter SemanticStack}
		[] semanticStatement([bind X1 Y1] E) then
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
					% Closure = E % calculate your closure here
					Closure = {CalcClosure Stmt 
								{AdjoinList E {Map ArgList 
									fun {$ A} case A of ident(X) then X#0 else raise error() end end end
								}}}
					{Unify ident(X) procedure(ArgList Stmt Closure) E}
					end
				else {Unify ident(X) V E}
				end
			end
			%{ThreadInterpreter SemanticStack}
		[] semanticStatement(apply|ident(X)|ArgListActual E) then
			local XSASvalue in
				XSASvalue = {RetrieveFromSAS E.X}
				case XSASvalue 
				of procedure(ArgListFormal Stmt Closure) then
					% {Browse ArgListFormal#Stmt#Closure}
					% {Browse ArgListActual}
					if {Length ArgListFormal} \= {Length ArgListActual} then raise argumentsdonotmatch() end
					else
						local NewClosure in
							NewClosure = {AddArgsToClosure ArgListFormal ArgListActual Closure E}
							{Push SemanticStack Stmt NewClosure}
						end
					end
					%{ThreadInterpreter SemanticStack}
				[] equivalence(_) then 
					{Push SemanticStack apply|ident(X)|ArgListActual E}
					raise unbound(X#E.X) end
					% {GetPutSuspendedStack E.X} 
					% {Interpreter}
				else raise xnotaprocedure() end
				end
			end
		% Straight forward If Else 	
		[] semanticStatement([conditional ident(X) S1 S2] E) then
			local XSASvalue in
				XSASvalue = {RetrieveFromSAS E.X} 
				% DOUBT - equivalence(E.X) - sometimes it is not necessary that equivalence returns the same store variable. 
				% Eg. X=Y. In this case {RetrieveFromSAS E.X} will return equivalence(y)
				case XSASvalue of equivalence(_) then 
					{Push SemanticStack [conditional ident(X) S1 S2] E}
					raise unbound(X#E.X) end
					% {GetPutSuspendedStack E.X} 
					% {Interpreter}
				% DOUBT - true or t?
				[] literal(t) then {Push SemanticStack S1 E}
					%{ThreadInterpreter SemanticStack}
				[] literal(f) then {Push SemanticStack S2 E}
					%{ThreadInterpreter SemanticStack}
				else raise wrongtype(X) end
				end
			end
		% Pattern matching 
		[] semanticStatement([match ident(X) P1 S1 S2] E) then
			local XSASvalue Match Enew in
				XSASvalue = {RetrieveFromSAS E.X}

				if XSASvalue.1 \= record then raise notrecord(X) end
				% If the pattern is not a record then S2 will be executed with E environment
				elseif P1.1 \= record then {Push SemanticStack S2 E}
				% If all above cases fail then try match patterns
					%{ThreadInterpreter SemanticStack}
				else
					% check unbound. If yes than raise error
					case XSASvalue of equivalence(_) then
					 	{Push SemanticStack [match ident(X) P1 S1 S2] E}
					 	raise unbound(X#E.X) end
						% {GetPutSuspendedStack E.X} 
						% {Interpreter}
					% If it is not even a record then raise error
					else 
						% Function to match and bound the P1. Match contains whether the match was successfull or not. If it was Enew contains the new environment
						{MatchAndBind XSASvalue P1 E Match Enew}
						% {Browse Enew}
						if Match == true then {Push SemanticStack S1 Enew} else {Push SemanticStack S2 E} end
						%{ThreadInterpreter SemanticStack}
					end
				end
			end
	    [] semanticStatement([spawn Stmt] E) then
	    	{AddStack Stmt E}
			%{ThreadInterpreter SemanticStack}
		[] semanticStatement(S1|S2 E) then 
			{Push SemanticStack S2 E}
	        {Push SemanticStack S1 E}
			%{ThreadInterpreter SemanticStack}
		else
			skip
			%{ThreadInterpreter SemanticStack}
		end
		{ThreadInterpreter SemanticStack}
	end
end

proc {Interpreter}
try
	local Stack in
		Stack = {TopExecutableStack}
		{ThreadInterpreter Stack}
	end

catch Err then
	% {Browse Err}
	case Err  
	of argumentsizedifferent(X) then {Browse X} {Browse '- Procedure call has different arguments than defined'}
	[] notaprocedure(X) then {Browse X} {Browse '- Not a procedure'}
	% Suspend thread. Whereas in others, terminate.
	[] unbound(X#V) then 
		{GetPutSuspendedStack V} 
		{Interpreter}
		% {Browse X} {Browse '- is unbound. Thread suspended.'}
	[] notabool(X) then {Browse X} {Browse '- not a bool'}
	[] patternnotincorrectformat(SortedP1) then {Browse SortedP1} {Browse '- Pattern Not in the given format'}
	[] error() then {Browse 'Something went wrong contact the Authors of this code'}
	[] somethingwrong() then {Browse 'Something went wrong contact the Authors of this code'}
	[] notacorrectstatement(Temp) then {Browse Temp} {Browse '- is not in the given kernel language'}
	[] notrecord(X) then {Browse X} {Browse '- is not a record'}
	[] incompatibleTypes(X Y) then  {Browse X} {Browse ' and '} {Browse Y} {Browse '- Bind error.'}
	[] empty then {Browse 'Program terminated!'}
	else {Browse 'Unidentified Exception!!'}
   end
finally
	skip
%    {Browse 'Thank you for using our interpreter' }
end
end

{AddStack Program environment()}
{Interpreter}
{Browse 'Thank you for using our interpreter' }

% {Push Program environment()}
% try {Interpreter}
% catch Err then
% 	{Browse Err}
% 	case Err  
% 	of argumentsizedifferent(X) then {Browse X} {Browse '- Procedure call has different arguments than defined'}
% 	[] notaprocedure(X) then {Browse X} {Browse '- Not a procedure'}
% 	% Suspend thread. Whereas in others, terminate.
% 	% [] unbound(X#V) then 
% 	% 	{GetPutSuspendedStack V} 
% 	% 	{Interpreter}
% 	% 	{Browse X} {Browse '- is unbound. Thread suspended.'}
% 	[] notabool(X) then {Browse X} {Browse '- not a bool'}
% 	[] patternnotincorrectformat(SortedP1) then {Browse SortedP1} {Browse '- Pattern Not in the given format'}
% 	[] error() then {Browse 'Something went wrong contact the Authors of this code'}
% 	[] somethingwrong() then {Browse 'Something went wrong contact the Authors of this code'}
% 	[] notacorrectstatement(Temp) then {Browse Temp} {Browse '- is not in the given kernel language'}
% 	[] notrecord(X) then {Browse X} {Browse '- is not a record'}
% 	[] incompatibleTypes(X Y) then  {Browse X} {Browse ' and '} {Browse Y} {Browse '- Bind error.'}
% 	[] empty then {Browse 'Program terminated!'}
% 	else {Browse 'Unidentified Exception!!'}
%    end
%    % {Browse 'Error! Exiting...'}
% finally
%    {Browse 'Thank you for using our interpreter' }
% end