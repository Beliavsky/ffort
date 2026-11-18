program p
implicit none
real::a(3,2)
integer(8)::s
real::b(3)
a=reshape([0.25,0.5,0.75,1.0,1.25,1.5],[3,2])
s=1_8
b=[-2.25,-2.25,-2.25]
write(*,'(*(f10.2,1x))')eoshift(boundary=b,dim=2_8,shift=s,array=a)
end program
