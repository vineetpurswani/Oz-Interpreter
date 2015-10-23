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

declare SemanticStack Environment Program
SemanticStack = {NewCell nil} 
Environment = environment()
Program = [localvar ident(foo)
			 [localvar ident(bar)
			  [localvar ident(quux)
			   [[bind ident(bar) [subr [ident(baz)]
					      [bind [record literal(person)
						     [literal(age) ident(foo)]] ident(baz)]]]
			    [apply ident(bar) ident(quux)]
			    [bind [record literal(person) [literal(age) literal(40)]] ident(quux)]
			    [bind literal(40) ident(foo)]]]]]

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
					% {Browse Enew}
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

{Push Program environment()}
try {Interpreter}
catch Err then
	case Err  
	of argumentsizedifferent(X) then {Browse X} {Browse 'Procedure call has different arguments than defined'}
	[] notaprocedure(X) then {Browse X} {Browse 'Not a procedure'}
	[] unbound(X) then {Browse X} {Browse ' is unbound'}
	[] notabool(X) then {Browse X} {Browse' not a bool'}
	[] patternnotincorrectformat(SortedP1) then {Browse SortedP1} {Browse 'Pattern Not in the given format'}
	[] error() then {Browse 'Something went wrong contact the Authors of this code'}
	[] somethingwrong() then {Browse 'Something went wrong contact the Authors of this code'}
	[] notacorrectstatement(Temp) then {Browse Temp} {Browse' is not in the given kernel language'}
	[] notrecord(X) then {Browse X} {Browse' is not a record'}
	 else {Browse 'Unidentified Exception!!'}
   end
   {Browse 'Error! Exiting...'}
finally
   {Browse 'Thank you for using our interpreter' }
end