program p
implicit none
call test()
contains
subroutine test(x)
real(8),optional,intent(in)::x
print *,digits(x)
end subroutine
end program
