program p
implicit none

call f()
print *,77
contains
subroutine f()
do
call g()
end do
end subroutine
subroutine g()
integer::n
n=0
do
n=n+1
if(n==2) exit
end do
end subroutine
end program
