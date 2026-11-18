program p
logical,allocatable::a(:),b(:,:),c(:,:,:),d(:,:,:)
allocate(a(0));allocate(b(2,0));allocate(c(-1:0,4:5,9:8))
a=.true.;b=.false.;c=.true.;d=c
print *,allocated(a),allocated(b),allocated(c),allocated(d)
print *,size(a),size(b),size(c),size(d),size(d,1),size(d,2),size(d,3)
print *,lbound(c,1),lbound(c,2),lbound(c,3),ubound(c,3)
end program
