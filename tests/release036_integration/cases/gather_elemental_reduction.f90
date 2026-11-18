program main
implicit none
integer(8)::a(3,2),b(3,2)
logical::m(3,2)
a=reshape([-4_8,0_8,3_8,2_8,-1_8,7_8],[3,2])
b=dim(a([3,1,3],:),0_8)
m=b>0_8
write(*,'("rows:",6(1x,i0))')b
write(*,'("reduce:",4(1x,i0))')sum(b),count(m),merge(1,0,parity(m)),count(parity(m,dim=2))
write(*,'("kinds:",4(1x,i0))')kind(b),kind(dim(b,0_8)),radix(b),kind(huge(b))
end program
