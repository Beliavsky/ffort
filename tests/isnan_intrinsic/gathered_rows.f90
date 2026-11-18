program p
implicit none
real(8)::a(3,2)
a=1d0
print *,isnan(a([3,1],:))
end program
