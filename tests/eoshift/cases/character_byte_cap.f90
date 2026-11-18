program p
implicit none
character(65536)::a(300)
a="A"
write(*,*)eoshift(a,1)
end program
