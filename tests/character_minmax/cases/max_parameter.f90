program p
implicit none
character(*),parameter::s=max('z','bb')
write(*,'(a)')s
write(*,'(*(i0,1x))')len(s),kind(s)
end program
