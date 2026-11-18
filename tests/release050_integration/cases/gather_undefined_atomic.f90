program p

implicit none
integer::a(2,1,1)
character(8)::s(1)
a(1,1,1)=8
write(*,'(a)')'SAFE'
write(s(1),'(i0)')iand(a([2],:,:),maskr(4))
end program
