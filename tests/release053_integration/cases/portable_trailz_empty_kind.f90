program p
use iso_fortran_env,only:int32,int64
implicit none
integer(int64)::x(3),bits(0)
integer(int64),allocatable::y(:)
y=x(trailz(bits)+1)
if(size(y)/=0)error stop "empty"
if(kind(trailz(0_int64))/=kind(0))error stop "default result kind"
if(kind(y)/=int64)error stop "gather kind"
write(*,'(3i3)')size(y),trailz(0_int32),trailz(0_int64)
end program
