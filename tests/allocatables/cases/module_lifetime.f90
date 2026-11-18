module state
integer,allocatable::a(:,:)
contains
subroutine setit()
allocate(a(-2:-1,4:6))
a=8
end subroutine
subroutine change()
a(-1,5)=2
end subroutine
pure function viewit() result(n)
integer::n
n=lbound(a,1)+ubound(a,2)+sum(a)
end function
subroutine clearit()
deallocate(a)
end subroutine
end module
program main
use state
print *,allocated(a)
call setit()
call change()
print *,allocated(a),lbound(a,1),ubound(a,2),viewit()
call clearit()
print *,allocated(a)
end program
