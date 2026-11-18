program p
implicit none
integer,allocatable::a(:,:)
integer::b(1,2)
b=a([1],:)
end program
