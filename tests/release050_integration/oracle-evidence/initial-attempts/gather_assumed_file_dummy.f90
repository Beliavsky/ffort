module m
contains
subroutine emit(v,s)
integer,intent(in)::v(:,:,:)
character(*),intent(out)::s(:,:,:)
integer::i,j,k
do k=1,size(v,3)
do j=1,size(v,2)
do i=1,size(v,1)
write(s(i,j,k),'(i3.3)')shiftr(v(i,j,k),1)
end do
end do
end do
end subroutine
end module
program p
use m
implicit none
integer::a(2,1,2)
character(3)::s(2,1,2)
a(:,1,1)=[8,10]
a(:,1,2)=[12,14]
call emit((a(:,:,[2,1])),s)
print '(a)',s
end program
