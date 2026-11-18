program p
implicit none
integer::a(3,2)
a=reshape([1,2,3,4,5,6],[3,2])
a=a([3,1,1],:)
print *,a
end program
