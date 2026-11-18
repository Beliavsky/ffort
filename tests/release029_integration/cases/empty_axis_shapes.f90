! Synthetic release 0.29 composition fixture; not an extracted utility body.
program composition
implicit none
integer,allocatable::a(:,:,:),b(:,:,:)
allocate(a(-2:-3,4:5,7:9))
a=1
call inspect(a)
b=a
print *,shape(b),size(b)
deallocate(a)
allocate(a(-2:-1,4:3,7:9))
a=2
call inspect(a)
b=a
print *,shape(b),size(b)
deallocate(a)
allocate(a(-2:-1,4:6,7:6))
a=3
call inspect(a)
b=a
print *,shape(b),size(b)
call inspect()
contains
subroutine inspect(x)
integer,optional,intent(in out)::x(:,:,:)
if(present(x)) then
 print *,shape(x),size(x)
else
 print *,present(x)
end if
end subroutine
end program
