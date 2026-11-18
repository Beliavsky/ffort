program p
logical,allocatable::a(:,:,:)
call inspect(a)
contains
subroutine inspect(x)
logical,allocatable,intent(in)::x(:,:,:)
allocate(x(1,1,1))
end subroutine
end program
