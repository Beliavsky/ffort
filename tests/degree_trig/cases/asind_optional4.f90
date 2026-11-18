program p
call f()
contains
subroutine f(x)
real(4),optional,intent(in)::x
print *,kind(asind(x))
end subroutine
end program
