module m
implicit none
contains
subroutine tick()
character(len=0),save::word='abc'
word='x'
print *,len(word)
end subroutine
end module
program p
use m
implicit none
call tick()
call tick()
end program
