! Synthetic release 0.31 composition fixture; not an extracted utility body.
program composition
implicit none
character(:),allocatable,target :: words(:,:,:)
logical,allocatable,target :: keep(:,:)
allocate(character(5)::words(2,1,1))
allocate(keep(2,1));keep=.true.
words='ab'
call inspect(words,keep)
deallocate(words)
deallocate(keep)
allocate(character(7)::words(0,2,1))
allocate(keep(0,2))
call inspect(words,keep)
contains
subroutine inspect(x,m)
character(*),intent(in),target :: x(:,:,:)
logical,allocatable,target,intent(in) :: m(:,:)
character(len=len(x(1,1,1))),target :: plane(size(x,1),size(x,2))
plane=x(:,:,1)
print *,shape(x),len(x),shape(plane),len(plane)
print *,findloc(plane,'ab',mask=m),findloc(plane,'ab',mask=m,back=.true.)
end subroutine
end program
