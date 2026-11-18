program purity_test
implicit none
integer :: aa(2,3)
aa=1
call adjust(aa(:,3:1:-1))
print *,aa
contains
pure subroutine adjust(xx)
integer,intent(inout)::xx(:,:)
integer::ii,jj
do jj=1,size(xx,2)
do ii=1,size(xx,1)
xx(ii,jj)=10*jj+ii
end do
end do
end subroutine adjust

end program
