module m
implicit none
contains
subroutine host(n,values)
integer,intent(in)::n
integer,intent(inout)::values(:)
call child(values)
contains
subroutine child(a)
integer,intent(inout)::a(n)
character(len=n)::label
label=repeat('x',n)
a=a+len(label)
print *,len(label),label
end subroutine
end subroutine
end module
program p
use m
implicit none
integer::a3(3),a1(1),a0(0)
a3=[1,2,3]
a1=[9]
call host(3,a3)
print *,a3
call host(1,a1)
print *,a1
call host(0,a0)
end program
