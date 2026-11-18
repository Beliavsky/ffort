program p
logical,allocatable::a(:),b(:,:),c(:,:,:)
integer::s
print *,allocated(a),allocated(b),allocated(c)
allocate(a(-2:0)); allocate(b(4:5,-1:0)); allocate(c(-1:0,4:4,7:9))
a=.true.; b=.false.; c=.true.
c(0,4,9)=.false.
print *,size(a),lbound(a,1),size(b),lbound(b,2),size(c),lbound(c,3),ubound(c,3)
print *,a,b,c
allocate(c(1,1,1),stat=s)
print *,s/=0,size(c),lbound(c,3),c(0,4,9)
deallocate(a);deallocate(b);deallocate(c,stat=s)
print *,s,allocated(c)
deallocate(c,stat=s)
print *,s/=0
end program
