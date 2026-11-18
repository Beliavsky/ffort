module m
contains
integer function q(iu)
integer,intent(in)::iu
character(24)::nm
inquire(unit=iu,name=nm)
q=len_trim(nm)
end function
end module
program p
end program
