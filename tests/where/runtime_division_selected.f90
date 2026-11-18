program p
implicit none
integer::a(2)=[0,2],b(2)=0
where([.true.,.false.]) b=8/a
end program
