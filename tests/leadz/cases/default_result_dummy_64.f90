program p
implicit none
call f(leadz(1_8))
call g(leadz([0_8,1_8]))
contains
subroutine f(x)
integer,intent(in)::x
print *,x
end subroutine
subroutine g(x)
integer,intent(in)::x(:)
print *,x
end subroutine
end program
