program p
integer,allocatable,target::a(:)
real(kind=8),target,allocatable::b(:,:)
logical,target,allocatable::c(:,:,:)
allocate(a(-1:0))
allocate(b(2:2,3:4))
allocate(c(1:1,2:2,3:4))
a=2;b=3.5_8;c=.true.
print *,a,b,c,lbound(a,1),lbound(b,2),lbound(c,3)
deallocate(a)
deallocate(b)
deallocate(c)
print *,allocated(a),allocated(b),allocated(c)
end program
