program main
implicit none
integer::i,j,a(0)
i=77
j=88
a=[((j,j=3,i),i=1,2)]
print *,size(a),i,j
end program
