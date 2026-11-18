! Synthetic release 0.29 composition fixture; not an extracted utility body.
program composition
implicit none
integer,allocatable::a(:,:,:)
allocate(a(2,2,2))
a=1
call update(a)
contains
subroutine update(x)
integer,allocatable,intent(in &
 & out),intent(in)::x(:,:,:)
print *,shape(x)
end subroutine
end program
