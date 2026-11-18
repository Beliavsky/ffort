program p
implicit none
integer::a(3),i
a=[3,1,2]
forall(i=1:3) a(a(i))=10*i
print *,a
end program
