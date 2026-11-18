program p
implicit none
character(:),allocatable::a(:),b(:),c(:)
a=['A','Z']
b=['BB','Y ']
c=min(a,b)
write(*,'(a)')c
write(*,'(*(i0,1x))')len(c),size(c)
end program
