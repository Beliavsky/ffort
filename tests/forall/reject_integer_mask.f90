program p
implicit none
integer::i,a(2)
forall(i=1:2,1) a(i)=3
end program
