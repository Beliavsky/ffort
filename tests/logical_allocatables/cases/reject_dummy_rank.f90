program p
logical,allocatable::a(:,:)
call inspect(a)
contains
subroutine inspect(x)
logical,allocatable,intent(in)::x(:,:,:)
print *,allocated(x)
end subroutine
end program
