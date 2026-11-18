program main

implicit none

print *,777
call f(2)
contains
subroutine f(s)
character(len=*),intent(in)::s
print *,s
end subroutine f
end program main
