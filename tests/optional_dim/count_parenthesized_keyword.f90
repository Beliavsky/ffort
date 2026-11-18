program p
implicit none
call f(1)
contains
subroutine f(d)
integer,optional,intent(in)::d
print *,count([.true.,.false.],dim=(d))
end subroutine
end program
