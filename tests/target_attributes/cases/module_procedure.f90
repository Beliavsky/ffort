module m
integer,target,public::a(1,1,2)
contains
subroutine setup()
integer,target::local
local=7;a=local
end subroutine
end module
program p
use m
call setup()
print *,a
end program
