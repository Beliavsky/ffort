subroutine print_absolute_threshold_counts(xx,thresh,fmt_header,fmt_trailer)
! for each threshold, print the number of values in xx(:) that are greater in absolute value and the number on each side
real(kind=dp)    , intent(in)           :: xx(:)
real(kind=dp)    , intent(in)           :: thresh(:)
character (len=*), intent(in), optional :: fmt_header,fmt_trailer
integer                                 :: ithresh,nthresh,outu_,nmore,nless,n,irepeat
real(kind=dp)                           :: th
n = size(xx)
outu_ = istdout
nthresh = size(thresh)
if (nthresh < 1 .or. n < 1) return
call write_format(fmt_header,iunit=outu_)
write (outu_,"(100a15)") "thresh",("|x| > thresh","x > thresh","x < -thresh",irepeat=1,2)
do ithresh=1,nthresh
   th = thresh(ithresh)
   nmore = count(xx >  th)
   nless = count(xx <- th)
   write (outu_,"(f15.2,3i15,100f15.6)") th,nmore+nless,nmore,nless,[nmore+nless,nmore,nless]/dble(n)
end do
call write_format(fmt_trailer,iunit=outu_)
end subroutine print_absolute_threshold_counts
!
