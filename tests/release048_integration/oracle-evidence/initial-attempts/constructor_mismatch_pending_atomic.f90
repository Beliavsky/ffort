program p
implicit none
character(:),allocatable::s,t,c(:)
s='AA'
t='B'
write(*,'(z2.2)',advance='no')ior(8,7)
c=[s,t]
end program
