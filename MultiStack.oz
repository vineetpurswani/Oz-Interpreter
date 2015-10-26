%% ---------------------------------------------------------------------------------
%% Authors:
%% Vineet Purswani			12813
%% Ayushman Sisodiya		12188
%% Deepak Kumar 			12228
%% ---------------------------------------------------------------------------------


\insert 'Queue.oz'

declare

proc {Push SemanticStack Stmt Env}
	case Stmt of nil then skip
	else SemanticStack := semanticStatement(Stmt Env) | @SemanticStack end
end

fun {Pull SemanticStack}
	case @SemanticStack of nil then nil
	else 
		local Top = @SemanticStack.1 in
			SemanticStack := @SemanticStack.2
			Top
		end
	end
end

proc {AddStack Stmt Env}
	local SemanticStack = {NewCell nil} in
		{Push SemanticStack Stmt Env}
		{QueuePut stack(SemanticStack ready)}
	end
end

fun {TopExecutableStack}
	% if {QueueIsEmpty} == true
	% then raise terminate() end
	% else
	local Helper Helper1 in
		fun {Helper}
			case {QueueTop}
			of stack(TempStack ready) then TempStack|nil
			% Check for suspended threads if they are ready to execute
			[] stack(TempStack suspend#X) then
				case {RetrieveFromSAS X}
				of equivalence(_) then {QueueGet}|{Helper}
				else TempStack|nil
				end
			else {QueueGet}|{Helper}
			end
		end
		fun {Helper1 Array}
			case Array
			of X|nil then X
			[] H|T then {QueuePut H} {Helper1 T}
			end
		end
		{Helper1 {Helper}}	
	end
	% end
end

proc {GetPutEmptyStack}
	case {QueueGet} 
	of stack(TempStack _) then {QueuePut stack(TempStack empty)}
	end
end

proc {GetPutSuspendedStack X}
	case {QueueGet} 
	of stack(TempStack _) then {QueuePut stack(TempStack suspend#X)}
	end
end
