program p
implicit none
integer::i,a(2,2),b(8)
a=1
b=[(transpose(a),i=1,2)]
print '(8i2)',b
end program
