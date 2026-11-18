program p
implicit none
integer,allocatable::a(:)
allocate(a(-3:0));a=[3,2,3,1]
print *,findloc(a,3,back=.true.),findloc(a,2,1)
end program
