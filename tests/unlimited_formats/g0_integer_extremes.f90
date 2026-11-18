program p
implicit none
integer::a
integer(8)::b
a=-2147483647-1
b=-9223372036854775807_8-1_8
write(*,'(g0,1x,g0,1x,g0,1x,g0)')a,b,2147483647,9223372036854775807_8
end program
