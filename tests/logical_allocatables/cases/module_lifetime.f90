module m
logical,allocatable::a(:,:,:)
contains
subroutine start()
allocate(a(-1:0,4:4,7:8));a=.true.
end subroutine
subroutine change()
a(0,4,8)=.false.
end subroutine
subroutine finish()
deallocate(a)
end subroutine
end module
program p
use m
print *,allocated(a)
call start();call change()
print *,lbound(a,3),a
call finish();print *,allocated(a)
end program
