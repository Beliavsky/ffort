program p
implicit none
integer::a(4),b(4),i
a=[1,2,3,4]
forall(i=1:4)
a(i)=a(5-i)
b(i)=a(i)+a(5-i)
a(i)=b(5-i)*10+i
end forall
print *,a,b
end program
