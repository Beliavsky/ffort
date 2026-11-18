program p
implicit none
integer::a(2,3)
a=reshape([2,7,7,-1,-1,3],[2,3])
print *,minloc(a),maxloc(a),minloc(a,back=.true.),maxloc(a,back=.true.)
end program
