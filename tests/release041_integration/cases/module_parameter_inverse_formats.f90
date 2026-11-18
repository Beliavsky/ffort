module settings
implicit none
character(len=*),parameter :: fmt='(3(f10.6,1x))'
end module
program p
use settings,only:fmt
implicit none
real(kind=8)::a(3)
a=asin([-1.0_8,0.0_8,1.0_8])
print fmt,a
write(*,fmt) atan([-1.0_8,0.0_8,1.0_8])
end program
