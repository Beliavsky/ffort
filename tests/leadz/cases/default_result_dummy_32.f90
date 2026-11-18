program p
implicit none
call f(leadz(1_4))
call g(leadz([0_4,1_4]))
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
