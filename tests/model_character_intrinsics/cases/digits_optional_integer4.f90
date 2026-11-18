program p
implicit none
call test()
contains
subroutine test(x)
integer(4),optional,intent(in)::x
print *,digits(x)
end subroutine
end program
