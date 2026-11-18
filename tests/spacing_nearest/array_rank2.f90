program p
implicit none

real(8)::a(2,2),s(2,2)
a=reshape([0d0,1d0,2d0,-1d0],[2,2]);s=1
print *,shape(spacing(a)),shape(nearest(s=s,x=a))
print *,nearest(a,s)>a
end program
