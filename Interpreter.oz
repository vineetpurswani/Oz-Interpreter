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
			{Unify ident(X) V E}
		[] semanticStatement(S1|S2 E) then 
			{Push S2 E}
			{Push S1 E}
		else skip end
		{Interpreter}
	end
end

{Push Program Environment}
{Interpreter}
