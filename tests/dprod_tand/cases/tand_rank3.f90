program p
implicit none
real(8)::a(2,1,2)
a=30d0
print *,tand(a),shape(tand(a))
end program
