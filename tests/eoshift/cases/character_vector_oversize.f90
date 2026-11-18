program p
implicit none
character(2)::a(3)
a=['A ','BB',' C']
write(*,'(*(a,:,"|"))')eoshift(a,8)
end program
