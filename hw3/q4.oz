%% ---------------------------------------------------------------------------------
%% Authors:
%% Vineet Purswani			12813
%% Ayushman Sisodiya		12188
%% Deepak Kumar 			12228
%% ---------------------------------------------------------------------------------

declare
fun lazy {Append Xs Ys}
   case Xs
   of H|T then
      H|{Append T Ys}
   [] nil then
      Ys
   end
end


declare
proc {Partition Pivot Xs PartitionLeft PartitionRight}
   local LVar RVar in
      case Xs
      of H|T then
	 if(H < Pivot) then
	    PartitionLeft = H|LVar
	    {Partition Pivot T LVar PartitionRight}
	 else
	    PartitionRight = H|RVar
	    {Partition Pivot T PartitionLeft RVar}
	 end
      [] nil then
	 PartitionLeft = nil
	 PartitionRight = nil
      end
   end	 
end

%Similar to the one given in Sir's intro lecture examples
declare
fun lazy{QuickSort Xs}
   case Xs
   of H|T then
      local PartitionLeft PartitionRight in
	 {Partition H T PartitionLeft PartitionRight}
	 {Append {QuickSort PartitionLeft} H|{QuickSort PartitionRight}}
      end
   [] nil then nil
   end
end


%To Test the QuickSort
local Len in
   X = {QuickSort [9 8 7 6 5 4 3 2 1]}
   {Browse X}
   % Code below is to show laziness
    {Delay 4000}
    {List.length X Len}
end

