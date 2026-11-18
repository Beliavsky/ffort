module m
implicit none
contains
subroutine host(answer)
integer,intent(out)::answer
answer=0
call child()
answer=answer+1
contains
subroutine child()
answer=41
return
answer=99
end subroutine
end subroutine
end module
program p
use m
implicit none
integer::answer
call host(answer)
print *,answer
end program
