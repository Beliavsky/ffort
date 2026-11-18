program p
implicit none
integer::i,j,k,a(2)
forall(i=1:2,j=1:2,k=1:2) a(i)=3
end program
