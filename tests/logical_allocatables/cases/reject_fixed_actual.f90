program p
logical::a(1,1,1)
call inspect(a)
contains
subroutine inspect(x)
logical,allocatable,intent(inout)::x(:,:,:)
x=.true.
end subroutine
end program
