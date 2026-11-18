program p
implicit none
integer(8)::s
integer::a(3)
s=huge(0_8);a=[1,2,3]
write(*,'(3(i0,1x))')eoshift(a,s,boundary=-9)
end program
