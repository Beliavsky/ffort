program p
implicit none
integer::a(3),i
forall(i=1:3) a(i)=i
print *,i
end program
