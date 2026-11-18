program p
implicit none
integer::a(2),i
logical::m
forall(i=1:2,m) a(i)=i
end program
