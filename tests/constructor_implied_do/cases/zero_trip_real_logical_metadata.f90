program main
implicit none
integer::i
real(8)::a(0)
logical::b(0)
a=[(0.25_8*i,i=2,1)]
b=[(i>0,i=2,1)]
print *,size(a),kind(a),size(b),kind(b)
end program
