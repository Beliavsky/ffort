program p
implicit none

real::a(4)
a=[1.,2.,3.,4.]
print *,spacing(a(4:1:-2))>0,nearest(a(1:4:2),-1.)<a(1:4:2)
end program
