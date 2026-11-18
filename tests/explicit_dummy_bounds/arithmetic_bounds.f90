program main
implicit none
integer::a(8)
a=4
call work(a,3)
contains
subroutine work(x,n)
integer,intent(in)::n
integer,parameter::p=2
integer,intent(in)::x(-abs(n):min(5,n)+max(0,modulo(-n,p))+mod(n,p)+n/p-n**2+7+n*p-6)
print *,size(x),lbound(x,1),ubound(x,1),sum(x)
end subroutine
end program
