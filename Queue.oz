%% ---------------------------------------------------------------------------------
%% Inspired from Queue.oz of Standard Mozart Library
%% ---------------------------------------------------------------------------------

declare L MultiSemanticStack

MultiSemanticStack = {NewCell 0#L#L}

fun {QueueGet} Old New in
	{Exchange MultiSemanticStack Old New}
	case Old of N#L1#L2 then
	%% note that we leave the queue in a consistent state
	%% even if the operation raises an exception
	if N==0 then New=Old raise empty end
	elsecase L1 of H|T then New=N-1#T#L2 H end
	end
end

proc {QueuePut X} New in
	case {Exchange MultiSemanticStack $ New}
	of N#L1#L2 then L3 in L2=X|L3 New=N+1#L1#L3 end
end

fun {QueueTop}
	case {Access MultiSemanticStack}
	of N#L1#_ then
	case N of 0 then raise empty end
	elsecase L1 of X|_ then X end
	end
end
