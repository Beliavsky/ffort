program main

implicit none
integer :: a(5),lo,hi,s
a=0
lo=1
hi=5
s=2
call change(a(lo:hi:s),lo,hi,s)
print *,a,lo,hi,s
contains
subroutine change(x,lo,hi,s)
integer, intent(out) :: x(:),lo,hi,s
lo=2
hi=4
s=1
x=9
end subroutine change
end program main
