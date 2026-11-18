program p
implicit none
integer::a(3),b(3),i
a=9
forall(i=1:3,.false.) a(i)=b(i)
print *,a
end program
