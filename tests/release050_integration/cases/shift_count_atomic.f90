program p

implicit none
integer::n
character(8)::s(1,1,1)
n=-1
write(*,'(a)')'SAFE'
write(s(1,1,1),'(i0)')shiftr(maskr(8),n)
end program
