program p
implicit none
integer :: i=42
integer(8)::j=9007199254740993_8
real(4)::a=1.25
real(8)::b=1.23456789012345_8
print *,real(i),real(i,8),real(i,4)
print *,real(j,8)==9007199254740992.0_8
print *,real(a),real(a,8),real(b,8)
print *,kind(real(b)),kind(real(b,8)),kind(real(a,8)),kind(real(i,4))
print *,real(real(b),8)==1.2345678806304931640625_8
print *,real(16777217,4)==16777216.0_4
print *,real(-0.0_8,4),real(-0.0_4,8),real(tiny(0.0_4),8),real(tiny(0.0_8),8)
end program p
