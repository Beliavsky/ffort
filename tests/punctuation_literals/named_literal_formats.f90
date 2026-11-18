program p
implicit none
character(*),parameter::fmt='(a)'
character(3)::s
s='[x]'
print fmt,s
write(*,'(a)') '('//s//')'
end program
