program main
implicit none
real(4)::a(-2:2)
call inspect(a)
print *, 'PASS'
contains
subroutine inspect(x)
real(4),optional,intent(out)::x(:)
if(.not.present(x)) error stop 1
if(size(x)/=5) error stop 2
if(kind(x)/=4) error stop 3
end subroutine
end program
