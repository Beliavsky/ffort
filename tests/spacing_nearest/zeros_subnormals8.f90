program p
implicit none

real(8)::x,s
x=0
s=nearest(x,1.0_8)
print *,s>0,s<tiny(x),spacing(x)==tiny(x),spacing(-x)==tiny(x),spacing(s)==tiny(x)
print *,nearest(s,-1.0_8)==0,nearest(-s,1.0_8)==0,nearest(-x,-1.0_8)<0
print *,nearest(tiny(x),-1.0_8)<tiny(x),spacing(tiny(x))==tiny(x)
end program
