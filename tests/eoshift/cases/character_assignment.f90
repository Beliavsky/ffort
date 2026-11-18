program p
implicit none
character(2)::a(3),b(3)
a=["A "," B","CC"];b=eoshift(a,1,"! ");a=eoshift(b,-1,"? ")
write(*,'(*(a,:,"|"))')a
end program
