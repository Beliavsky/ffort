program p
implicit none
integer::a(2)
a=7
write(*,'(*(2(i0:,",")))')a
end program
