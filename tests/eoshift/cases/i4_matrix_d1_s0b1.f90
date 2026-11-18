program p
implicit none
integer::a(3,2)
integer(8)::s
integer::b(2)
a=reshape([1,2,3,4,5,6],[3,2])
s=1_8
b=[-9,-9]
write(*,'(*(i0,1x))')eoshift(boundary=b,dim=1_8,shift=s,array=a)
end program
