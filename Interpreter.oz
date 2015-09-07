functor
import
	Browser(browse:Browse)

define SemanticStack Store SASCounter Environment
	SemanticStack = {NewCell nil} 
	Store = {NewDictionary}
	SASCounter = {NewCell 0}
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

	fun {NextSASCounter}
		local C = @SASCounter in
			SASCounter := @SASCounter+1
			C
		end
	end

	proc {Interpreter}
		{Browse @SemanticStack}
		case @SemanticStack of nil then skip
		else 
			case {Pull} of semanticStatement([nop] E) then 
				skip
			[] semanticStatement([localvar ident(X) S] E) then
				{Push S {Adjoin E environment(X:{NextSASCounter})}}
			% [] semanticStatement(stmt: [bind ident(X) ident(Y)] env: E) then
			% 	{BindStore X Y}
			[] semanticStatement(S1|S2 E) then 
				{Push S2 E}
				{Push S1 E}
			else skip end
			{Interpreter}
		end
	end

	{Push [localvar ident(x) [localvar ident(y) [localvar ident(x) [nop]]]] nil}
	{Interpreter}

end

