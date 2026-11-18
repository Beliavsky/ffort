program p
implicit none

call inspect()
print *, "PASS"
contains
subroutine inspect(a)
integer,optional,intent(in)::a(:)
integer::b(3)
b=cshift(a,1)
end subroutine
end program
