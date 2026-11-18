program probe
implicit none
integer,allocatable :: a(:)
integer,parameter :: b(-3:-1)=[1,2,3]
a=b
print *,lbound(a,1),ubound(a,1),a
end program
