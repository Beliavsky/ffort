program main
implicit none
character(5)::x
call outer()
call outer(last='abc')
x='hello'
call outer(x,'xyz')
call undefined(x)
print *, 'PASS' 
contains
subroutine outer(first,last)
character(5),optional,intent(in)::first
character(*),optional,intent(in)::last
call inner(first,last)
end subroutine
subroutine inner(first,last)
character(5),optional,intent(in)::first
character(*),optional,intent(in)::last
if(present(first)) then
if(first/='hello'.or.len(first)/=5) error stop 1
end if
if(present(last)) then
if(len(last)/=3) error stop 2
end if
if(kind(first)/=1) error stop 3
end subroutine
subroutine undefined(x)
character(*),intent(out)::x
call query(x)
end subroutine
subroutine query(x)
character(*),optional,intent(in)::x
if(.not.present(x).or.len(x)/=5) error stop 4
end subroutine
end program
