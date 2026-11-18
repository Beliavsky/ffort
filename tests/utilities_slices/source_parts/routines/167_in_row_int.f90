function in_row_int(ivec,imat) result(tf)
! return true if any row of imat(:,:) equals ivec(:)
integer, intent(in) :: ivec(:)
integer, intent(in) :: imat(:,:)
logical             :: tf
integer             :: i,nrows
tf    = .false.
nrows = size(imat,1)
if (size(ivec) /= size(imat,2)) return
do i=1,nrows
   tf = all(ivec == imat(i,:))
   if (tf) return
end do
end function in_row_int
!
! subroutine unique_rows_int(imat,ipos,nuniq)
! ! return in ipos(1:nuniq) the positions of the unique elements of ivec(:)
! integer, intent(in)  :: imat(:,:)
! integer, intent(out) :: ipos(:) ! positions of unique integers in ivec
! integer, intent(out) :: nuniq   ! # of unique integers in ivec
! integer              :: i,n
! n = size(imat,1)
! if (size(ipos) /= n) then
!    write (*,*) mod_str//"unique_int, size(imat,1), size(ipos) =",n,size(ipos)," should be equal, stopPinG"
!    stop
! end if
! if (n == 0) return
! ipos(1) = 1
! nuniq   = 1
! do i=2,n
!    if (in_row_int(imat(i,:),imat(ipos(:nuniq),:))) then
!       nuniq = nuniq + 1
!       ipos(nuniq) = i
!    end if
! end do
! end subroutine unique_rows_int
!
