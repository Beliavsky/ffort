program p
implicit none
integer::a(3,2),b(1,2)
a(2,:)=[2,5]
b=a([2],:)
print *,b
end program
