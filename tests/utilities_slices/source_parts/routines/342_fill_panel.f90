subroutine fill_panel(xx,labels_2,labels_3,fill_initial,min_good_value,write_interp_stats)
real(kind=dp)    , intent(in out) :: xx(:,:,:)
character (len=*), intent(in)     :: labels_2(:),labels_3(:)
real(kind=dp)    , intent(in)     :: min_good_value
logical          , intent(in)     :: fill_initial,write_interp_stats
integer                           :: i2,i3,n2,n3
integer, allocatable              :: nfilled(:,:),nbad(:,:)
logical :: good(size(xx,1))
n2 = size(xx,2)
n3 = size(xx,3)
allocate (nfilled(n2,n3),nbad(n2,n3))
if (write_interp_stats) write (*,"(/,'#points filled',/,a20,a8,3x,100a6)") "var","pts",labels_2
do i3=1,n3
   do i2=1,n2
      good = xx(:,i2,i3) > min_good_value
      nbad(i2,i3) = count(.not. good)
      ! output: xx, nfilled
      call fill_vec(good,xx(:,i2,i3),nfilled(i2,i3),fill_initial=fill_initial)
   end do
   if (write_interp_stats) then
      write (*,"(a20,a8,100i6)") trim(labels_3(i3)),"bad",nbad(:,i3)
      write (*,"(a20,a8,100i6)") trim(labels_3(i3)),"filled",nfilled(:,i3)
      write (*,"(a20,a8,100i6)") trim(labels_3(i3)),"remain",nbad(:,i3)-nfilled(:,i3)
   end if
end do
end subroutine fill_panel
!
