program p
implicit none
integer::a(0,2),i,x
forall(i=1:2) a(:,i)=3
print *,size(a)
end program
