module m
implicit none
integer::calls=0
contains
impure elemental integer function pick(i) result(v)
integer,intent(in)::i
calls=calls+1
v=i
end function
end module
program p
use m
implicit none
integer::a(3,3,3),idx(2),i,j,k
integer,allocatable::b(:,:,:)
a=1
idx=[3,1]
b=a(pick(idx),:,:)
if(calls/=2.or.size(b)/=18)error stop 1
do k=1,3
do j=1,3
do i=1,2
if(b(i,j,k)/=1)error stop 2
end do
end do
end do
print '(i0)',1
end program
