program test
implicit none
integer,dimension(2),parameter::a=[4,2],b=[2,4]
print *,minloc(a),maxloc(b)
end program
