program p
implicit none
integer::a(2),i,s
s=0
forall(i=1:2:s) a(i)=i
end program
