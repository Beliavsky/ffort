program main
implicit none
character(5)::a(2,2)
call query(a)
print *, 'PASS' 
contains
subroutine query(x)
character(*),optional,intent(out)::x(:,:)
if(.not.present(x)) error stop 1
if(len(x)/=5) error stop 2
end subroutine
end program
