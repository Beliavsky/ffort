program p
implicit none
real(8)::a(2,2)
a=0.5d0
print *,acos(a),shape(acos(a))
end program
