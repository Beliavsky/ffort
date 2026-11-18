module transform
implicit none
contains
function convert(x,direction) result(y)
real(8),intent(in)::x(:,:)
real(8),optional,intent(in)::direction
real(8)::y(size(x,1),size(x,2))
y=set_exponent(fraction(x),exponent(x))
if(present(direction))y=nearest(y,direction)
end function
end module
program main
use transform
implicit none
real(8),allocatable::a(:,:)
a=reshape([1d0,2d0,4d0,8d0],[2,2])
a=convert((a([2,1],:)))
write(*,'("optional:",7(1x,i0))')shape(a),int(a),kind(a)
a=convert(a,direction=-1d0)
write(*,'("next:",2(1x,i0))')count(a<reshape([2d0,1d0,8d0,4d0],[2,2])),count(spacing(a)>0d0)
end program
