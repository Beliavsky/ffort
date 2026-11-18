program p
implicit none
integer::a(0,3),b(3,0)
print *,minloc(a),maxloc(a,1),size(minloc(a,2)),maxloc(b),size(minloc(b,1)),maxloc(b,2)
end program
