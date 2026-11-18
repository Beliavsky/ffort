program p
implicit none
integer::a(2,3)
a=0
print *,shape(kind=8,source=a),kind(shape(kind=8,source=a))
print *,shape(a,8),shape(source=a)
end program
