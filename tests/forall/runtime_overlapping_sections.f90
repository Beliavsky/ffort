program p
implicit none
integer::a(4),i
forall(i=1:2) a(i:i+2)=i
end program
