program p
implicit none
integer::a(2),b(2)=0
where([.true.,.false.]) b=a
end program
