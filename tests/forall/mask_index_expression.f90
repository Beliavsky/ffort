program p
implicit none
integer::a(5),i
a=0
forall(i=1:5,mod(i,2)==1) a(i)=i*i
print *,a
end program
