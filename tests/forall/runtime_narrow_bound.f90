program p
implicit none
integer::i,a(2)
forall(i=1:2147483648_8) a(i)=i
end program
