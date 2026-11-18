program p
implicit none
integer::a(0),b(2,0),c(0,3,2)
print *,shape(a),shape(b),shape(c)
print *,shape(shape(c)),shape(shape(1))
end program
