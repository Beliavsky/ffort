program p
use iso_fortran_env,only:int32
implicit none
integer(int32)::x(3),bits
integer::i
character(9)::lines(3)
x=[10_int32,20_int32,30_int32]
bits=1_int32
i=1
lines='untouched'
do while(trailz(bits)<3)
write(lines(i),'(i2.2,":",2i3)')i,x(trailz([bits,1_int32])+1)
x=x+10_int32
bits=bits*2_int32
i=i+1
end do
write(*,'(a)')lines
end program
