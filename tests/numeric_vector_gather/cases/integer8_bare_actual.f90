program p
implicit none
integer(8)::a(4)
a=[1,2,3,4]
call inspect(a([4,1,4]))

print '(i0)',1
contains
subroutine inspect(x)
integer(8),intent(in)::x(:)
if(size(x)/=3.or.any(x/=[4,1,4]))error stop 1
end subroutine
end program
