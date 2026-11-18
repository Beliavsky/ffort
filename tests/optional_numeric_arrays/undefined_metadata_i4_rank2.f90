program main
implicit none
integer(4)::a(-2:2,4:5)
call inspect(a)
print *, 'PASS'
contains
subroutine inspect(x)
integer(4),optional,intent(out)::x(:,:)
if(.not.present(x)) error stop 1
if(size(x)/=10) error stop 2
if(kind(x)/=4) error stop 3
end subroutine
end program
