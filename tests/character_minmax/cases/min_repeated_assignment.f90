program p
implicit none
character::a(3)
character(2)::x(3)
integer::i
a=['a','b','c']
do i=1,4
x=min(a,'bb')
enddo
write(*,'(a)')x
end program
