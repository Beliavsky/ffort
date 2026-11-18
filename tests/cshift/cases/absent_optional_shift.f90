program p
implicit none

call inspect()
print *, "PASS"
contains
subroutine inspect(s)
integer,optional,intent(in)::s
integer::b(3)
b=cshift([1,2,3],s)
end subroutine
end program
