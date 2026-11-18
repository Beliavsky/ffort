program p
implicit none
integer::a(2,3)
a=0
print *,shape(a+1),shape(reshape([1,2,3,4,5,6],[2,3]))
print *,shape([1,2,3]),shape(source=a,kind=4)
end program
