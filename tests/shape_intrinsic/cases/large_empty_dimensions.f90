program p
implicit none
integer::a(0,2147483647,2147483647)
integer::b(2147483647,0,2147483647)
integer::c(2147483647,2147483647,0)
print *,shape(a),shape(b,kind=8),shape(c)
end program
