program p
implicit none
real(8)::aa(0),bb(2)
bb=[aa,1d0,aa,2d0,aa]
print *,bb,kind([aa,1d0])
end program p
