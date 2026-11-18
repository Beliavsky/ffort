program p
implicit none
integer::a(3,2)
a=1
print *,shape(a([3,1],:)),size(a([3,1],:))
end program
