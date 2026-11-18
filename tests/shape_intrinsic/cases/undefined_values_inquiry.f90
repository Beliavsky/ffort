program p
implicit none
integer::a(2,3),scalar
real::r(4)
logical::l(2)
character(3)::c(5)
print *,shape(a),shape(r),shape(l),shape(c),size(shape(scalar))
end program
