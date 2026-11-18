program p
implicit none
integer::i,j,a(2)
forall(i=1:2,j=i:2) a(i)=3
end program
