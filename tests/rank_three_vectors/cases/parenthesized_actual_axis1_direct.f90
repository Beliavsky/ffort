program p
implicit none
integer::a(3,3,3),idx(2)
a=1
idx=[3,1]
call inspect((a(idx,:,:)))
print '(i0)',1
contains
subroutine inspect(x)
integer,intent(in)::x(:,:,:)
integer::i,j,k
if(size(x)/=18)error stop 1
do k=1,size(x,3)
do j=1,size(x,2)
do i=1,size(x,1)
if(x(i,j,k)/=1)error stop 2
end do
end do
end do
end subroutine
end program
