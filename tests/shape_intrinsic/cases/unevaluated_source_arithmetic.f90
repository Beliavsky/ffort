program p
implicit none
integer::a(2,3),zero
zero=0
print *,shape(a/zero),size(shape(1/zero))
end program
