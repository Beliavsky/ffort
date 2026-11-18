program p
implicit none

real::a(0),b(2,0)
print *,size(spacing(a)),size(nearest(a,1.0)),shape(nearest(b,1d0))
end program
