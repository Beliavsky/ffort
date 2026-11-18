subroutine host()
implicit none
integer::x
x=1
call child()
contains
subroutine child()
x=x+1
end subroutine
end subroutine
program p
call host()
end program
