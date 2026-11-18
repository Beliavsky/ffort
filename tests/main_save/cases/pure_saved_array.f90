module m
implicit none
contains
pure subroutine q()
integer,save::a(2)=[1,2]
end subroutine
end module
program p
use m
call q()
end program
