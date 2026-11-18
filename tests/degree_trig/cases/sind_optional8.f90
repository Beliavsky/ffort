program p
call f()
contains
subroutine f(x)
real(8),optional,intent(in)::x
print *,kind(sind(x))
end subroutine
end program
