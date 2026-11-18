program p
implicit none
call f(1)
contains
subroutine f(d)
integer,optional,intent(in)::d
print *,lbound([1,2],dim=d)
end subroutine
end program
