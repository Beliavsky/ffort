function mask_vec(ivec,ibad,ascending) result(imask)
! return in imask(:) .true. if the corresponding element of ivec is not found in ibad(:)
integer, intent(in)           :: ivec(:)
integer, intent(in)           :: ibad(:)
logical, intent(in), optional :: ascending ! if .true., assume that ivec(:) and ibad(:) are non-descending
logical                       :: imask(size(ivec))
integer                       :: i,i1,ipos,n,nbad
logical                       :: found,ascending_
ascending_ = default(.false.,ascending)
imask = .true.
n = size(ivec)
nbad = size(ibad)
if (n == 0 .or. nbad == 0) return
if (ascending_) then
   i1 = 1
   ! write (*,"(5a8)") "i","ivec(i)","ipos","i1","found"
   do i=1,n
      call exact_match_ascending_int(ibad,ivec(i),ipos,found,i1)
      imask(i) = .not. found
   !   write (*,"(4i8,l8)") i,ivec(i),ipos,i1,found
      if (found) i1 = ipos
   end do
else
   forall (i=1:n) imask(i) = all(ibad /= ivec(i))
end if
end function mask_vec
!
