program p
implicit none
integer,parameter::a(3)=eoshift([1,2,3],-1,boundary=-9)
write(*,'(*(i0,1x))')a
end program
