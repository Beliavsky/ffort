program p
implicit none
integer::i,a(1)
a=0
forall(i=1:3,i==2) a(1)=i
print *,a
end program
