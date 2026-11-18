module empty_text
implicit none
character(*),parameter::vacant(0)=[character(3)::]
contains
function extend(words,n) result(answer)
character(*),intent(in)::words(:)
integer,intent(in)::n
character(len(words)+n)::answer(size(words))
answer=words//achar(33)
end function
subroutine relay(words,n)
character(*),intent(in)::words(:)
integer,intent(in)::n
call inspect(extend(words,n))
end subroutine
subroutine inspect(words)
character(*),intent(in)::words(:)
print '(I1,I1)',size(words),len(words)
end subroutine
end module
program empty_composition
use empty_text
implicit none
call relay(vacant,int(cos(0.0)))
end program
