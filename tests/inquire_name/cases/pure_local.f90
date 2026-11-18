module m
contains
pure subroutine q(iu)
integer,intent(in)::iu
character(24)::nm
inquire(unit=iu,name=nm)
end subroutine
end module
program p
end program
