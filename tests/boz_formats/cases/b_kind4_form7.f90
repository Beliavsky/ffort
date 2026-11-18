program p
implicit none
integer(4)::a(9)
integer::i
a(1)=-huge(0_4)
a(1)=a(1)-1_4
a(2)=-2147483647_4
a(3)=-2_4
a(4)=-1_4
a(5)=0_4
a(6)=1_4
a(7)=15_4
a(8)=16_4
a(9)=2147483647_4
do i=1,9
print '(a,B1.0,a)',"[",a(i),"]"
end do
end program
