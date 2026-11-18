program p
implicit none

real(8),allocatable::a(:)
allocate(a(3));a=1
print *,nearest(a,1.)>a,spacing(a)==epsilon(1d0)
end program
