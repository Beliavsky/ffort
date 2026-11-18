program p
implicit none
character(:),allocatable::fmt
fmt='(i0)'
print fmt,99
deallocate(fmt)
fmt='(i3.3)'
write(*,fmt)8
end program
