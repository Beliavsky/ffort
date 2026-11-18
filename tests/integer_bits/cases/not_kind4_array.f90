program bits_driver
implicit none
integer(4)::a(2,2,2)
a(1,1,1)=0_4
a(2,1,1)=1_4
a(1,2,1)=-1_4
a(2,2,1)=53_4
a(1,1,2)=-45_4
a(2,1,2)=2147483647_4
a(1,2,2)=(-2147483647_4-1_4)
a(2,2,2)=-2147483647_4
a=not(i=a)
write(*,"(*(i0,1x))")a
end program
