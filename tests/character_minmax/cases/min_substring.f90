program p
implicit none
character(4)::a
a='bcde'
write(*,'(a)')min(a(2:3),'z'),min('abc'(1:2),'aaa')
end program
