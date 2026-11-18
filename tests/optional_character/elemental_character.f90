program main
implicit none
character(3)::a(2)
a='abc'
if(any(choose(a)/='abc')) error stop 1
if(any(choose(a,'xyz')/='xyz')) error stop 2
call change(a)
if(any(a/='def')) error stop 3
print *, 'PASS' 
contains
elemental function choose(x,y) result(z)
character(*),intent(in)::x
character(*),optional,intent(in)::y
character(3)::z
z=x
if(present(y)) z=y
end function
elemental subroutine change(x,y)
character(*),intent(inout)::x
character(*),optional,intent(in)::y
x='def'
if(present(y)) x=y
end subroutine
end program
