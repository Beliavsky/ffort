program p
implicit none
integer::a(3,2),b(1,2)
a=1
b=a([9223372036854775807_8],:)
end program
