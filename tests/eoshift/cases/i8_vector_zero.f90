program p
implicit none
integer(8)::a(3)
a=[9007199254740990_8,9007199254740991_8,9007199254740992_8]
write(*,'(*(i0,1x))')eoshift(a,0)
end program
