module m
contains
function search(s,b) result(n)
character(*),intent(in)::s
logical,optional,intent(in)::b
integer::n
n=scan(s,'a',b)
end function
function forwarding(s,b) result(n)
character(*),intent(in)::s
logical,optional,intent(in)::b
integer::n
n=search(s,b)
end function
end module
program p
use m
implicit none
print *, forwarding('aba'), forwarding('aba',.true.), forwarding('aba',.false.)
end program
