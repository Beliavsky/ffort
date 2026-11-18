program p
implicit none

call inspect()
print *, "PASS"
contains
subroutine inspect(d)
integer,optional,intent(in)::d
integer::a(2,3),b(2,3)
a=1
b=cshift(a,1,(d))
end subroutine
end program
