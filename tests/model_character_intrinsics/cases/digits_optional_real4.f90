program p
implicit none
call test()
contains
subroutine test(x)
real(4),optional,intent(in)::x
print *,digits(x)
end subroutine
end program
