program p
implicit none
character(1)::a(3,2),b(2,2)
b=a([1,2],:)
end program
