program p
implicit none
character(1)::a(2,3)
character(2)::b(2,3),x(2,3)
a=reshape(['a','b','c','d','e','f'],[2,3])
b='cc'
x=min(a,b)
write(*,'(a)')x
write(*,'(*(i0,1x))')len(x),shape(x)
end program
