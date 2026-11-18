program p
implicit none
integer::a(3),i
a=[3,2,1]
forall(i=1:a(1)) a(i)=0
print *,a
end program
