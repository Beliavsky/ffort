program p
implicit none
integer(8)::a(9)
integer::i
a(1)=-huge(0_8)
a(1)=a(1)-1_8
a(2)=-9223372036854775807_8
a(3)=-2_8
a(4)=-1_8
a(5)=0_8
a(6)=1_8
a(7)=15_8
a(8)=16_8
a(9)=9223372036854775807_8
do i=1,9
print '(a,Z16.16,a)',"[",a(i),"]"
end do
end program
