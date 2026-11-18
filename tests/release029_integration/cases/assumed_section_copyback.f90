! Synthetic release 0.29 composition fixture; not an extracted utility body.
program composition
implicit none
real(8),allocatable::a(:,:,:)
integer::i,j,k
allocate(a(-1:2,3:4,7:9))
do k=7,9
 do j=3,4
  do i=-1,2
   a(i,j,k)=100*k+10*j+i
  end do
 end do
end do
call update(a(2:-1:-2,4:3:-1,9:7:-1))
print *,a(2,4,9),a(0,3,9),a(2,4,7),a(0,3,7),a(1,3,8)
contains
subroutine update(x)
real(8),optional,intent(in &
 & out)::x(:,:,:)
if(present(x)) then
 print *,shape(kind=8,source=x),kind(shape(x,kind=8))
 print *,shape(x(1,:,3:1:-2))
 where(x(:,:,1)>0) x(:,:,1)=-x(:,:,1)
 x(:,:,3)=x(:,:,3)+1000
end if
end subroutine
end program
