program p
logical,allocatable::a(:,:,:)
call fill(a)
print *,a(2,1,2)
contains
subroutine fill(x)
logical,allocatable,intent(out)::x(:,:,:)
allocate(x(2,1,2));x(1,1,1)=.true.
end subroutine
end program
