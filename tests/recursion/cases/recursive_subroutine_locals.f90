program p
implicit none
integer::x
x=0
call walk(5,x)
print *,x
contains
recursive subroutine walk(n,total)
integer,intent(in)::n
integer,intent(inout)::total
integer::saved,i
saved=n
if(n>0) call walk(n-1,total)
do i=1,2
total=total+saved
end do
end subroutine
end program
