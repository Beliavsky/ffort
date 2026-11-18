program p
implicit none
integer::i,step
real::a(2),v(-1:0)
step=0
print '(a)','SAFE'
a=[(norm2([real(i),0.]),i=lbound(v,1),ubound(v,1),step)]
end program
