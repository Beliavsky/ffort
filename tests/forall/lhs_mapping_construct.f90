program p
implicit none
integer::a(3),b(3),i
a=[3,1,2]
forall(i=1:3)
b(a(i))=i
a(i)=b(i)
end forall
print *,a,b
end program
