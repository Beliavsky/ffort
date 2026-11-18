program p
implicit none
real(4)::x(3),a(3)
integer::before
x=-3.0_4
a=-99
before=17
a=rrspacing(x)
if(before/=17.or.any(a/=3.0_4*2.0_4**22))error stop 1
print *,a
end program
