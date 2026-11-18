program test
implicit none
integer::n
n=0
call q(n,n)
contains
subroutine q(c,r)
integer,intent(out)::c,r
call system_clock(c,r)
end subroutine
end program
