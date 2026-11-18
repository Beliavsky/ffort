module m
implicit none
contains
subroutine show(a,mask)
integer,intent(in)::a(:,:)
logical,intent(in)::mask(:,:)
print *,size(pack(a,mask))
end subroutine
end module
program main
use m
implicit none
integer::a(0,2)
logical::mask(0,3)
call show(a,mask)
end program
