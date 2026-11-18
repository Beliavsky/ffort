program main
implicit none
character(:),allocatable::a(:),b(:)
a=['ab','cd']
print *,1
b=pack(a,[.true.,.false.])

end program
