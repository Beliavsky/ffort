program p
integer,allocatable::a(:,:,:)
call inspect()
call inspect(a)
allocate(a(1,2,3)); a=4
call inspect(a)
contains
subroutine inspect(x)
integer,allocatable,optional,intent(in)::x(:,:,:)
print *,present(x)
if(present(x)) then
print *,allocated(x)
if(allocated(x)) print *,size(x),sum(x(:,:,1))+sum(x(:,:,2))+sum(x(:,:,3))
end if
end subroutine
end program
