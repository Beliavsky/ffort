program main
implicit none
integer::a(2,0),idx(1)
idx=[3]
write(*,'(a)')"before"
write(*,'(i0)')size(a(idx,:))
end program
