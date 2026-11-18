program p
logical,allocatable::a(:),b(:,:),c(:,:,:),d(:,:,:)
a=[.true.,.false.]
b=reshape([.true.,.false.,.false.,.true.],[2,2])
allocate(c(-1:0,4:4,7:8));c=.true.
c(0,4,8)=.false.
d=.not.c
print *,a,b,d
c=c.and..not.d
print *,c
c=c.or.d
print *,c
c=c.neqv.d
print *,c
c=c.eqv.d
print *,c
end program
