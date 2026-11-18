program p
implicit none
real(8)::x(2)
character(24)::fmt
integer::i
x=[1d0,2d0]
fmt='(*(f5.1))'
write(*,'(a)',advance='no')'kept:'
print fmt,(acosd(x(i)),i=1,2)
end program
