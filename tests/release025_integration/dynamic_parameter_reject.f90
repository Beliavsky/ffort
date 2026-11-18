program bad_parameter
implicit none
call bad(3)
contains
subroutine bad(n)
integer,intent(in)::n
character(n),parameter::text="abc"
print *,text
end subroutine
end program
