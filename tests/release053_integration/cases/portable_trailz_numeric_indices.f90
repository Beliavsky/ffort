program p
use iso_fortran_env,only:int32,int64
implicit none
integer(int32)::a(3),bits4(3),i4(3)
integer(int64)::b(3),bits8(3)
a=[10_int32,20_int32,30_int32]
b=[100_int64,200_int64,300_int64]
bits4=[4_int32,1_int32,2_int32]
bits8=[4_int64,1_int64,2_int64]
i4=trailz(bits4)+1
write(*,'(3i4)')a(i4)
write(*,'(3i4)')b(trailz(bits8)+1)
end program
