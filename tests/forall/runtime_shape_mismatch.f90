program p
implicit none
integer::a(2,2),b(3),i
b=1
forall(i=1:2) a(:,i)=b
end program
