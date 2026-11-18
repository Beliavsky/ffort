module m
implicit none
integer,allocatable::a(:),b(:)
contains
subroutine start()
allocate(a(2),b(3))
a=2
b=3
end subroutine
subroutine finish()
deallocate(a,b)
end subroutine
end module
program p
use m
implicit none
call start()
print *,sum(a),sum(b)
call finish()
print *,allocated(a),allocated(b)
end program
