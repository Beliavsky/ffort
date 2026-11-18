program p
implicit none
character(1)::a(2,1,2)
character(3)::b(2,1,2),x(2,1,2)
a='z'
b='aaa'
x=min(a,b,'bb')
write(*,'(a)')x
write(*,'(*(i0,1x))')len(x),shape(x)
end program
