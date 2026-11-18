module m
implicit none
contains
function selected(a) result(b)
integer,intent(in)::a(:,:)
integer::b(count(a>0))
b=pack(reshape(a,[size(a)]),reshape(a>0,[size(a)]))
end function
end module
program main
use m
implicit none
integer::a(2,2)
a=reshape([-1,2,3,-4],[2,2])
print *,reshape(selected(a),[2,1]),size(selected(-a*0))
end program
