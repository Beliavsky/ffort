program p
implicit none
integer::i
i=5
forall(i=1:3)
end forall
print *,i
end program
