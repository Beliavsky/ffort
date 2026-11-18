program p
implicit none
integer::a(5)
a=[7,-2,8,-2,8]
print *,minloc(a),maxloc(a),minloc(a,back=.true.),maxloc(a,back=.true.)
end program
