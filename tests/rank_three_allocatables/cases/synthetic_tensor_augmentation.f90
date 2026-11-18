! Synthetic allocation/section driver. Not an extracted or rewritten utility.
program p
real(8)::tensor(2,2,2),matrix(2,2)
real(8),allocatable::out_tensor(:,:,:)
integer::axis,k
real(8)::total
matrix=9.0d0; tensor=2.0d0
do axis=1,3
out_tensor=augment(matrix,tensor,axis,.true.)
total=0.0d0
do k=1,size(out_tensor,3)
total=total+sum(out_tensor(:,:,k))
end do
print *,total,out_tensor(1,1,1),out_tensor(2,2,2)
out_tensor=augment(matrix,tensor,axis,.false.)
total=0.0d0
do k=1,size(out_tensor,3)
total=total+sum(out_tensor(:,:,k))
end do
print *,total,out_tensor(1,1,1),out_tensor(size(out_tensor,1),size(out_tensor,2),size(out_tensor,3))
end do
contains
function augment(m,t,axis,before) result(r)
real(8),intent(in)::m(:,:),t(:,:,:)
integer,intent(in)::axis
logical,intent(in)::before
real(8),allocatable::r(:,:,:)
integer::n1,n2,n3
n1=size(t,1);n2=size(t,2);n3=size(t,3)
if(axis==1) then
allocate(r(n1+1,n2,n3))
if(before) then
r(1,:,:)=m; r(2:,:,:)=t
else
r(n1+1,:,:)=m; r(:n1,:,:)=t
end if
else if(axis==2) then
allocate(r(n1,n2+1,n3))
if(before) then
r(:,1,:)=m; r(:,2:,:)=t
else
r(:,n2+1,:)=m; r(:,:n2,:)=t
end if
else
allocate(r(n1,n2,n3+1))
if(before) then
r(:,:,1)=m; r(:,:,2:)=t
else
r(:,:,n3+1)=m; r(:,:,:n3)=t
end if
end if
end function
end program
