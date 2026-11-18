program p
implicit none
integer::a(2,2)=0
where([.true.,.false.]) a=1
end program
