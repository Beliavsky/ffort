program p
implicit none
integer::a(-3:3),i
a=0
forall(i=3:-3:-2) a(i)=i
print *,a
end program
