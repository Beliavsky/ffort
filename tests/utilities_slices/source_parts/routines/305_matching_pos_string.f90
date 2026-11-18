pure function matching_pos_string(ii,ivec) result(ipos)
! return in ipos the positions of ivec that match elements of ii, excluding elements of ii with no matches
character (len=*), intent(in)  :: ii(:),ivec(:)
integer          , allocatable :: ipos(:)
integer                        :: jpos(size(ii))
jpos = match_string_vec(ii,ivec)
call set_alloc(pack(jpos,jpos>0),ipos)
end function matching_pos_string
!
