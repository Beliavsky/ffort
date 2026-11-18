program p
implicit none
character(4)::a
a='bcde'
write(*,'(a)')max(a(2:3),'z'),max('abc'(1:2),'aaa')
end program
