program p
implicit none
character(:),allocatable::s,c(:)
character(8)::fmt
s='SAFE'
c=[s]
write(*,'(a)',advance='no')c
fmt='(z0)'
print fmt,1.0
end program
