program p
integer,allocatable::a(:,:,:)
call bad(a)
contains
subroutine bad(x)
integer,allocatable,intent(in)::x(:,:,:)
allocate(x(1,1,1))
end subroutine
end program
