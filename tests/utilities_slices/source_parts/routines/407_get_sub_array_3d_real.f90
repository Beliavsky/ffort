subroutine get_sub_array_3d_real(xx,iget,jget,kget,yy,ygood,xgood,ydef)
! set yy = xx(iget,jget) where (iget,jget) is in bounds and xgood is .true.
real(kind=dp), intent(in)           :: xx(:,:,:)    ! (n1,n2,n3)
integer      , intent(in)           :: iget(:)      ! (ni)
integer      , intent(in)           :: jget(:)      ! (nj)
integer      , intent(in)           :: kget(:)      ! (nk)
logical      , intent(in), optional :: xgood(:,:,:) ! (n1,n2,n3)
real(kind=dp), intent(out)          :: yy(:,:,:)    ! (ni,nj,nk)
logical      , intent(out)          :: ygood(:,:,:) ! (ni,nj,nk)
real(kind=dp), intent(in), optional :: ydef
integer                             :: i,j,k,iuse,juse,kuse,ni,nj,nk,n1,n2,n3
character (len=*), parameter        :: msg="in get_sub_array_3d_real, "
logical      , allocatable          :: xgood_(:,:,:)
n1 = size(xx,1)
n2 = size(xx,2)
n3 = size(xx,3)
ni = size(iget)
nj = size(jget)
nk = size(kget)
! print*,msg // " n1, n2, n3, ni, nj, nk =",n1, n2, n3, ni, nj, nk !! debug
if (any([size(yy,1),size(ygood,1)] /= ni) .or. any([size(yy,2),size(ygood,2)] /= nj) &
         .or. any([size(yy,3),size(ygood,3)] /= nk)) then
   print*,msg,"[size(iget),size(jget),size(kget)]=",[ni,nj,nk]," shape(yy)=",shape(yy)," shape(ygood)=",shape(ygood), &
         " should all be equal, STOPPING"
   stop
else if (present(xgood)) then
   if (size(xgood,1) /= n1 .or. size(xgood,2) /= n2 .or. size(xgood,3) /= n3) then
      print*,msg,"shape(xx)=",shape(xx)," shape(xgood)=",shape(xgood)," should be equal, STOPPING"
      stop
   end if
end if
if (present(xgood)) then
   call set_alloc(xgood,xgood_)
else
   allocate (xgood_(n1,n2,n3))
   xgood_ = .true.
end if
ygood = .false.
if (present(ydef)) yy = ydef
do_i: do i=1,ni
   iuse = iget(i)
   if (iuse < 1 .or. iuse > n1) cycle do_i
   do_j: do j=1,nj
      juse = jget(j)
      if (juse < 1 .or. juse > n2) cycle do_j
      do_k: do k=1,nk
         kuse = kget(k)
!         print*,"ni, nj, nk, iuse, juse, kuse =",ni,nj,nk,iuse,juse,kuse," shape(xx)=",shape(xx)," shape(xgood_)=",shape(xgood_) !! debug
         if (kuse < 1 .or. kuse > n3) cycle do_k
         if (xgood_(iuse,juse,kuse)) then
            yy(i,j,k)    = xx(iuse,juse,kuse)
            ygood(i,j,k) = .true.
         end if
      end do do_k
   end do do_j
end do do_i
end subroutine get_sub_array_3d_real
!
! subroutine write_trim_vec(strings,label,prefix,suffix,outu)
! subroutine write_trim_vec(strings,outu)
