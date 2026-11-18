program p
implicit none
integer::a(3)=0
where([.true.,.false.]) a=1
end program
