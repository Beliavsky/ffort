program main
implicit none
real(8),pointer::p(:)
p=>null()
if(kind(norm2(p))/=8) error stop 1
end program
