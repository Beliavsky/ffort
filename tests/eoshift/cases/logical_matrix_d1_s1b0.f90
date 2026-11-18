program p
implicit none
logical::a(3,2)
integer(8)::s(2)
logical::b
a=reshape([.true.,.false.,.true.,.false.,.false.,.true.],[3,2])
s=[1_8,-2_8]
b=.true.
write(*,'(*(l1,1x))')eoshift(boundary=b,dim=1_8,shift=s,array=a)
end program
