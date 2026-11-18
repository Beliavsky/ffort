program p
implicit none
real(8)::a(0)
print *,minloc(a),maxloc(a,1),minloc(a,kind=8)
end program
