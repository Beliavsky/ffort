subroutine unique_positions_int(ivec,ipos,freq)
! return in ipos the positions of the first occurrences of the unique elements of ivec(:)
integer, intent(in)                         :: ivec(:)
integer, intent(out), allocatable           :: ipos(:) ! positions of unique integers in ivec
integer, intent(out), optional, allocatable :: freq(:)
integer                                     :: i,n,nuniq
n = size(ivec)
allocate (ipos(n))
if (n == 0) return
ipos(1) = 1
nuniq   = 1
do i=2,n
   if (all(ivec(i) /= ivec(ipos(:nuniq)))) then
      nuniq = nuniq + 1
      ipos(nuniq) = i
   end if
end do
call set_alloc((ipos(:nuniq)),ipos)
if (present(freq)) then
   allocate (freq(nuniq))
   forall (i=1:nuniq) freq(i) = count(ivec==ivec(ipos(i)))
end if
end subroutine unique_positions_int
!
