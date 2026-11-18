subroutine select_vec_character(iuse,xx,idim)
! select elements in positions iuse along dimension idim
integer          , intent(in)                  :: iuse(:)
integer          , intent(in)    , optional    :: idim
character (len=*), intent(in out), allocatable :: xx(:)
character (len=*), parameter                   :: msg=mod_str//"select_vec_character, "
integer                                        :: idim_
call set_optional(idim_,1,idim)
if (idim_ /= 1) then
   write (*,*) msg,"idim_ =",idim_," must equal 1, stoppinG"
   stop
end if
call set_alloc((xx(iuse)),xx)
end subroutine select_vec_character
