! Synthetic release 0.30 composition fixture; not an extracted utility body.
program composition
implicit none
logical,allocatable :: a(:),b(:),selected(:)
allocate(a(-2:0))
a=.false.
allocate(b(4:6))
b=[.false.,.true.,.true.]
a=b
selected=.not.a
print *,shape(a),lbound(a,1),findloc(a,.true.,dim=1),findloc(a,.true.,dim=1,back=.true.)
print *,shape(selected),findloc(a,.false.,mask=selected)
deallocate(b)
allocate(b(7:10))
b=[.true.,.false.,.true.,.false.]
a=b
selected=a
print *,shape(a),lbound(a,1),ubound(a,1),shape(selected),lbound(selected,1)
print *,findloc(a(10:7:-1),.true.,dim=1),findloc(a,.true.,mask=selected,back=.true.)
end program
