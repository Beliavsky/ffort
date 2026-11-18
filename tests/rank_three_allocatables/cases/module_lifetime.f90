module storage
integer,allocatable::a(:,:,:)
contains
subroutine setup()
allocate(a(-1:0,4:4,7:8)); a=3
end subroutine
subroutine change()
a(0,4,8)=11
end subroutine
subroutine clean()
deallocate(a)
end subroutine
end module
program p
use storage
print *,allocated(a)
call setup(); call change()
print *,allocated(a),lbound(a,3),sum(a(:,:,7))+sum(a(:,:,8))
call clean()
print *,allocated(a)
end program
