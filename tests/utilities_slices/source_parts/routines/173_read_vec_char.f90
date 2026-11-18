subroutine read_vec_char(text,cdelim,max_read,xchar,nread,print_values_read)
! read character variables from a string or count how many can be read
character (len=*), intent(in)                         :: text     ! character variable from which data read
integer          , intent(in) , optional              :: max_read
character (len=*), intent(in) , optional              :: cdelim   ! if present, delimiter of variables in string
character (len=*), intent(out), optional, allocatable :: xchar(:)    ! values read
integer          , intent(out), optional              :: nread    ! # of values read
logical          , intent(in) , optional              :: print_values_read
character (len=100)           , allocatable :: xread(:)
character (len=len(text))                   :: mod_text
character (len=*)             , parameter   :: new_delim = ","
integer                                     :: i,ierr,nread_,max_read_,nlen
logical                                     :: read_mod_text
logical                       , parameter   :: print_debug = .false.
nlen = len_trim(text)
if (present(cdelim)) then
   max_read_ = num_matching_char(text,cdelim) + 1
else
   max_read_ = (nlen+1)/2
end if
if (present(max_read)) max_read_ = min(max_read_,max_read)
allocate (xread(max_read_))
if (present(cdelim)) then
   read_mod_text = (cdelim /= " " .and. cdelim /= ",")
else
   read_mod_text = .false.
end if
if (read_mod_text) then
   mod_text = text
   do i=1,nlen
      if (text(i:i) == cdelim) mod_text(i:i) = new_delim
   end do
end if
nread_ = 0
do i=max_read_,1,-1
   if (read_mod_text) then
      read (mod_text,*,iostat=ierr) xread(:i)
      if (print_debug) write (*,*) "i, ierr, mod_text = ",i,ierr," '" // trim(mod_text) // "'"
   else
      read (text,*,iostat=ierr) xread(:i)
      if (print_debug) write (*,*) "i, ierr, text = ",i,ierr," '" // trim(text) // "'"
   end if
   if (ierr == 0) then
      nread_ = i
      exit
   end if
end do
if (present(nread)) nread = nread_
if (present(xchar)) then
   allocate (xchar(nread_))
   xchar = xread(:nread_)
   if (present_and_true(print_values_read)) write (*,*) size(xchar)," value(s) read:", &
                                            (" '"//trim(xchar(i))//"'",i=1,size(xchar))
end if
deallocate (xread)
end subroutine read_vec_char
!
