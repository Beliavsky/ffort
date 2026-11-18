module optional_calls
implicit none
contains
pure function inner(a,b,c) result(x)
integer, optional, intent(in) :: a,b,c
integer :: x
x=0
if(present(a=a)) x=x+a
if(present(b)) x=x+10*b
if(present(c)) x=x+100*c
end function
pure function outer(a,b,c) result(x)
integer, intent(in), optional :: a,b,c
integer :: x
x=inner(a,b,c)
end function
subroutine sink(a,b,c)
integer, optional, intent(inout) :: a
integer, optional, intent(out) :: b
integer, optional, intent(in) :: c
if(present(a)) a=a+1
if(present(b)) b=17
if(present(c)) then
 if(present(b)) b=c
end if
end subroutine
subroutine forward(a,b,c)
integer, optional, intent(inout) :: a
integer, optional, intent(out) :: b
integer, optional, intent(in) :: c
call sink(a,b,c)
end subroutine
end module
program use_optional_calls
use optional_calls
implicit none
integer :: a,b,c
print *,inner(),inner(c=3),inner(b=2),inner(1,c=3)
print *,outer(),outer(c=4),outer(b=3),outer(2,c=5)
a=4
call forward(a)
print *,a
call forward(b=b)
print *,b
call forward(c=21,b=c)
print *,c
call forward()
end program
