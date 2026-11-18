function combine_tensors_real(aa,bb,idim) result(ytens)
! combine tensors aa and bb along dimension idim
real(kind=dp)    , intent(in)           :: aa(:,:,:)  ! (m1,m2,m3)
real(kind=dp)    , intent(in)           :: bb(:,:,:)  ! (n1,n2,n3)
integer          , intent(in)           :: idim
real(kind=dp)    , allocatable          :: ytens(:,:,:)
integer                                 :: m1,m2,m3,n1,n2,n3
character (len=*), parameter            :: msg = mod_str // "combine_tensors_real, "
m1  = size(aa,1)
m2  = size(aa,2)
m3  = size(aa,3)
n1  = size(bb,1)
n2  = size(bb,2)
n3  = size(bb,3)
call assert(idim>0 .and. idim<=3,msg // "need 1 <= idim <= 3",stop_error=.true.)
if (any(exclude(shape(aa),iexcl=[idim]) /= exclude(shape(bb),iexcl=[idim]))) then
   write (*,*) msg,"idim =",idim," shape(aa)=",shape(aa)," shape(bb)=",shape(bb), &
               " cannot combine matrix with tensor along specified dimension"
   stop
end if
if (idim == 1) then
   allocate (ytens(m1+n1,n2,n3))
   ytens(:m1  ,:,:) = aa
   ytens(m1+1:,:,:) = bb
else if (idim == 2) then
   allocate (ytens(n1,m2+n2,n3))
   ytens(:,:m2  ,:) = aa
   ytens(:,m2+1:,:) = bb
else
   allocate (ytens(n1,n2,m3+n3))
   ytens(:,:,:m3  )  = aa
   ytens(:,:,m3+1:) = bb
end if
end function combine_tensors_real
!
