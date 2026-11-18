function combine_mat_tensor_real(xmat,xtens,idim,position) result(ytens)
! augment tensor xtens(:,:) by matrix xmat(:) along dimension idim
real(kind=dp)    , intent(in)           ::  xmat(:,:)    ! (m1,m2)
real(kind=dp)    , intent(in)           :: xtens(:,:,:)  ! (n1,n2,n3)
integer          , intent(in)           :: idim
character (len=*), intent(in), optional :: position
real(kind=dp)    , allocatable          :: ytens(:,:,:)
integer                                 :: n1,n2,n3
character (len=*), parameter            :: msg = mod_str // "combine_vec_mat, "
character (len=20)                      :: position_
position_ = default("before",position)
n1  = size(xtens,1)
n2  = size(xtens,2)
n3  = size(xtens,3)
call assert(idim>0 .and. idim<=3,msg // "need 1 <= idim <= 3",stop_error=.true.)
call assert(position_=="before" .or. position_ == "after","need position = 'before' or 'after'",stop_error=.true.)
if (any(shape(xmat) /= exclude(shape(xtens),iexcl=[idim]))) then
   write (*,*) msg,"idim =",idim," shape(xmat)=",shape(xmat)," shape(xtens)=",shape(xtens), &
               " cannot combine matrix with tensor along specified dimension"
   stop
end if
if (idim == 1) then ! add another row
   allocate (ytens(n1+1,n2,n3))
   if (position_ == "before") then
      ytens(1 ,:,:) = xmat
      ytens(2:,:,:) = xtens
   else
      ytens(n1+1,:,:) = xmat
      ytens(:n1 ,:,:) = xtens
   end if
else if (idim == 2) then ! add another column
   allocate (ytens(n1,n2+1,n3))
   if (position_ == "before") then
      ytens(:,1   ,:) = xmat
      ytens(:,2:  ,:) = xtens
   else
      ytens(:,n2+1,:) = xmat
      ytens(:,:n2 ,:) = xtens
   end if
else
   allocate (ytens(n1,n2,n3+1))
   if (position_ == "before") then
      ytens(:,:,1)  = xmat
      ytens(:,:,2:) = xtens
   else
      ytens(:,:,n3+1) = xmat
      ytens(:,:,:n3)  = xtens
   end if
end if
end function combine_mat_tensor_real
!
