program p
implicit none
integer::i,a(2)
forall(i=1:2)
a(i)=i
end forall foo
end program
