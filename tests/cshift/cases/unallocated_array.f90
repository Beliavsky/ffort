program p
implicit none
integer,allocatable::a(:),b(:)
b=cshift(a,1)
print *, "PASS"
end program
