program main
implicit none
call f()
contains
subroutine f(b)
logical,optional,intent(in)::b(:,:)
print *, index('ababa','ba',b)
end subroutine
end program
