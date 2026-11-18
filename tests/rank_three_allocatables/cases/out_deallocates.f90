program p
integer,allocatable::a(:,:,:)
allocate(a(1,2,3)); a=4
call drop(a)
print *,allocated(a)
contains
subroutine drop(x)
integer,allocatable,intent(out)::x(:,:,:)
print *,allocated(x)
end subroutine
end program
