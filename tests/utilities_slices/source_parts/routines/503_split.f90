function split(string,delim,adjustl_words) result(words)
! split string by delim
character (len=*)   , intent(in)  :: string
character (len=*)   , intent(in)  :: delim
logical             , intent(in), optional :: adjustl_words
character (len=1000), allocatable :: words(:)
integer             , allocatable :: ipos(:)
integer                           :: i,ndelim,nlen
call set_alloc(positions_char_string(trim(string),delim),ipos)
ndelim = size(ipos)
nlen = len_trim(string)
allocate (words(ndelim+1))
if (ndelim == 0) then
   words(1) = string
   return
end if
words(1) = string(1:ipos(1)-1)
do i=2,ndelim
   words(i) = string(ipos(i-1)+1:ipos(i)-1)
end do
words(ndelim+1) = string(ipos(ndelim)+1:nlen)
if (default(.false.,adjustl_words)) words = adjustl(words)
end function split
!
