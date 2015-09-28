%% ---------------------------------------------------------------------------------
%% Authors:
%% Vineet Purswani			12813
%% Ayushman Sisodiya		12188
%% Deepak Kumar 			12228

%% Global Variables:
%% SAS 			- Single Assignment Store - a dictionary data structure
%% SASCounter 	- Counter to keep track of store variables

%% Functions and Procedures:
%% BindValueToKeyInSAS	- If Key is unbound (value is part of an equivalence set) bind Val to a key in the SAS. Should raise an exception alreadyAssigned(Key Val CurrentValue) if the key is bound.
%% BindRefToKeyInSAS	- If the key is unbound, then bind a reference to another key to a key in the SAS. 
%% NextSASCounter		- Increments and returns the value of SASCounter.
%% RetrieveFromSAS		- Retrieve a value from the single assignment store. This will raise an exception if the key is missing from the SAS. For unbound keys, this will return equivalence(Key) 
%% AddKeyToSAS			- Add a key to the single assignment store. This will return the key that you can associate with your identifier and later assign a value to.
%% ---------------------------------------------------------------------------------


declare SAS SASCounter

SAS = {NewDictionary}
SASCounter = {NewCell 0}

proc {BindValueToKeyInSAS Key Val}
	case {Dictionary.get SAS Key} of unbound then {Dictionary.put SAS Key Val}
	[] reference(X) then 
		{BindValueToKeyInSAS X Val}
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
	if {Dictionary.member SAS Key} then
		local Value = {Dictionary.get SAS Key} in
			case Value of unbound then equivalence(Key)
			[] reference(X) then {RetrieveFromSAS X}
			else Value end
		end
	else raise keyMissing(Key) end end
end

fun {AddKeyToSAS}
	local Key = {NextSASCounter} in
		{Dictionary.put SAS Key unbound}
		Key
	end
end
