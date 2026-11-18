program p
implicit none
real(8)::x(4),a(4)
integer::before
x=-3.0_8
a=-99
before=17
a=rrspacing(x)
if(before/=17.or.any(a/=3.0_8*2.0_8**51))error stop 1
print *,a
end program
