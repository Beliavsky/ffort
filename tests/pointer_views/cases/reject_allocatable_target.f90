program main
implicit none
integer,allocatable,target::a(:)
integer,pointer::p(:)
allocate(a(2))
p=>a
end program
