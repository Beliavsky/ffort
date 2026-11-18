! Synthetic release 0.30 composition fixture; not an extracted utility body.
program composition
implicit none
character(:),allocatable :: words(:,:,:)
logical,allocatable :: selected(:,:,:)
allocate(character(6)::words(0,2,1))
allocate(selected(0,2,1))
call inspect(words,selected)
contains
subroutine inspect(x,m)
character(*),intent(in) :: x(:,:,:)
logical,allocatable,intent(in) :: m(:,:,:)
character(len=len(x(1,1,1))) y(0)
print *,shape(x),shape(m),len(y),size(y)
print *,shape(x(:,:,1)),findloc(x(:,:,1),'x',mask=m(:,:,1))
print *,findloc(x(:,:,1),'x',dim=1,mask=m(:,:,1),back=.true.)
end subroutine
end program
