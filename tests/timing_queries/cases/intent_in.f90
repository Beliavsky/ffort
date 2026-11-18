program test
implicit none
integer::n
n=0
call q(n)
contains
subroutine q(n)
integer,intent(in)::n
call system_clock(n)
end subroutine
end program
