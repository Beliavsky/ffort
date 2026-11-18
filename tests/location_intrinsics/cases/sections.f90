program p
implicit none
integer::a(-2:2)
a=[8,-1,8,-1,4]
print *,minloc(a),maxloc(a),minloc(a(2:-2:-1)),maxloc(a(-2:2:2))
end program
