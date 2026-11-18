program p
implicit none
logical::a(3)
a=[.true.,.false.,.true.]
write(*,'(*(l1,1x))')eoshift(a,2)
end program
