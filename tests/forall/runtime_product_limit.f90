program p
implicit none
integer::i,j,a(1)
forall(i=1:1001,j=1:1000) a(1)=i+j
end program
