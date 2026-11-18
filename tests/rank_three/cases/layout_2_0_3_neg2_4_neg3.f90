program rankthree
implicit none
integer :: aa(-2:-1,4:3,-3:-1),bb(2,0,3),i,j,k
do k=-3,-1
do j=4,3
do i=-2,-1
aa(i,j,k)=100*k+10*j+i
end do
end do
end do
bb=max(abs(-aa),7)+2
print *,aa,bb
print *,size(aa),size(aa,1),size(aa,2),size(aa,3)
print *,lbound(aa,1),ubound(aa,1),lbound(aa,2),ubound(aa,2),lbound(aa,3),ubound(aa,3)
print *,size(aa+1,3),lbound(aa+1,3),ubound(aa+1,3)
end program rankthree
