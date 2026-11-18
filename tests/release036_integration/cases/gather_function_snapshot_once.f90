module selection
implicit none
integer::calls=0
contains
impure elemental function pick(i) result(idx)
integer,intent(in)::i
integer::idx
calls=calls+1
idx=i
end function
end module
program main
use selection
implicit none
integer::a(3,2),b(2,2)
a=reshape([1,2,3,4,5,6],[3,2])
b=dim(a(pick([3,1]),:),0)
write(*,'("first:",5(1x,i0))')calls,b
b=sign(a(pick([2,2]),:),-1)
write(*,'("second:",5(1x,i0))')calls,b
write(*,'("reduced:",2(1x,i0))')merge(1,0,parity(b<0)),radix(b)
end program
