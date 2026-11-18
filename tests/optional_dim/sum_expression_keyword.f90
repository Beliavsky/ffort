program p
implicit none
call f(1)
contains
subroutine f(d)
integer,optional,intent(in)::d
print *,sum([1,2],dim=d+0)
end subroutine
end program
