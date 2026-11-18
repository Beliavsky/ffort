program p
implicit none
integer::a(3,2)
print *,shape(a([3,1],:))
end program
