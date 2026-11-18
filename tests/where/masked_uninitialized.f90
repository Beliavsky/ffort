program p
implicit none
integer::a(4),b(4)=7
a(1)=2;a(3)=4
where([.true.,.false.,.true.,.false.]) b=8/a
print *,b
end program
