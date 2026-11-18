program p
implicit none
character(:),allocatable::s,a(:)
s='ABCDEFGH'
a=[s]
write(*,'(a,t3,z2.2)',advance='no')a(1),ior(8,7)
write(*,'(tr1,b2.2)')iand(3,1)
end program
