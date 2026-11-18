module m
implicit none
contains
subroutine work(x,n)
logical,intent(in)::x(:)
integer,intent(in)::n
integer::a(count(x,dim=n))
a=1
print *,size(a)
end subroutine
end module
program p
use m
implicit none
call work([.true.,.false.],1)
end program
