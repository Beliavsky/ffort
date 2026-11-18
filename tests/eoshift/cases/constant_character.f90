program p
implicit none
character(2),parameter::a(3)=eoshift(["A "," B","CC"],1)
write(*,'(*(a,:,"|"))')a
end program
