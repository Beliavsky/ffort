program p
implicit none
integer::a(2)
forall(integer::i=1:2) a(i)=i
end program
