program main
implicit none
real(8)::a(-2:2,4:5)
call inspect(a)
print *, 'PASS'
contains
subroutine inspect(x)
real(8),optional,intent(out)::x(:,:)
if(.not.present(x)) error stop 1
if(size(x)/=10) error stop 2
if(kind(x)/=8) error stop 3
end subroutine
end program
