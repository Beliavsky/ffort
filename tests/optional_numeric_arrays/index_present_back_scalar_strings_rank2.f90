program main
implicit none
logical::b(2,2)
b=.true.
call f(b)
print *, 'PASS'
contains
subroutine f(b)
logical,optional,intent(in)::b(:,:)
if(any(index('ababa','ba',b)/=4)) error stop 1
end subroutine
end program
