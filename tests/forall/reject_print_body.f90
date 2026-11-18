program p
implicit none
integer::i
forall(i=1:2)
print *,i
end forall
end program
