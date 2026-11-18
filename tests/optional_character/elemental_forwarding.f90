program main
implicit none
character(3)::a(2),z(0)
a='abc'
call outer(a)
if(any(a/='def')) error stop 1
call outer(a,'xyz')
if(any(a/='xyz')) error stop 2
call outer(z)
print *, 'PASS' 
contains
elemental subroutine outer(x,y)
character(*),intent(out)::x
character(*),optional,intent(in)::y
call inner(x,y)
end subroutine
elemental subroutine inner(x,y)
character(*),intent(out)::x
character(*),optional,intent(in)::y
x='def'
if(present(y)) x=y
end subroutine
end program
