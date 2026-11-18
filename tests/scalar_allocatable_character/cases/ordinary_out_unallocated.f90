program p
implicit none
character(3),allocatable::s
call fill(s)
contains
subroutine fill(x)
character(*),intent(out)::x
x='abc'
end subroutine
end program
