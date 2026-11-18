program p
implicit none

write(*,'(a)')'['//max('','')//']'
write(*,'(*(i0,1x))')len(max('',''))
end program
