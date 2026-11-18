program p
implicit none
integer::a(-2:1),b(2,3),c(2,3,4)
a=0
b=0
c=0
print *,shape(a),shape(b),shape(c)
print *,kind(shape(a)),kind(shape(source=c,kind=8))
print *,size(shape(42)),sum(shape(42))
end program
