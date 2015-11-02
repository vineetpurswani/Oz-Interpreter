%% ---------------------------------------------------------------------------------
%% Authors:
%% Vineet Purswani			12813
%% Ayushman Sisodiya		12188
%% Deepak Kumar 			12228
%% ---------------------------------------------------------------------------------


% Three Sample Functions
declare
proc {Ones}
   {Browse 1}
end
declare
proc {Twos}
   {Browse 2}
end
declare
proc {Threes}
   {Browse 3}
end

%Runs the Nth Procedure in Xs list. N = 0,1,2,3..n-1
declare
proc {RunNth Xs N}
   case Xs
   of H|T then
      if(N==0) then
	 {H}
      else
	 {RunNth T N-1}
      end
   [] nil then skip
   end
end

%NSelect's Auxillary Function
declare
proc {Barrier2 Xs Vprev C TBound}
   local V in
      case Xs
      of H|nil then %The last element of list
	 local Done in
	    thread
	       if Vprev==1 then %AllFalse then execute the last statement
		  local P Q in
		     H = P#Q
		     {Q} % Execute the last element
		     Done = 1 % Set if All False
		  end
	       end
	    end
	    thread
	       if TBound == 1 then % If even one of stmt is true then TBound is bound
		  local RandNum NewRand ListLen TrueList ExecStmt in
		     TrueList = @C
		     {List.length TrueList ListLen} %List's length
		     {OS.rand RandNum} %Random Number
		     {Int.'mod' RandNum ListLen NewRand} %Take RandNum%ListLen to get random number in range 0-(Listlen-1)
		     %{Browse ListLen}
		     %{Browse NewRand}
		     {RunNth TrueList NewRand} % Run the NewRand'th element in the TrueList
		     Done = 1 % Gets Set if even one of the elements is true
		  end
	       end
	    end
	    if(Done == 1) then %Wait till Done Gets Bound
	       skip
	    end
	 end
	 
      [] H|T then
	 thread
	    local Y S in
	       H = Y#S
	       if(Y == true) then
		  C := S|@C % Append its Statement to the cell
		  TBound = 1 % One of the elements became True
	       else %False
		  V = Vprev
	       end
	    end
	 end
	 {Barrier2 T V C TBound}
      end
   end
end



declare
proc {NSelect Xs}
   local C TBound in
      {NewCell nil C} %First bind the cell C to nil
      {Barrier2 Xs 1 C TBound} %Initial Call to Barrier2
   end
end



%TEST CASES
local P Q R in
    {NSelect [true#Threes true#Twos true#Ones]} % Run one of the first two elements
   
   % {NSelect [false#Threes true#Twos true#Ones]} % Run the second Element
   
   % thread {Delay 5000} P=true end % Bind P to true after 5sec
   % {NSelect [P#Threes Q#Twos true#Ones]} %Wait till one of the vars get bound
   
   % thread {Delay 5000} P=false Q=false end % Bind P to true after 5sec
   % {NSelect [P#Threes Q#Twos true#Ones]} %Wait till one of the vars get bound
   
   % {NSelect [false#Threes false#Twos true#Ones]}  %Run the last one
   
   {Browse completedExecution}
end
