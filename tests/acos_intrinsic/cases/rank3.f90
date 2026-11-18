program p
implicit none
real::a(2,1,2)
a=0.5
print *,acos(a),shape(acos(a))
end program
