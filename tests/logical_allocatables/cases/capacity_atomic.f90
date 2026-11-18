program p
logical,allocatable::a(:,:,:),b(:,:,:)
integer::s
allocate(a(64,64,32));a=.true.
allocate(b(-1:0,4:4,7:500006),stat=s)
print *,s/=0,allocated(b),size(a),a(64,64,32)
deallocate(a)
allocate(b(-1:0,4:4,7:7),stat=s);b=.false.
print *,s,size(b),lbound(b,3),b
end program
