program main
implicit none
integer::a(2,2),idx(2)
a=1
write(*,'(a)')"before"
write(*,'(2(i0,1x))')7,sum(dim(a(idx,:),0))
end program
