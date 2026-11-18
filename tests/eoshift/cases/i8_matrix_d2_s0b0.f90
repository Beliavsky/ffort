program p
implicit none
integer(8)::a(3,2)
integer(8)::s
integer(8)::b
a=reshape([9007199254740990_8,9007199254740991_8,9007199254740992_8,9007199254740993_8,9007199254740994_8,9007199254740995_8],[3,2])
s=1_8
b=-9007199254740999_8
write(*,'(*(i0,1x))')eoshift(boundary=b,dim=2_8,shift=s,array=a)
end program
