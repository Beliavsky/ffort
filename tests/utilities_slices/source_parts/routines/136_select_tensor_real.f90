subroutine select_tensor_real(iuse,xx,idim)
! select elements in positions iuse along dimension idim
integer      , intent(in)                  :: iuse(:)
real(kind=dp), intent(in out), allocatable :: xx(:,:,:)
integer      , intent(in)    , optional    :: idim
integer                                    :: idim_
character (len=*), parameter               :: msg=mod_str//"select_tensor_real, "
call set_optional(idim_,1,idim)
select case (idim_)
   case (1); call set_alloc((xx(iuse,:,:)),xx)
   case (2); call set_alloc((xx(:,iuse,:)),xx)
   case (3); call set_alloc((xx(:,:,iuse)),xx)
   case default
      write (*,*) msg,"idim_ =",idim_," should be between 1 and 3, stopPinG"
      stop
end select
end subroutine select_tensor_real
!
