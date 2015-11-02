%% ---------------------------------------------------------------------------------
%% Authors:
%% Vineet Purswani			12813
%% Ayushman Sisodiya		12188
%% Deepak Kumar 			12228


declare
fun lazy {GenOnes}
   1|{GenOnes}
end

declare
fun lazy {AddStream Xs Ys}
   Xs.1+Ys.1|{AddStream Xs.2 Ys.2}
end

%Returns Y(n+1)
declare
fun {GetFirstTerm Ys Xs Ps}
   local T1 T2 T3 B in
      {Float.is Ys.1 B}
      {Int.toFloat Ps.1 T2}
      {Int.toFloat Xs.1 T3}
      if B then
         T1 = Ys.1
         ((T1*T2)+T3)/(T2+1.0)
      else
          {Int.toFloat Ys.1 T1}
    ((T1*T2)+T3)/(T2+1.0)
      end      
       %Return Value
      % y(n+1) = [n*y(n) + x(n+1)]/[n+1]
   end
end

%Calculates the last term and recursively calls itself to generate the stream
declare
fun lazy {Avg Ys Xs Ps}
   {GetFirstTerm Ys Xs Ps}|{Avg Ys.2 Xs.2 Ps.2}
end


%Generates the Bits 0 or 1 in the stream Xs
declare
fun {GenBits}
   local X Y in
      {Delay 100}  %To Comment
      {OS.rand X}
      {Int.'mod' X 2 Y}
      Y|{GenBits}
   end
end

%Prints the Stream Ys
declare
proc {Printlist Ys}
   case Ys
   of H|T then
      {Browse H}
      {Printlist T}
   end
end




%TO RUN FUNCTION
%TEST
local Xs Ys Ps in
   thread %Producer
      Xs = {GenBits} %Creates a stream of 1s and 0s
   end
   
   thread  %Consumer
      local PosInts Ones in
         Ones = {GenOnes} % Generate stream of Ones 1|1|1..
         PosInts = 1|{AddStream Ones PosInts} % Generate Stream 1|2|3|4|5...
         Ys = Xs.1|{Avg Ys Xs.2 PosInts} % Generate the Avg of Ones List
      end
   end
   
   thread
      {Printlist Ys} %Print the List Ys. Not Browse BCoz I'm generating Ys Lazily
   end
end
