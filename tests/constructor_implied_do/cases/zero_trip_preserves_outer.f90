program main
implicit none
integer::i,j,a(0),b(0)
i=99
j=88
a=[(i,i=4,1)]
b=[(j,j=-4,1,-2)]
print *,size(a),size(b),i,j
end program
