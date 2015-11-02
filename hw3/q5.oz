declare
fun {MergeStream Xs Ys Zs}
   %{Delay 500}
   if Xs.1 < Ys.1 then
      if Xs.1 < Zs.1 then
	 Xs.1|{MergeStream Xs.2 Ys Zs}
      elseif Xs.1 == Zs.1 then % To skip both Xs and Zs. Avoiding multiple prints
	 Xs.1|{MergeStream Xs.2 Ys Zs.2}
      else
	 Zs.1|{MergeStream Xs Ys Zs.2}
      end
   elseif Xs.1 == Ys.1 then
      if Xs.1 < Zs.1 then
	 Xs.1|{MergeStream Xs.2 Ys.2 Zs}
      elseif Xs.1 == Zs.1 then
	 Xs.1|{MergeStream Xs.2 Ys.2 Zs.2}
      else
	 Zs.1|{MergeStream Xs Ys Zs.2}
      end
   else
      if Ys.1 < Zs.1 then
	 Ys.1|{MergeStream Xs Ys.2 Zs}
      elseif Ys.1 == Zs.1 then
	 Ys.1|{MergeStream Xs Ys.2 Zs.2}
      else
	 Zs.1|{MergeStream Xs Ys Zs.2}
      end
   end
end


declare
fun {Scale X K}
   % Delay Added to have effective Browse
   {Delay 500}
   K*X.1|{Scale X.2 K}
end

% Just as taught in the class by sir (although not available in his notes)
declare
proc {HammingFun}
   local As Bs Cs Ds Hamming in
      Hamming = 1|Ds
      thread As = {Scale Hamming 2} end
      thread Bs = {Scale Hamming 3} end
      thread Cs = {Scale Hamming 5} end
      thread Ds = {MergeStream As Bs Cs} end
      {Browse Hamming}
   end
end

% Function Call
{HammingFun}