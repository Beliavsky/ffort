function filter_vec(ivec,ibad,ascending) result(jvec)
! return in jvec(:) the elements of ivec(:), excluding those found in ibad(:)
integer, intent(in)           :: ivec(:)
integer, intent(in)           :: ibad(:)
logical, intent(in), optional :: ascending ! if .true., assume that ivec(:) and ibad(:) are non-descending
integer, allocatable          :: jvec(:)
call set_alloc(pack(ivec,mask_vec(ivec,ibad,ascending)),jvec)
end function filter_vec
!
