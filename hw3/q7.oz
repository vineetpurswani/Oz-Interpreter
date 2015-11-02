%% ---------------------------------------------------------------------------------
%% Authors:
%% Vineet Purswani			12813
%% Ayushman Sisodiya		12188
%% Deepak Kumar 			12228
%% ---------------------------------------------------------------------------------


declare
proc {Barrier2 Xs Vprev Flg}
   local V in
      case Xs
      of H|T then
	 %if Flg==1 then %Flg is 1 only for the first time
	 %   thread
	 %      {H}
	 %      V = 1
	 %   end
	 %   {Barrier2 T V 0}
	 %else
	    thread
	       {H}
	       V = Vprev
	    end
	    {Barrier2 T V 0}
	 %end
      [] nil then
	 if Vprev==1 then skip %End of execution
	 end
      end
   end
end

declare
proc {Barrier Xs}
   local V in
      V = 1 %Dummy :p
      {Barrier2 Xs V 1}
   end
end



%Test Case
local Ones Twos Threes X Y Z in
    proc {Ones}
       local T in
	 % {Delay 5000}
	  T = 1
	  X = T
       end
    end

    proc {Twos}
       local T in
	  {Delay 5000}
	  T = 2
	  Y = T
       end
    end

    proc {Threes}
       local T in
	  {Delay 5000}
	  T = 3
	  Z = T
       end
    end
    {Browse [X Y Z]}
    {Barrier [Ones Twos Threes]}
    {Browse completed}
end
