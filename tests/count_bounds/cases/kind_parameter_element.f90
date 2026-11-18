module m
implicit none
contains
subroutine work(x)
logical,intent(in)::x(:)

integer,parameter::kinds(2)=[4,8]
integer::a(count(kind=kinds(2),dim=1,mask=x))

a=7
print *,size(a),sum(a)
end subroutine
end module
program p
use m
implicit none
call work([.true.,.false.,.true.])
end program
