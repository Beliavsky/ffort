program p
implicit none
real(8)::aa(2,3)
print *,kind(sum(aa)),kind(sum(aa,dim=1))
end program p
