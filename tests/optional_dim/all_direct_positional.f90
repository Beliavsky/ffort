program p
implicit none
call f(1)
contains
subroutine f(d)
integer,optional,intent(in)::d
print *,all([.true.,.false.],d)
end subroutine
end program
