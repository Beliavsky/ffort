subroutine unique_int(ivec,ipos,nuniq)
! return in ipos(1:nuniq) the positions of the unique elements of ivec(:)
integer, intent(in)  :: ivec(:)
integer, intent(out) :: ipos(:) ! positions of unique integers in ivec
integer, intent(out) :: nuniq   ! # of unique integers in ivec
integer              :: i,n
n = size(ivec)
if (size(ipos) /= n) then
   write (*,*) mod_str//"unique_int, size(ivec), size(ipos) =",n,size(ipos)," should be equal, stopPinG"
   stop
end if
if (n == 0) then
   nuniq = 0
   return
end if
ipos(1) = 1
nuniq   = 1
do i=2,n
   if (all(ivec(i) /= ivec(ipos(:nuniq)))) then
      nuniq = nuniq + 1
      ipos(nuniq) = i
   end if
end do
end subroutine unique_int
!
