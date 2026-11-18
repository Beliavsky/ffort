program p
call f()
contains
subroutine f(x)
real(4),optional,intent(in)::x
print *,kind(acosd(x))
end subroutine
end program
