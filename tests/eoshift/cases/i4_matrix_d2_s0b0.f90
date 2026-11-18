program p
implicit none
integer::a(3,2)
integer(8)::s
integer::b
a=reshape([1,2,3,4,5,6],[3,2])
s=1_8
b=-9
write(*,'(*(i0,1x))')eoshift(boundary=b,dim=2_8,shift=s,array=a)
end program
