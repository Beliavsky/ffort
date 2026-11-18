program p
implicit none
integer::a(3),b(3)
a=[1,2,3];b=0
where(a>1)b=eoshift(a,1,-9)
write(*,'(*(i0,1x))')b
end program
