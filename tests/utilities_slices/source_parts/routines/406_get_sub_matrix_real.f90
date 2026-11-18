subroutine get_sub_matrix_real(xx,iget,jget,yy,ygood,xgood)
! set yy = xx(iget,jget) where (iget,jget) is in bounds and xgood is .true.
real(kind=dp), intent(in)           :: xx(:,:)    ! (n1,n2)
integer      , intent(in)           :: iget(:)    ! (ni)
integer      , intent(in)           :: jget(:)    ! (nj)
logical      , intent(in), optional :: xgood(:,:) ! (n1,n2)
real(kind=dp), intent(out)          :: yy(:,:)    ! (ni,nj)
logical      , intent(out)          :: ygood(:,:) ! (ni,nj)
integer                             :: i,j,iuse,juse,ni,nj,n1,n2
character (len=*), parameter        :: msg="in get_sub_matrix_real, "
logical      , allocatable          :: xgood_(:,:)
n1 = size(xx,1)
n2 = size(xx,2)
ni = size(iget)
nj = size(jget)
if (any([size(yy,1),size(ygood,1)] /= ni) .or. any([size(yy,2),size(ygood,2)] /= nj)) then
   print*,msg,"[size(iget),size(jget)]=",[ni,nj]," shape(yy)=",shape(yy)," shape(ygood)=",shape(ygood), &
         " should all be equal, STOPPING"
   stop
else if (present(xgood)) then
   if (size(xgood,1) /= n1 .or. size(xgood,2) /= n2) then
      print*,msg,"shape(xx)=",shape(xx)," shape(xgood)=",shape(xgood)," should be equal, STOPPING"
      stop
   end if
end if
if (present(xgood)) then
   call set_alloc(xgood,xgood_)
else
   allocate (xgood_(n1,n2))
   xgood_ = .true.
end if
ygood = .false.
do_i: do i=1,ni
   iuse = iget(i)
   if (iuse < 1 .or. iuse > ni) cycle do_i
   do_j: do j=1,nj
      juse = jget(j)
      if (juse < 1 .or. juse > nj) cycle do_j
      if (xgood_(iuse,juse)) then
         yy(i,j)    = xx(iuse,juse)
         ygood(i,j) = .true.
      end if
   end do do_j
end do do_i
end subroutine get_sub_matrix_real
!
