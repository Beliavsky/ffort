program p
implicit none
real(4),allocatable::a(:)
a=[1.,2.,3.,4.]
call replace((a([4,1,4])),a)
if(size(a)/=3.or.any(a/=[4,1,4]))error stop 1
print '(i0)',1
contains
subroutine replace(x,y)
real(4),intent(in)::x(:)
real(4),allocatable,intent(out)::y(:)
allocate(y(size(x)))
y=x
end subroutine
end program
