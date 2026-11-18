module m
implicit none
contains
subroutine q()
integer,save::a(2)=[1,2]
print *,a
end subroutine
end module
program p
use m
call q()
end program
