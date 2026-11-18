program p
integer::a(3,4),v,d,i
logical::m(3,4)
a=reshape([0,0,1,-1,1,2,1,0,2,-1,-1,0],[3,4])
m=reshape([.true.,.false.,.true.,.true.,.true.,.true.,.false.,.false.,.true.,.false.,.false.,.false.],[3,4])
do v=-3,3
print *,findloc(a,v,mask=m),findloc(a,v,mask=m,back=.true.)
do d=1,2
print *,findloc(a,v,dim=d,mask=m),findloc(a,v,dim=d,mask=m,back=.true.)
end do
end do
a=reshape([-1,2,-2,2,0,-2,2,0,1,-1,1,0],[3,4])
m=reshape([.true.,.false.,.true.,.true.,.true.,.true.,.true.,.true.,.true.,.false.,.true.,.false.],[3,4])
do v=-3,3
print *,findloc(a,v,mask=m),findloc(a,v,mask=m,back=.true.)
do d=1,2
print *,findloc(a,v,dim=d,mask=m),findloc(a,v,dim=d,mask=m,back=.true.)
end do
end do
a=reshape([-1,0,0,-1,-1,0,0,-2,-1,0,-1,1],[3,4])
m=reshape([.true.,.true.,.true.,.true.,.false.,.false.,.false.,.false.,.true.,.true.,.true.,.false.],[3,4])
do v=-3,3
print *,findloc(a,v,mask=m),findloc(a,v,mask=m,back=.true.)
do d=1,2
print *,findloc(a,v,dim=d,mask=m),findloc(a,v,dim=d,mask=m,back=.true.)
end do
end do
a=reshape([1,2,1,2,1,2,-1,-1,-2,2,0,-2],[3,4])
m=reshape([.false.,.true.,.true.,.true.,.true.,.false.,.true.,.true.,.true.,.true.,.false.,.true.],[3,4])
do v=-3,3
print *,findloc(a,v,mask=m),findloc(a,v,mask=m,back=.true.)
do d=1,2
print *,findloc(a,v,dim=d,mask=m),findloc(a,v,dim=d,mask=m,back=.true.)
end do
end do
a=reshape([-1,-1,-1,1,-2,-1,-1,2,2,-2,1,1],[3,4])
m=reshape([.true.,.true.,.false.,.false.,.true.,.false.,.true.,.false.,.true.,.true.,.true.,.false.],[3,4])
do v=-3,3
print *,findloc(a,v,mask=m),findloc(a,v,mask=m,back=.true.)
do d=1,2
print *,findloc(a,v,dim=d,mask=m),findloc(a,v,dim=d,mask=m,back=.true.)
end do
end do
a=reshape([-2,1,-1,2,0,-2,-2,1,0,-1,-2,0],[3,4])
m=reshape([.false.,.false.,.false.,.false.,.true.,.false.,.false.,.true.,.true.,.true.,.true.,.true.],[3,4])
do v=-3,3
print *,findloc(a,v,mask=m),findloc(a,v,mask=m,back=.true.)
do d=1,2
print *,findloc(a,v,dim=d,mask=m),findloc(a,v,dim=d,mask=m,back=.true.)
end do
end do
a=reshape([2,1,2,-2,-2,2,1,0,0,2,-2,1],[3,4])
m=reshape([.true.,.true.,.false.,.true.,.false.,.true.,.true.,.true.,.false.,.true.,.false.,.false.],[3,4])
do v=-3,3
print *,findloc(a,v,mask=m),findloc(a,v,mask=m,back=.true.)
do d=1,2
print *,findloc(a,v,dim=d,mask=m),findloc(a,v,dim=d,mask=m,back=.true.)
end do
end do
a=reshape([2,1,-1,-2,-2,-1,-1,2,-2,-1,2,0],[3,4])
m=reshape([.false.,.false.,.false.,.true.,.false.,.true.,.true.,.true.,.true.,.false.,.false.,.false.],[3,4])
do v=-3,3
print *,findloc(a,v,mask=m),findloc(a,v,mask=m,back=.true.)
do d=1,2
print *,findloc(a,v,dim=d,mask=m),findloc(a,v,dim=d,mask=m,back=.true.)
end do
end do
end program
