module m
implicit none
contains
pure subroutine lookup(iu,name)
integer,intent(in) :: iu
character(*),intent(out) :: name
inquire(unit=iu,name=name)
end subroutine
end module
program p
end program
