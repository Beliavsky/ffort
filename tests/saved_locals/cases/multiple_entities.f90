module m
implicit none
contains
subroutine tick()
integer,save::i=2,j=8
i=i+1
j=j+2
print *,i,j
end subroutine
end module
program p
use m
implicit none
call tick()
call tick()
end program
