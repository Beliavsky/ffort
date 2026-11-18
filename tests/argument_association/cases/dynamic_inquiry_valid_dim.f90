program main

implicit none
integer :: a(-2:2),d
d=1
print *,size(a,d),lbound(a,d),ubound(a,d)
end program main
