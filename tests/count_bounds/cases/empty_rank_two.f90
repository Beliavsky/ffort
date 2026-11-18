module m
implicit none
contains
subroutine work(x)
logical,intent(in)::x(:,:)

integer::a(count(x),2)

print *,size(a),size(a,1),size(a,2)
end subroutine
end module
program p
use m
implicit none
logical::v(0,4)
call work(v)
end program
