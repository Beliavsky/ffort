program p
implicit none

print *,f([.true.,.false.])
contains
pure logical function f(x)
logical,intent(in)::x(:)
f=parity(x)
end function
end program
