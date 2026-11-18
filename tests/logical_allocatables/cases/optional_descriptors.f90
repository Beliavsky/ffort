program p
logical,allocatable::a(:,:,:)
call inspect()
call inspect(a)
allocate(a(1,1,2));a=.true.
call inspect(a)
contains
subroutine inspect(x)
logical,allocatable,optional,intent(in)::x(:,:,:)
print *,present(x)
if(present(x)) then
print *,allocated(x)
if(allocated(x)) print *,x
end if
end subroutine
end program
