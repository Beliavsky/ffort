program p
implicit none
integer::i,a(2)
foo: forall(i=1:2) a(i)=i
end program
