declare
fun lazy {GenOnes}
   1|{GenOnes}
end

declare
fun lazy {AddStream Xs Ys}
   Xs.1+Ys.1|{AddStream Xs.2 Ys.2}
end

%Tested Works
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

declare
fun lazy {Avg Ys Xs Ps}
   {GetFirstTerm Ys Xs Ps}|{Avg Ys.2 Xs.2 Ps.2}
end

%Tested Works


declare
fun {GenBits}
   local X Y in
      {Delay 100}  %To Comment
      {OS.rand X}
      {Int.'mod' X 2 Y}
      Y|{GenBits}
   end
end

declare
proc {Printlist Ys}
   case Ys
   of H|T then
      {Browse H}
      % {Browse hello}
      {Printlist T}
   end
end


local Xs Ys Ps in
   thread %Producer
      Xs = {GenBits}
   end 
   thread  %Consumer
      local PosInts Ones in
         Ones = {GenOnes}
         PosInts = 1|{AddStream Ones PosInts}
         Ys = Xs.1|{Avg Ys Xs.2 PosInts}
      end
   end
   thread
      {Browse {List.take Ys 10}}
   end
   thread
      {Browse {List.take Xs 10}}
   end
end