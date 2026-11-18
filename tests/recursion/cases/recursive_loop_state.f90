program p
integer::answer
answer=0
call walk(4,answer)
print *,answer
contains
recursive subroutine walk(n,answer)
integer,intent(in)::n
integer,intent(inout)::answer
integer::j,saved
saved=n
if(n==0) then
answer=answer+1
else
do j=1,2
call walk(n-1,answer)
if(saved/=n) error stop 1
end do
end if
end subroutine
end program
