program p
implicit none
integer::a(3),i
a=0;forall(i=1:3) a(i)=i;forall(i=1:3) a(i)=a(4-i)
forall(i=1:3, &
 & a(i)>1) a(i)=a(i)+10
print *,a
end program
