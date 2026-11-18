program test
implicit none
integer,dimension((3))::a,b
integer,dimension(-1:0,2:3)::c
integer,dimension(2)::d
a=[5,1,1]
b=a
c=reshape([4,3,2,1],[2,2])
d=[8,9]
print *,minloc(a),maxloc(b),minloc(c),maxloc(d)
end program
