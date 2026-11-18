program p
implicit none
integer::i,a(2)
forall(i=1:2,i=1:2) a(i)=3
end program
