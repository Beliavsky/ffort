program p
integer,allocatable::a(:,:,:)
integer::s
allocate(a(1,1,1000001),stat=s)
print *,s/=0,allocated(a)
allocate(a(-1:0,2:2,-5:-4),stat=s); a=6
print *,s,size(a),lbound(a,3),sum(a(:,:,-5))+sum(a(:,:,-4))
end program
