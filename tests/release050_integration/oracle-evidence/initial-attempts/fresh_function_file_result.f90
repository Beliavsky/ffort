module m
contains
function labels(n) result(answer)
integer,intent(in)::n
character(4)::answer(2)
write(answer(1),'(z4.4)')maskr(n)
write(answer(2),'(z4.4)')shiftr(maskr(n),1)
end function
end module
program p
use m
implicit none
character(4)::s(2)
s=labels(3)
print '(a)',s
s=labels(1)
print '(a)',s
end program
