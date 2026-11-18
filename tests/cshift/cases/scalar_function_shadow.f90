program p
implicit none
real(8)::x
x=cshift(3)
if(x/=3.5d0) error stop 1
print *, "PASS"
contains
real(8) function cshift(n)
integer,intent(in)::n
cshift=n+0.5d0
end function
end program
