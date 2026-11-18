module m
implicit none
contains
subroutine host(answer)
character(len=5),intent(out)::answer
character(len=5)::text
text='abcde'
call child()
answer=text
contains
subroutine child()
text(2:4)='XYZ'
end subroutine
end subroutine
end module
program p
use m
implicit none
character(len=5)::answer
call host(answer)
print *,answer
end program
