program p
implicit none
logical::a(3,2)
integer(8)::s(3)
logical::b(3)
a=reshape([.true.,.false.,.true.,.false.,.false.,.true.],[3,2])
s=[-1_8,0_8,2_8]
b=[.false.,.true.,.false.]
write(*,'(*(l1,1x))')eoshift(boundary=b,dim=2_8,shift=s,array=a)
end program
