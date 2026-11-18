program main
implicit none
integer,allocatable::a(:)
allocate(a(2))
print *,a(1)
end program
