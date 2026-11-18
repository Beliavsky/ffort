program p
implicit none
integer::i(0),j(2,0,1)
real(8)::r(0)
print *,size(dim(i,3)),size(sign(-2,j)),size(log_gamma(r))
end program
