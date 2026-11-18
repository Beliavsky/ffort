program p
implicit none
real(8)::a(2,3)
integer::s,d
write(*,'(i0)')kind(eoshift(a,s,dim=d))
end program
