program p
implicit none
real(4)::a(-2:1),b(4)
integer(8)::idx(4)
a=[1.,2.,3.,4.]
idx=[1_8,-2_8,1_8,-1_8]
b=a(idx)
if(any(b/=[4,1,4,2]))error stop 1
print '(i0)',1
end program
