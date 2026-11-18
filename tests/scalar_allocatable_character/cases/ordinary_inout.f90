program p
implicit none
character(:),allocatable::s
s='abcd'
call change(s)
if(s/='q   '.or.len(s)/=4) error stop 1
contains
subroutine change(x)
character(*),intent(inout)::x
x='q'
end subroutine
end program
