program p
integer::answer
answer=0
call left(5,answer)
print *,answer
contains
recursive subroutine left(n,answer)
integer,intent(in)::n
integer,intent(inout)::answer
answer=answer+1
if(n>0) call right(n-1,answer)
end subroutine
recursive subroutine right(n,answer)
integer,intent(in)::n
integer,intent(inout)::answer
answer=answer+10
if(n>0) call left(n-1,answer)
end subroutine
end program
