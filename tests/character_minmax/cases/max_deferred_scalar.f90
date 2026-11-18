program p
implicit none
character(:),allocatable::a,b,c
a='x'
b='bbb'
c=max(a,b)
write(*,'(a)')c
write(*,'(*(i0,1x))')len(c)
a='longer'
c=max(a,b)
write(*,'(a)')c
write(*,'(*(i0,1x))')len(c)
end program
