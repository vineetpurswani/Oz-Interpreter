declare SAS SASCounter

SAS = {NewDictionary}
SASCounter = {NewCell 0}

proc {BindValueToKeyInSAS Key Val}
	case {Dictionary.get SAS Key} of unbound then {Dictionary.put SAS Key Val}
	[] reference(X) then {BindValueToKeyInSAS X Val}
	[] X then {Raise alreadyAssigned(Key Val X)}
	else skip end
end

proc {BindRefToKeyInSAS Key RefKey}
	case {Dictionary.get SAS Key} of unbound then {Dictionary.put SAS Key reference(RefKey)}
	[] reference(X) then {BindRefToKeyInSAS X RefKey}
	else skip end
end

fun {NextSASCounter}
	local C = @SASCounter in
		SASCounter := @SASCounter+1
		C
	end
end

fun {RetrieveFromSAS Key}
	% {Browse {Dictionary.entries SAS}}
	if {Dictionary.member SAS Key} then
		case {Dictionary.get SAS Key} of unbound then equivalence(Key)
		[] reference(X) then {RetrieveFromSAS X}
		else {Dictionary.get SAS Key} end
	else raise keyMissing(Key) end end
end

fun {AddKeyToSAS}
	local Key = {NextSASCounter} in
		{Dictionary.put SAS Key unbound}
		% {Browse {Dictionary.entries SAS}}
		Key
	end
end


	% {BindRefToKeyInSAS {AddKeyToSAS} {AddKeyToSAS}}
	% {BindRefToKeyInSAS 0 {AddKeyToSAS}}
	% {Browse {RetrieveFromSAS 0}}
	% {BindValueToKeyInSAS 0 23}
	% end