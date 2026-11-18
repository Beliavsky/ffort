function label_obs_bins(thresh,fmt_real) result(labels)
! labels for ranges determined by thresh(:)
real(kind=dp)     , intent(in) :: thresh(:)
character (len=30)             :: labels(size(thresh)+1)
character (len=*) , intent(in), optional :: fmt_real
character (len=20)             :: fstr
integer                        :: i,nthresh
logical                        :: in_quotes
in_quotes = .true.
call set_optional(fstr,"f0.4",fmt_real)
nthresh = size(thresh)
if (nthresh < 1) return
! write (labels(1),"('x<=',f0.4)") thresh(1)
write (labels(1),"('x<='," // trim(fstr) // ")") thresh(1)
do i=1,nthresh-1
!   write (labels(i+1),"(f0.4,'<x<=',f0.4)") thresh([i,i+1])
   write (labels(i+1),"(" // trim(fstr) // ",'<x<='," // trim(fstr) // ")") thresh([i,i+1])
end do
! write (labels(nthresh+1),"('x>',f0.4)") thresh(nthresh)
write (labels(nthresh+1),"('x>'," // trim(fstr) // ")") thresh(nthresh)
if (in_quotes) then
   do i=1,size(labels)
      labels(i) = "'" // trim(labels(i)) // "'"
   end do
end if
end function label_obs_bins
!
