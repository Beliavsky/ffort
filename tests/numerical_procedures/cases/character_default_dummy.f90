program main

implicit none

print *,777
call f('abc')
contains
subroutine f(x)
character,intent(in)::x
print *,x
end subroutine f
end program main
