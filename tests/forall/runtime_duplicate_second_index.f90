program p
implicit none
integer::a(2),i,j
forall(i=1:2,j=1:2) a(i)=j
end program
