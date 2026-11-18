program p
implicit none
integer::a(6),i
a=[1,2,3,4,5,6]
i=99
forall(i=1:6) a(i)=a(7-i)
print *,a,i
end program
