program p
implicit none
call f()
contains
subroutine f(d)
integer,optional,intent(in)::d
print *,kind(count([.true.],dim=d))
end subroutine
end program
