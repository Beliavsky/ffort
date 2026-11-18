module m
implicit none
contains
subroutine host(answer)
integer,intent(out)::answer
integer,parameter::k=kind(0d0),n=3
real(kind=k)::x(n)
x=[1.0_k,2.0_k,3.0_k]
call child()
answer=int(sum(x))
contains
subroutine child()
real(kind=k)::b(n)
b=2.0_k
x=x+b
end subroutine
end subroutine
end module
program p
use m
implicit none
integer::answer
call host(answer)
print *,answer
end program
