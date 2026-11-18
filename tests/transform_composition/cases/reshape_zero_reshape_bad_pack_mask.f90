program p
implicit none
integer::a(2,2),n
logical::m(1,4)
a=1;m=.true.;n=1
print *,size(reshape(pack(a,m(:,:n)),[0]))
end program
