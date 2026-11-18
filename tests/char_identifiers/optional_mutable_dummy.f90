module m
implicit none
contains
subroutine change(char)
integer,intent(inout),optional::char
if(present(char)) char=char+1
end subroutine
end module
program p
use m
implicit none
integer::i
i=4
call change()
call change(char=i)
if(i/=5) error stop 1
print *,i
end program
