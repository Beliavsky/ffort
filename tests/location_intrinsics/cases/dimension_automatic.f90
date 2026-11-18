module m
implicit none
contains
function positions(a) result(pos)
integer,dimension(:,:),intent(in)::a
integer,dimension(size(a,2))::pos
pos=minloc(a,1)
end function
end module
program test
use m
implicit none
print *,positions(reshape([4,1,2,3],[2,2]))
end program
