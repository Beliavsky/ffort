program independent_ranktwo
implicit none
integer :: aa(2,3),bb(3,2),cc(2,2),ii,jj
do jj=1,3
 do ii=1,2
 aa(ii,jj)=ii+2*jj
 end do
end do
do jj=1,2
 do ii=1,3
 bb(ii,jj)=2*ii-jj
 end do
end do
call multiply(aa,bb,cc)
print *,cc
contains
subroutine multiply(xx,yy,zz)
 integer,intent(in) :: xx(:,:),yy(:,:)
 integer,intent(out) :: zz(:,:)
 integer :: ii,jj,kk
 zz=0
 do jj=1,size(zz,2)
 do ii=1,size(zz,1)
 do kk=1,size(xx,2)
 zz(ii,jj)=zz(ii,jj)+xx(ii,kk)*yy(kk,jj)
 end do
 end do
 end do
end subroutine multiply
end program independent_ranktwo
