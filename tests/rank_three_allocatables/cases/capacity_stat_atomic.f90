program p
integer,allocatable::a(:,:,:),b(:,:,:)
integer::s
allocate(a(64,64,32)); a=3
allocate(b(-1:0,2:2,7:500006),stat=s)
print *,s/=0,allocated(b),size(a),a(1,1,1),a(64,64,32),lbound(a,3)
deallocate(a)
allocate(b(-1:0,2:2,7:7),stat=s)
b=9
print *,s,size(b),lbound(b,3),sum(b(:,:,7))
end program
