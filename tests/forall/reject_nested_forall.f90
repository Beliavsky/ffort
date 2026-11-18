program p
implicit none
integer::i,j,a(2)
forall(i=1:2)
forall(j=1:2) a(j)=i
end forall
end program
