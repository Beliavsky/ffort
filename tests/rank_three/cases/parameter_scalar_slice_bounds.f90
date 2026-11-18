program rankthree
implicit none
integer,parameter :: aa(-1:0,3:5,7:10)=4
integer,parameter :: bb(2,3)=aa(:,:,8)
integer,parameter :: n=aa(-1,3,7),m=size(aa,2),l=ubound(aa,3)-lbound(aa,3)+1
integer :: cc(n,m,l)
cc=bb(1,1)+1
print *,aa(:,4,9),bb,size(cc),size(cc,3),cc(4,3,4)
end program rankthree
