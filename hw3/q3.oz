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

local X Length in
   X = {Append [1 2 3] [4 5 6]}
   %{List.length X Length} %To show laziness uncomment
   {Browse X}
end
