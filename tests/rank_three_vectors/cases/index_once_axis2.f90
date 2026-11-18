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
integer::a(3,3,3),idx(2)
integer,allocatable::b(:,:,:)
a=1
idx=[3,1]
b=a(:,pick(idx),:)
if(calls/=2.or.sum(b)/=18)error stop 1
print '(i0)',1
end program
