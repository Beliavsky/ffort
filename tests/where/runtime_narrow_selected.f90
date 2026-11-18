program p
implicit none
integer::a(2)=0
where([.true.,.false.]) a=[3000000000_8,0_8]
end program
