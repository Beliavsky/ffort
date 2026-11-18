subroutine print_threshold_counts(xx,thresh,fmt_header,fmt_trailer)
! for each threshold, print the number of values in xx(:) that are greater
real(kind=dp)    , intent(in)           :: xx(:)
real(kind=dp)    , intent(in)           :: thresh(:)
character (len=*), intent(in), optional :: fmt_header,fmt_trailer
integer                                 :: ithresh,nthresh,outu_,nmore,n
real(kind=dp)                           :: th
n = size(xx)
outu_ = istdout
nthresh = size(thresh)
if (nthresh < 1 .or. n < 1) return
call write_format(fmt_header,iunit=outu_)
write (outu_,"(100a15)") "thresh","#x > thresh","fraction"
do ithresh=1,nthresh
   th = thresh(ithresh)
   nmore = count(xx >  th)
   write (outu_,"(f15.2,i15,f15.6)") th,nmore,nmore/dble(n)
end do
call write_format(fmt_trailer,iunit=outu_)
end subroutine print_threshold_counts
!
