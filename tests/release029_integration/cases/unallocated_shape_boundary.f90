! Synthetic release 0.29 composition fixture; not an extracted utility body.
program composition
implicit none
integer,allocatable::a(:,:,:)
call inspect(a)
contains
subroutine inspect(x)
integer,allocatable,intent(in &
 & out)::x(:,:,:)
print *,shape(x)
end subroutine
end program
