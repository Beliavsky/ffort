program p
implicit none
real(8)::a(3,2)
integer(8)::s
real(8)::b
a=reshape([0.25_8,0.5_8,0.75_8,1.0_8,1.25_8,1.5_8],[3,2])
s=1_8
b=-2.25_8
write(*,'(*(f10.2,1x))')eoshift(boundary=b,dim=1_8,shift=s,array=a)
end program
