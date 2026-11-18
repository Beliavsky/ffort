program p
implicit none
real::i
integer::a(2)
forall(i=1:2) a(1)=3
end program
