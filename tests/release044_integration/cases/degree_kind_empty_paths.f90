program p
implicit none
real(8)::empty(0),unknown,outside
character(24)::fmt
integer::i
fmt='(*(i0,1x))'
outside=2d0
print fmt,(kind(acosd(outside)),kind(asind(unknown)),size(sind(empty)),i=1,2)
end program
