module composition
implicit none
contains
subroutine host(n)
integer,intent(inout)::n
call child()
contains
subroutine child()
integer::work(n),entry
character(n)::char
entry=n
work=7
char=' x '
n=1
write(*,'("entry:",3(1x,i0)," [",a,"]")')entry,size(work),len(char),char
end subroutine
end subroutine
end module
program main
use composition
implicit none
integer::n
n=3
call host(n)
write(*,'("host:",1x,i0)')n
n=0
call host(n)
end program
