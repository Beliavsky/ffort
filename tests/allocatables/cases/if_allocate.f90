program main
implicit none
integer,allocatable::a(:)
if(.not.allocated(a)) allocate(a(2))
a=5
if(allocated(a)) deallocate(a)
print *,allocated(a)
end program
