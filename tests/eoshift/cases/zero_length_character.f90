program p
implicit none
character(0)::a(3),b
a="";b=""
write(*,'(2(i0,1x))')len(eoshift(a,1,b)),size(eoshift(a,-1,b))
end program
