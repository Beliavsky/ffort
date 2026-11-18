program p
implicit none
integer::a(3,2)
a=reshape([1,2,3,4,5,6],[3,2])
print *,sum(a([3,1],:))
end program
