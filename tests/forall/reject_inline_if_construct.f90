program p
implicit none
integer::i,a(3)
if(.true.) forall(i=1:3)
a(i)=i
end forall
end program
