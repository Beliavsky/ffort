module m
implicit none
contains
subroutine show(a,mask)
integer,intent(in)::a(:,:)
logical,intent(in)::mask(:,:)
print *, pack(a,mask,[9,8,7,6])
end subroutine
end module
program main
use m
implicit none
integer::a(2,2)
logical::mask(2,2)
a(:,1)=[1,2]
a(:,2)=[3,4]
mask=a>2
call show(a,mask)
end program
