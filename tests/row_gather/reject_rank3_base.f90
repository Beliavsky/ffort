program p
implicit none
integer::a(3,2,1),b(2,2,1)
b=a([1,2],:,:)
end program
