program p
integer::x
x=2
call change(procedure=x)
if(x/=3) error stop 1
print *, 'mutable dummy'
contains
subroutine change(procedure)
integer,intent(inout)::procedure
procedure=procedure+1
end subroutine
end program
